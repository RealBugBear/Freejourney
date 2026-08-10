# Trainer Network — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the full trainer discovery feature: trainers register with a location, admins approve them, clients find nearby trainers on a map and send connection requests.

**Architecture:** New `trainer_profiles` + `trainer_profile_private` Supabase tables (PostGIS geography columns). `find_trainers_nearby` SECURITY DEFINER RPC returns only approximated public pins, never raw coordinates or contact data. Discovery is a 4th tab in AppShell; trainer registration plugs into the existing trainer activation flow.

**Tech Stack:** Flutter (Riverpod, GoRouter, flutter_map 7.x, geolocator 13.x, latlong2 0.9.x), Supabase (PostGIS ST_DWithin, RLS, SECURITY DEFINER RPCs), permission_handler (already in pubspec).

**Spec reference:** `docs/superpowers/specs/2026-04-24-trainer-discovery-design.md`

---

## File Map

### New files
| File | Responsibility |
|---|---|
| `supabase/migrations/20260427_trainer_network.sql` | PostGIS, trainer_profiles, trainer_profile_private, all RPCs, RLS, grants |
| `lib/features/trainer/domain/models/trainer_profile.dart` | `TrainerProfile` model + `TrainerProfileStatus` enum |
| `lib/features/trainer/domain/models/trainer_discovery_request.dart` | `TrainerDiscoveryRequest` model (incoming requests for trainer view) |
| `lib/features/trainer/domain/repositories/trainer_profile_repository.dart` | Abstract repository interface |
| `lib/features/trainer/data/repositories/supabase_trainer_profile_repository.dart` | Supabase implementation |
| `lib/features/trainer/presentation/providers/trainer_discovery_provider.dart` | Riverpod providers for discovery, profile setup, admin review, requests |
| `lib/features/trainer/presentation/widgets/trainer_location_picker_widget.dart` | Interactive flutter_map widget — tap to set a pin |
| `lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart` | Trainer self-registration form + location picker |
| `lib/features/trainer/presentation/screens/trainer_profile_pending_screen.dart` | "Profil wird geprüft" waiting screen |
| `lib/features/trainer/presentation/screens/trainer_discovery_screen.dart` | Map + list + radius slider for clients |
| `lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart` | Trainer profile view + "Anfrage senden" CTA |
| `lib/features/trainer/presentation/screens/trainer_requests_screen.dart` | Trainer sees + accepts/declines incoming requests |
| `test/features/trainer/domain/models/trainer_profile_test.dart` | Unit tests for TrainerProfile.fromJson |
| `test/features/trainer/domain/models/trainer_discovery_request_test.dart` | Unit tests for TrainerDiscoveryRequest.fromJson |

### Modified files
| File | Change |
|---|---|
| `pubspec.yaml` | Add flutter_map, geolocator, latlong2 |
| `ios/Runner/Info.plist` | Add NSLocationWhenInUseUsageDescription |
| `android/app/src/main/AndroidManifest.xml` | Add ACCESS_FINE_LOCATION + ACCESS_COARSE_LOCATION permissions |
| `lib/core/navigation/app_router.dart` | Add 5 new routes; add `trainerDiscovery`, `trainerProfileSetup`, `trainerProfilePending`, `trainerPublicProfile`, `trainerRequests` to Routes constants |
| `lib/core/navigation/app_shell.dart` | Add 4th tab: Trainer-Discovery (map icon) |
| `lib/features/admin/presentation/providers/admin_provider.dart` | Add `pendingTrainersProvider`, `approveTrainerProvider`, `suspendTrainerProvider` |
| `lib/features/admin/presentation/screens/admin_panel_screen.dart` | Add "Trainer-Anträge" 3rd tab + `_TrainerReviewTab` widget |
| `lib/l10n/app_localizations.dart` | Add abstract getters for all new strings |
| `lib/l10n/app_localizations_de.dart` | German strings |
| `lib/l10n/app_localizations_en.dart` | English strings |

---

## Task 1: Packages + Platform Permissions

**Files:**
- Modify: `pubspec.yaml`
- Modify: `ios/Runner/Info.plist`
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1.1: Add packages to pubspec.yaml**

In `pubspec.yaml`, under `dependencies:`, add after the existing `permission_handler` line:

```yaml
  flutter_map: ^7.0.2
  geolocator: ^13.0.2
  latlong2: ^0.9.1
```

- [ ] **Step 1.2: Add iOS location permission strings to Info.plist**

In `ios/Runner/Info.plist`, add inside the root `<dict>` (before the closing `</dict>`):

```xml
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>CoreJourney benötigt deinen Standort, um Trainer in deiner Nähe anzuzeigen.</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>CoreJourney benötigt deinen Standort, um Trainer in deiner Nähe anzuzeigen.</string>
```

- [ ] **Step 1.3: Add Android location permissions to AndroidManifest.xml**

In `android/app/src/main/AndroidManifest.xml`, add before the `<application` tag:

```xml
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

- [ ] **Step 1.4: Run flutter pub get and verify no errors**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter pub get
```

Expected: no dependency conflicts, flutter_map + geolocator + latlong2 in `.dart_tool/package_config.json`.

- [ ] **Step 1.5: Commit**

```bash
git add pubspec.yaml pubspec.lock ios/Runner/Info.plist android/app/src/main/AndroidManifest.xml
git commit -m "feat: add flutter_map, geolocator, latlong2 + platform location permissions"
```

---

## Task 2: Database Migration

**Files:**
- Create: `supabase/migrations/20260427_trainer_network.sql`

- [ ] **Step 2.1: Create the migration file**

```sql
-- CoreJourney — Trainer Network
-- PostGIS extension, trainer_profiles, trainer_profile_private,
-- source_type on trainer_client_relationships, all RPCs, RLS.
-- Idempotent: safe to re-run.

-- ── 0. PostGIS ────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS postgis;

-- ── 1. trainer_profiles ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trainer_profiles (
  id                   uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  display_name         text NOT NULL,
  bio                  text,
  photo_url            text,
  location_private     geography(POINT, 4326),
  location_public      geography(POINT, 4326),
  location_precision_m int  NOT NULL DEFAULT 1000,
  location_updated_at  timestamptz,
  status               text NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'active', 'suspended')),
  approved_at          timestamptz,
  approved_by          uuid REFERENCES profiles(id),
  submitted_at         timestamptz NOT NULL DEFAULT now(),
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_location_private
  ON trainer_profiles USING GIST (location_private);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_status
  ON trainer_profiles (status);

-- ── 2. trainer_profile_private ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trainer_profile_private (
  trainer_id    uuid PRIMARY KEY REFERENCES trainer_profiles(id) ON DELETE CASCADE,
  contact_email text NOT NULL,
  contact_phone text,
  admin_notes   text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- ── 3. source_type on trainer_client_relationships ───────────────────────────

ALTER TABLE trainer_client_relationships
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'invite'
  CHECK (source_type IN ('invite', 'discovery'));

-- One pending discovery request per trainer-client pair
CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_pending_discovery
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'pending' AND source_type = 'discovery' AND client_id IS NOT NULL;

-- ── 4. RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trainer reads own profile" ON trainer_profiles;
CREATE POLICY "Trainer reads own profile"
  ON trainer_profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins manage all trainer profiles" ON trainer_profiles;
CREATE POLICY "Admins manage all trainer profiles"
  ON trainer_profiles FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

ALTER TABLE trainer_profile_private ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trainer sees own private profile" ON trainer_profile_private;
CREATE POLICY "Trainer sees own private profile"
  ON trainer_profile_private FOR SELECT
  USING (auth.uid() = trainer_id);

DROP POLICY IF EXISTS "Admins manage private trainer profiles" ON trainer_profile_private;
CREATE POLICY "Admins manage private trainer profiles"
  ON trainer_profile_private FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── 5. Helper: jitter a geography point ──────────────────────────────────────

CREATE OR REPLACE FUNCTION _jitter_location(
  p_location    geography,
  p_precision_m int DEFAULT 1000
)
RETURNS geography
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_angle       float8 := random() * 2 * pi();
  v_radius_deg  float8 := (random() * p_precision_m / 111000.0);
  v_lat         float8 := ST_Y(p_location::geometry);
  v_lng         float8 := ST_X(p_location::geometry);
  v_offset_lat  float8 := v_radius_deg * sin(v_angle);
  v_offset_lng  float8 := v_radius_deg * cos(v_angle)
                          / NULLIF(cos(v_lat * pi() / 180.0), 0);
BEGIN
  RETURN ST_MakePoint(v_lng + v_offset_lng, v_lat + v_offset_lat)::geography;
END;
$$;

-- ── 6. upsert_trainer_profile ─────────────────────────────────────────────────
-- Creates or updates trainer_profiles + trainer_profile_private.
-- Status always stays 'pending' on upsert (approval is admin-only).

CREATE OR REPLACE FUNCTION upsert_trainer_profile(
  p_display_name  text,
  p_bio           text    DEFAULT NULL,
  p_photo_url     text    DEFAULT NULL,
  p_contact_email text    DEFAULT NULL,
  p_contact_phone text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id AND role = 'trainer') THEN
    RAISE EXCEPTION 'Nur Trainer können ein Trainer-Profil anlegen';
  END IF;

  IF trim(COALESCE(p_display_name, '')) = '' THEN
    RAISE EXCEPTION 'Anzeigename fehlt';
  END IF;

  INSERT INTO trainer_profiles (id, display_name, bio, photo_url)
  VALUES (v_user_id, trim(p_display_name), NULLIF(trim(COALESCE(p_bio, '')), ''), NULLIF(trim(COALESCE(p_photo_url, '')), ''))
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio          = EXCLUDED.bio,
    photo_url    = EXCLUDED.photo_url,
    updated_at   = now();

  IF p_contact_email IS NOT NULL THEN
    INSERT INTO trainer_profile_private (trainer_id, contact_email, contact_phone)
    VALUES (v_user_id, trim(p_contact_email), NULLIF(trim(COALESCE(p_contact_phone, '')), ''))
    ON CONFLICT (trainer_id) DO UPDATE SET
      contact_email = EXCLUDED.contact_email,
      contact_phone = EXCLUDED.contact_phone,
      updated_at    = now();
  END IF;
END;
$$;

-- ── 7. upsert_trainer_location ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION upsert_trainer_location(
  p_lat         float8,
  p_lng         float8,
  p_precision_m int DEFAULT 1000
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id      uuid := auth.uid();
  v_location_prv geography;
  v_location_pub geography;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'Ungültige Koordinaten';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM trainer_profiles WHERE id = v_user_id) THEN
    RAISE EXCEPTION 'Trainer-Profil nicht gefunden';
  END IF;

  v_location_prv := ST_MakePoint(p_lng, p_lat)::geography;
  v_location_pub := _jitter_location(v_location_prv, p_precision_m);

  UPDATE trainer_profiles
  SET
    location_private     = v_location_prv,
    location_public      = v_location_pub,
    location_precision_m = p_precision_m,
    location_updated_at  = now(),
    updated_at           = now()
  WHERE id = v_user_id;
END;
$$;

-- ── 8. find_trainers_nearby ───────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION find_trainers_nearby(
  lat       float8,
  lng       float8,
  radius_km float8 DEFAULT 25
)
RETURNS TABLE (
  id               uuid,
  display_name     text,
  bio              text,
  photo_url        text,
  distance_km      float8,
  public_latitude  float8,
  public_longitude float8,
  verified         boolean
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    ROUND((ST_Distance(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography
    ) / 1000.0)::numeric, 0)::float8 AS distance_km,
    ST_Y(tp.location_public::geometry) AS public_latitude,
    ST_X(tp.location_public::geometry) AS public_longitude,
    (tp.status = 'active') AS verified
  FROM trainer_profiles tp
  WHERE
    auth.uid() IS NOT NULL
    AND lat BETWEEN -90 AND 90
    AND lng BETWEEN -180 AND 180
    AND radius_km BETWEEN 1 AND 100
    AND tp.status = 'active'
    AND tp.location_private IS NOT NULL
    AND tp.location_public  IS NOT NULL
    AND ST_DWithin(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC;
$$;

-- ── 9. get_pending_trainers (admin) ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_pending_trainers()
RETURNS TABLE (
  id            uuid,
  display_name  text,
  bio           text,
  photo_url     text,
  contact_email text,
  contact_phone text,
  admin_notes   text,
  submitted_at  timestamptz,
  public_latitude  float8,
  public_longitude float8
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    tpp.contact_email,
    tpp.contact_phone,
    tpp.admin_notes,
    tp.submitted_at,
    CASE WHEN tp.location_private IS NOT NULL
      THEN ST_Y(tp.location_private::geometry) ELSE NULL END AS public_latitude,
    CASE WHEN tp.location_private IS NOT NULL
      THEN ST_X(tp.location_private::geometry) ELSE NULL END AS public_longitude
  FROM trainer_profiles tp
  LEFT JOIN trainer_profile_private tpp ON tpp.trainer_id = tp.id
  WHERE
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    AND tp.status = 'pending'
  ORDER BY tp.submitted_at ASC;
$$;

-- ── 10. admin_approve_trainer ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION admin_approve_trainer(p_trainer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Nur Admins können Trainer freigeben';
  END IF;

  UPDATE trainer_profiles
  SET
    status      = 'active',
    approved_at = now(),
    approved_by = auth.uid(),
    updated_at  = now()
  WHERE id = p_trainer_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trainer nicht gefunden oder nicht im pending-Status';
  END IF;
END;
$$;

-- ── 11. admin_suspend_trainer ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION admin_suspend_trainer(
  p_trainer_id uuid,
  p_notes      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Nur Admins können Trainer suspendieren';
  END IF;

  UPDATE trainer_profiles
  SET
    status     = 'suspended',
    updated_at = now()
  WHERE id = p_trainer_id;

  IF p_notes IS NOT NULL THEN
    INSERT INTO trainer_profile_private (trainer_id, contact_email, admin_notes)
    VALUES (p_trainer_id, '', p_notes)
    ON CONFLICT (trainer_id) DO UPDATE SET
      admin_notes = EXCLUDED.admin_notes,
      updated_at  = now();
  END IF;
END;
$$;

-- ── 12. send_discovery_request ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION send_discovery_request(p_trainer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_rel_id    uuid;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM trainer_profiles
    WHERE id = p_trainer_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Trainer nicht gefunden oder nicht aktiv';
  END IF;

  -- Block if already active with this trainer
  IF EXISTS (
    SELECT 1 FROM trainer_client_relationships
    WHERE trainer_id = p_trainer_id AND client_id = v_client_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Bereits mit diesem Trainer verbunden';
  END IF;

  INSERT INTO trainer_client_relationships (
    trainer_id, client_id, status, source_type
  ) VALUES (
    p_trainer_id, v_client_id, 'pending', 'discovery'
  )
  RETURNING id INTO v_rel_id;

  RETURN v_rel_id;
END;
$$;

-- ── 13. get_incoming_discovery_requests (trainer view) ────────────────────────

CREATE OR REPLACE FUNCTION get_incoming_discovery_requests()
RETURNS TABLE (
  relationship_id uuid,
  client_id       uuid,
  display_name    text,
  created_at      timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tcr.id AS relationship_id,
    tcr.client_id,
    p.display_name,
    tcr.created_at
  FROM trainer_client_relationships tcr
  JOIN profiles p ON p.id = tcr.client_id
  WHERE
    tcr.trainer_id   = auth.uid()
    AND tcr.status       = 'pending'
    AND tcr.source_type  = 'discovery'
    AND tcr.client_id IS NOT NULL
  ORDER BY tcr.created_at ASC;
$$;

-- ── 14. respond_discovery_request ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION respond_discovery_request(
  p_relationship_id uuid,
  p_accept          boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_client_id  uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  SELECT client_id INTO v_client_id
  FROM trainer_client_relationships
  WHERE id          = p_relationship_id
    AND trainer_id  = v_trainer_id
    AND status      = 'pending'
    AND source_type = 'discovery';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Anfrage nicht gefunden';
  END IF;

  IF p_accept THEN
    -- Deactivate existing active relationships for this client
    UPDATE trainer_client_relationships
    SET status = 'disconnected'
    WHERE client_id = v_client_id AND status = 'active';

    -- Activate this request
    UPDATE trainer_client_relationships
    SET
      status    = 'active',
      linked_at = now()
    WHERE id = p_relationship_id;

    -- Create direct chat channel
    PERFORM ensure_trainer_client_relationship(v_client_id);
  ELSE
    UPDATE trainer_client_relationships
    SET status = 'disconnected'
    WHERE id = p_relationship_id;
  END IF;
END;
$$;

-- ── 15. get_own_trainer_profile ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_own_trainer_profile()
RETURNS TABLE (
  id           uuid,
  display_name text,
  bio          text,
  photo_url    text,
  status       text,
  submitted_at timestamptz,
  has_location boolean
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    tp.status,
    tp.submitted_at,
    (tp.location_private IS NOT NULL) AS has_location
  FROM trainer_profiles tp
  WHERE tp.id = auth.uid();
$$;

-- ── 16. Grants ────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION upsert_trainer_profile(text, text, text, text, text)    TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_trainer_location(float8, float8, int)             TO authenticated;
GRANT EXECUTE ON FUNCTION find_trainers_nearby(float8, float8, float8)             TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_trainers()                                   TO authenticated;
GRANT EXECUTE ON FUNCTION admin_approve_trainer(uuid)                              TO authenticated;
GRANT EXECUTE ON FUNCTION admin_suspend_trainer(uuid, text)                        TO authenticated;
GRANT EXECUTE ON FUNCTION send_discovery_request(uuid)                             TO authenticated;
GRANT EXECUTE ON FUNCTION get_incoming_discovery_requests()                        TO authenticated;
GRANT EXECUTE ON FUNCTION respond_discovery_request(uuid, boolean)                 TO authenticated;
GRANT EXECUTE ON FUNCTION get_own_trainer_profile()                                TO authenticated;
```

- [ ] **Step 2.2: Apply migration to local Supabase**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
supabase db reset
# or apply incrementally:
supabase db push
```

Expected: no errors. PostGIS extension enabled, both tables created, all functions defined.

- [ ] **Step 2.3: Smoke-test RPCs in Supabase Studio**

In Studio → SQL Editor, run:
```sql
-- Verify tables
SELECT * FROM trainer_profiles LIMIT 1;
SELECT * FROM trainer_profile_private LIMIT 1;

-- Verify PostGIS
SELECT ST_MakePoint(13.4050, 52.5200)::geography;

-- Verify functions exist
SELECT proname FROM pg_proc WHERE proname LIKE '%trainer%' ORDER BY proname;
```

Expected: tables exist (empty), PostGIS returns a geography value, functions listed.

- [ ] **Step 2.4: Commit**

```bash
git add supabase/migrations/20260427_trainer_network.sql
git commit -m "feat: trainer network DB migration — trainer_profiles, PostGIS RPCs, RLS"
```

---

## Task 3: l10n Strings

**Files:**
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_de.dart`
- Modify: `lib/l10n/app_localizations_en.dart`

- [ ] **Step 3.1: Add abstract getters to app_localizations.dart**

Add the following inside the `AppLocalizations` abstract class, after the last existing `String get` declaration:

```dart
  // ── Trainer Discovery ─────────────────────────────────────────────────────
  String get trainerDiscoveryTitle;
  String get trainerDiscoveryEmpty;
  String trainerDiscoveryRadiusLabel(int km);
  String get trainerDiscoveryLocationRequired;
  String get trainerDiscoveryLocationDenied;
  String trainerDiscoveryDistanceLabel(double km);
  String get trainerDiscoverySendRequest;
  String get trainerDiscoveryRequestSent;
  String get trainerDiscoveryRequestAlreadySent;
  String get trainerDiscoveryRequestAlreadyConnected;

  // ── Trainer Profile Setup ─────────────────────────────────────────────────
  String get trainerSetupTitle;
  String get trainerSetupDisplayNameLabel;
  String get trainerSetupBioLabel;
  String get trainerSetupEmailLabel;
  String get trainerSetupPhoneLabel;
  String get trainerSetupLocationTitle;
  String get trainerSetupLocationHint;
  String get trainerSetupLocationMissing;
  String get trainerSetupSubmit;
  String get trainerSetupPendingTitle;
  String get trainerSetupPendingBody;

  // ── Trainer Public Profile ────────────────────────────────────────────────
  String get trainerPublicProfileTitle;
  String get trainerPublicProfileVerified;

  // ── Trainer Requests ──────────────────────────────────────────────────────
  String get trainerRequestsTitle;
  String get trainerRequestAccept;
  String get trainerRequestDecline;
  String get trainerRequestNoRequests;

  // ── Admin Trainer Review ──────────────────────────────────────────────────
  String get adminTrainerReviewTab;
  String get adminTrainerApprove;
  String get adminTrainerSuspend;
  String get adminTrainerNoPending;
  String get adminTrainerApproveSuccess;
  String get adminTrainerSuspendSuccess;
```

- [ ] **Step 3.2: Add German strings to app_localizations_de.dart**

Append inside the `AppLocalizationsDe` class:

```dart
  // ── Trainer Discovery ─────────────────────────────────────────────────────
  @override String get trainerDiscoveryTitle => 'Trainer in der Nähe';
  @override String get trainerDiscoveryEmpty => 'Keine Trainer in diesem Bereich gefunden.';
  @override String trainerDiscoveryRadiusLabel(int km) => 'Radius: $km km';
  @override String get trainerDiscoveryLocationRequired => 'Standort wird benötigt';
  @override String get trainerDiscoveryLocationDenied => 'Standort-Berechtigung verweigert. Bitte in den Einstellungen aktivieren.';
  @override String trainerDiscoveryDistanceLabel(double km) => '${km.toStringAsFixed(0)} km entfernt';
  @override String get trainerDiscoverySendRequest => 'Anfrage senden';
  @override String get trainerDiscoveryRequestSent => 'Anfrage gesendet.';
  @override String get trainerDiscoveryRequestAlreadySent => 'Anfrage bereits gesendet.';
  @override String get trainerDiscoveryRequestAlreadyConnected => 'Bereits mit diesem Trainer verbunden.';

  // ── Trainer Profile Setup ─────────────────────────────────────────────────
  @override String get trainerSetupTitle => 'Trainer-Profil einrichten';
  @override String get trainerSetupDisplayNameLabel => 'Anzeigename';
  @override String get trainerSetupBioLabel => 'Über mich (optional)';
  @override String get trainerSetupEmailLabel => 'Kontakt-E-Mail';
  @override String get trainerSetupPhoneLabel => 'Telefon (optional)';
  @override String get trainerSetupLocationTitle => 'Dein Standort';
  @override String get trainerSetupLocationHint => 'Tippe auf die Karte, um deinen Standort zu pinnen.';
  @override String get trainerSetupLocationMissing => 'Bitte setze deinen Standort auf der Karte.';
  @override String get trainerSetupSubmit => 'Profil einreichen';
  @override String get trainerSetupPendingTitle => 'Profil wird geprüft';
  @override String get trainerSetupPendingBody => 'Wir benachrichtigen dich, sobald dein Profil freigegeben wurde.';

  // ── Trainer Public Profile ────────────────────────────────────────────────
  @override String get trainerPublicProfileTitle => 'Trainer-Profil';
  @override String get trainerPublicProfileVerified => 'Verifiziert';

  // ── Trainer Requests ──────────────────────────────────────────────────────
  @override String get trainerRequestsTitle => 'Verbindungsanfragen';
  @override String get trainerRequestAccept => 'Annehmen';
  @override String get trainerRequestDecline => 'Ablehnen';
  @override String get trainerRequestNoRequests => 'Keine offenen Anfragen.';

  // ── Admin Trainer Review ──────────────────────────────────────────────────
  @override String get adminTrainerReviewTab => 'Trainer-Anträge';
  @override String get adminTrainerApprove => 'Freigeben';
  @override String get adminTrainerSuspend => 'Ablehnen';
  @override String get adminTrainerNoPending => 'Keine offenen Trainer-Anträge.';
  @override String get adminTrainerApproveSuccess => 'Trainer freigegeben.';
  @override String get adminTrainerSuspendSuccess => 'Trainer abgelehnt.';
```

- [ ] **Step 3.3: Add English strings to app_localizations_en.dart**

Append inside the `AppLocalizationsEn` class:

```dart
  // ── Trainer Discovery ─────────────────────────────────────────────────────
  @override String get trainerDiscoveryTitle => 'Trainers Nearby';
  @override String get trainerDiscoveryEmpty => 'No trainers found in this area.';
  @override String trainerDiscoveryRadiusLabel(int km) => 'Radius: $km km';
  @override String get trainerDiscoveryLocationRequired => 'Location required';
  @override String get trainerDiscoveryLocationDenied => 'Location permission denied. Please enable it in settings.';
  @override String trainerDiscoveryDistanceLabel(double km) => '${km.toStringAsFixed(0)} km away';
  @override String get trainerDiscoverySendRequest => 'Send Request';
  @override String get trainerDiscoveryRequestSent => 'Request sent.';
  @override String get trainerDiscoveryRequestAlreadySent => 'Request already sent.';
  @override String get trainerDiscoveryRequestAlreadyConnected => 'Already connected to this trainer.';

  // ── Trainer Profile Setup ─────────────────────────────────────────────────
  @override String get trainerSetupTitle => 'Set Up Trainer Profile';
  @override String get trainerSetupDisplayNameLabel => 'Display Name';
  @override String get trainerSetupBioLabel => 'About me (optional)';
  @override String get trainerSetupEmailLabel => 'Contact Email';
  @override String get trainerSetupPhoneLabel => 'Phone (optional)';
  @override String get trainerSetupLocationTitle => 'Your Location';
  @override String get trainerSetupLocationHint => 'Tap on the map to pin your location.';
  @override String get trainerSetupLocationMissing => 'Please set your location on the map.';
  @override String get trainerSetupSubmit => 'Submit Profile';
  @override String get trainerSetupPendingTitle => 'Profile under review';
  @override String get trainerSetupPendingBody => 'We will notify you once your profile has been approved.';

  // ── Trainer Public Profile ────────────────────────────────────────────────
  @override String get trainerPublicProfileTitle => 'Trainer Profile';
  @override String get trainerPublicProfileVerified => 'Verified';

  // ── Trainer Requests ──────────────────────────────────────────────────────
  @override String get trainerRequestsTitle => 'Connection Requests';
  @override String get trainerRequestAccept => 'Accept';
  @override String get trainerRequestDecline => 'Decline';
  @override String get trainerRequestNoRequests => 'No pending requests.';

  // ── Admin Trainer Review ──────────────────────────────────────────────────
  @override String get adminTrainerReviewTab => 'Trainer Applications';
  @override String get adminTrainerApprove => 'Approve';
  @override String get adminTrainerSuspend => 'Reject';
  @override String get adminTrainerNoPending => 'No pending trainer applications.';
  @override String get adminTrainerApproveSuccess => 'Trainer approved.';
  @override String get adminTrainerSuspendSuccess => 'Trainer rejected.';
```

- [ ] **Step 3.4: Run flutter analyze to verify no missing overrides**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/l10n/
```

Expected: no errors about unimplemented abstract members.

- [ ] **Step 3.5: Commit**

```bash
git add lib/l10n/
git commit -m "feat: add trainer network l10n strings (DE + EN)"
```

---

## Task 4: Domain Models + Tests

**Files:**
- Create: `lib/features/trainer/domain/models/trainer_profile.dart`
- Create: `lib/features/trainer/domain/models/trainer_discovery_request.dart`
- Create: `test/features/trainer/domain/models/trainer_profile_test.dart`
- Create: `test/features/trainer/domain/models/trainer_discovery_request_test.dart`

- [ ] **Step 4.1: Write failing tests for TrainerProfile**

Create `test/features/trainer/domain/models/trainer_profile_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/domain/models/trainer_profile.dart';

void main() {
  group('TrainerProfile.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max Muster',
        'bio': 'Certified trainer',
        'photo_url': 'https://example.com/photo.jpg',
        'distance_km': 8.0,
        'public_latitude': 52.5200,
        'public_longitude': 13.4050,
        'verified': true,
        'status': 'active',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };

      final profile = TrainerProfile.fromJson(json);

      expect(profile.id, 'abc-123');
      expect(profile.displayName, 'Max Muster');
      expect(profile.bio, 'Certified trainer');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.distanceKm, 8.0);
      expect(profile.publicLatitude, 52.5200);
      expect(profile.publicLongitude, 13.4050);
      expect(profile.verified, true);
      expect(profile.status, TrainerProfileStatus.active);
      expect(profile.submittedAt, DateTime.utc(2026, 4, 1, 10, 0, 0));
    });

    test('nullable fields are null when absent', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max Muster',
        'bio': null,
        'photo_url': null,
        'distance_km': null,
        'public_latitude': null,
        'public_longitude': null,
        'verified': false,
        'status': 'pending',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };

      final profile = TrainerProfile.fromJson(json);

      expect(profile.bio, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.distanceKm, isNull);
      expect(profile.publicLatitude, isNull);
      expect(profile.publicLongitude, isNull);
    });

    test('unknown status maps to pending', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max',
        'bio': null,
        'photo_url': null,
        'distance_km': null,
        'public_latitude': null,
        'public_longitude': null,
        'verified': false,
        'status': 'unknown_future_value',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };

      final profile = TrainerProfile.fromJson(json);
      expect(profile.status, TrainerProfileStatus.pending);
    });

    test('integer distance_km is coerced to double', () {
      final json = {
        'id': 'abc-123',
        'display_name': 'Max',
        'bio': null,
        'photo_url': null,
        'distance_km': 5,
        'public_latitude': 52.0,
        'public_longitude': 13.0,
        'verified': true,
        'status': 'active',
        'submitted_at': '2026-04-01T10:00:00.000Z',
      };

      final profile = TrainerProfile.fromJson(json);
      expect(profile.distanceKm, 5.0);
    });
  });
}
```

- [ ] **Step 4.2: Run test to verify it fails**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter test test/features/trainer/domain/models/trainer_profile_test.dart
```

Expected: FAIL — `trainer_profile.dart` does not exist.

- [ ] **Step 4.3: Create TrainerProfile model**

Create `lib/features/trainer/domain/models/trainer_profile.dart`:

```dart
enum TrainerProfileStatus { pending, active, suspended }

class TrainerProfile {
  const TrainerProfile({
    required this.id,
    required this.displayName,
    this.bio,
    this.photoUrl,
    this.distanceKm,
    this.publicLatitude,
    this.publicLongitude,
    required this.verified,
    required this.status,
    required this.submittedAt,
    this.contactEmail,
    this.contactPhone,
    this.adminNotes,
    this.hasLocation = false,
  });

  final String id;
  final String displayName;
  final String? bio;
  final String? photoUrl;
  final double? distanceKm;
  final double? publicLatitude;
  final double? publicLongitude;
  final bool verified;
  final TrainerProfileStatus status;
  final DateTime submittedAt;
  final String? contactEmail;
  final String? contactPhone;
  final String? adminNotes;
  final bool hasLocation;

  static TrainerProfileStatus _parseStatus(String? s) {
    switch (s) {
      case 'active': return TrainerProfileStatus.active;
      case 'suspended': return TrainerProfileStatus.suspended;
      default: return TrainerProfileStatus.pending;
    }
  }

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    return TrainerProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      publicLatitude: (json['public_latitude'] as num?)?.toDouble(),
      publicLongitude: (json['public_longitude'] as num?)?.toDouble(),
      verified: json['verified'] as bool? ?? false,
      status: _parseStatus(json['status'] as String?),
      submittedAt: DateTime.parse(json['submitted_at'] as String),
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      adminNotes: json['admin_notes'] as String?,
      hasLocation: json['has_location'] as bool? ?? false,
    );
  }
}
```

- [ ] **Step 4.4: Run test to verify it passes**

```bash
flutter test test/features/trainer/domain/models/trainer_profile_test.dart
```

Expected: 4 tests pass.

- [ ] **Step 4.5: Write failing tests for TrainerDiscoveryRequest**

Create `test/features/trainer/domain/models/trainer_discovery_request_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/domain/models/trainer_discovery_request.dart';

void main() {
  group('TrainerDiscoveryRequest.fromJson', () {
    test('parses all fields correctly', () {
      final json = {
        'relationship_id': 'rel-123',
        'client_id': 'client-456',
        'display_name': 'Anna Müller',
        'created_at': '2026-04-27T09:00:00.000Z',
      };

      final req = TrainerDiscoveryRequest.fromJson(json);

      expect(req.relationshipId, 'rel-123');
      expect(req.clientId, 'client-456');
      expect(req.displayName, 'Anna Müller');
      expect(req.createdAt, DateTime.utc(2026, 4, 27, 9, 0, 0));
    });
  });
}
```

- [ ] **Step 4.6: Run test to verify it fails**

```bash
flutter test test/features/trainer/domain/models/trainer_discovery_request_test.dart
```

Expected: FAIL — `trainer_discovery_request.dart` does not exist.

- [ ] **Step 4.7: Create TrainerDiscoveryRequest model**

Create `lib/features/trainer/domain/models/trainer_discovery_request.dart`:

```dart
class TrainerDiscoveryRequest {
  const TrainerDiscoveryRequest({
    required this.relationshipId,
    required this.clientId,
    required this.displayName,
    required this.createdAt,
  });

  final String relationshipId;
  final String clientId;
  final String displayName;
  final DateTime createdAt;

  factory TrainerDiscoveryRequest.fromJson(Map<String, dynamic> json) {
    return TrainerDiscoveryRequest(
      relationshipId: json['relationship_id'] as String,
      clientId: json['client_id'] as String,
      displayName: json['display_name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
```

- [ ] **Step 4.8: Run all model tests**

```bash
flutter test test/features/trainer/domain/models/
```

Expected: all 5 tests pass.

- [ ] **Step 4.9: Commit**

```bash
git add lib/features/trainer/domain/models/ test/features/trainer/domain/models/
git commit -m "feat: TrainerProfile + TrainerDiscoveryRequest models with tests"
```

---

## Task 5: Repository + Supabase Implementation

**Files:**
- Create: `lib/features/trainer/domain/repositories/trainer_profile_repository.dart`
- Create: `lib/features/trainer/data/repositories/supabase_trainer_profile_repository.dart`

- [ ] **Step 5.1: Create abstract repository**

Create `lib/features/trainer/domain/repositories/trainer_profile_repository.dart`:

```dart
import '../models/trainer_discovery_request.dart';
import '../models/trainer_profile.dart';

abstract class TrainerProfileRepository {
  Future<List<TrainerProfile>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
  });

  Future<TrainerProfile?> getOwnProfile();

  Future<void> upsertProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
    required String contactEmail,
    String? contactPhone,
  });

  Future<void> updateLocation(double lat, double lng);

  Future<List<TrainerProfile>> getPendingTrainers();

  Future<void> approveTrainer(String trainerId);

  Future<void> suspendTrainer(String trainerId);

  Future<void> sendConnectionRequest(String trainerId);

  Future<List<TrainerDiscoveryRequest>> getIncomingRequests();

  Future<void> respondToRequest(String relationshipId, {required bool accept});
}
```

- [ ] **Step 5.2: Create Supabase implementation**

Create `lib/features/trainer/data/repositories/supabase_trainer_profile_repository.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/trainer_discovery_request.dart';
import '../../domain/models/trainer_profile.dart';
import '../../domain/repositories/trainer_profile_repository.dart';

class SupabaseTrainerProfileRepository implements TrainerProfileRepository {
  SupabaseTrainerProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TrainerProfile>> findNearby({
    required double lat,
    required double lng,
    double radiusKm = 25,
  }) async {
    final res = await _client.rpc('find_trainers_nearby', params: {
      'lat': lat,
      'lng': lng,
      'radius_km': radiusKm,
    });
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerProfile.fromJson)
        .toList();
  }

  @override
  Future<TrainerProfile?> getOwnProfile() async {
    final res = await _client.rpc('get_own_trainer_profile');
    final list = (res as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) return null;
    return TrainerProfile.fromJson(list.first);
  }

  @override
  Future<void> upsertProfile({
    required String displayName,
    String? bio,
    String? photoUrl,
    required String contactEmail,
    String? contactPhone,
  }) async {
    await _client.rpc('upsert_trainer_profile', params: {
      'p_display_name': displayName,
      'p_bio': bio,
      'p_photo_url': photoUrl,
      'p_contact_email': contactEmail,
      'p_contact_phone': contactPhone,
    });
  }

  @override
  Future<void> updateLocation(double lat, double lng) async {
    await _client.rpc('upsert_trainer_location', params: {
      'p_lat': lat,
      'p_lng': lng,
    });
  }

  @override
  Future<List<TrainerProfile>> getPendingTrainers() async {
    final res = await _client.rpc('get_pending_trainers');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerProfile.fromJson)
        .toList();
  }

  @override
  Future<void> approveTrainer(String trainerId) async {
    await _client.rpc('admin_approve_trainer', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<void> suspendTrainer(String trainerId) async {
    await _client.rpc('admin_suspend_trainer', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<void> sendConnectionRequest(String trainerId) async {
    await _client.rpc('send_discovery_request', params: {
      'p_trainer_id': trainerId,
    });
  }

  @override
  Future<List<TrainerDiscoveryRequest>> getIncomingRequests() async {
    final res = await _client.rpc('get_incoming_discovery_requests');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(TrainerDiscoveryRequest.fromJson)
        .toList();
  }

  @override
  Future<void> respondToRequest(
    String relationshipId, {
    required bool accept,
  }) async {
    await _client.rpc('respond_discovery_request', params: {
      'p_relationship_id': relationshipId,
      'p_accept': accept,
    });
  }
}
```

- [ ] **Step 5.3: Run flutter analyze**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze lib/features/trainer/
```

Expected: no errors.

- [ ] **Step 5.4: Commit**

```bash
git add lib/features/trainer/domain/repositories/ lib/features/trainer/data/
git commit -m "feat: TrainerProfileRepository abstract + Supabase implementation"
```

---

## Task 6: Riverpod Providers

**Files:**
- Create: `lib/features/trainer/presentation/providers/trainer_discovery_provider.dart`

- [ ] **Step 6.1: Create discovery providers**

Create `lib/features/trainer/presentation/providers/trainer_discovery_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_trainer_profile_repository.dart';
import '../../domain/models/trainer_discovery_request.dart';
import '../../domain/models/trainer_profile.dart';
import '../../domain/repositories/trainer_profile_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final trainerProfileRepositoryProvider = Provider<TrainerProfileRepository>(
  (ref) => SupabaseTrainerProfileRepository(Supabase.instance.client),
);

// ── Own trainer profile ───────────────────────────────────────────────────────

final ownTrainerProfileProvider = FutureProvider<TrainerProfile?>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(trainerProfileRepositoryProvider).getOwnProfile();
});

// ── Nearby trainer search ─────────────────────────────────────────────────────

class NearbyParams {
  const NearbyParams({
    required this.lat,
    required this.lng,
    required this.radiusKm,
  });
  final double lat;
  final double lng;
  final double radiusKm;
}

final nearbyTrainersProvider =
    FutureProvider.family<List<TrainerProfile>, NearbyParams>(
  (ref, params) => ref.read(trainerProfileRepositoryProvider).findNearby(
        lat: params.lat,
        lng: params.lng,
        radiusKm: params.radiusKm,
      ),
);

// ── Pending trainers (admin) ──────────────────────────────────────────────────

class PendingTrainersNotifier extends AsyncNotifier<List<TrainerProfile>> {
  @override
  Future<List<TrainerProfile>> build() {
    ref.watch(authStateProvider);
    return ref.read(trainerProfileRepositoryProvider).getPendingTrainers();
  }

  Future<void> approve(String trainerId) async {
    await ref.read(trainerProfileRepositoryProvider).approveTrainer(trainerId);
    ref.invalidateSelf();
  }

  Future<void> suspend(String trainerId) async {
    await ref.read(trainerProfileRepositoryProvider).suspendTrainer(trainerId);
    ref.invalidateSelf();
  }
}

final pendingTrainersProvider =
    AsyncNotifierProvider<PendingTrainersNotifier, List<TrainerProfile>>(
  PendingTrainersNotifier.new,
);

// ── Incoming discovery requests (trainer) ─────────────────────────────────────

class IncomingRequestsNotifier
    extends AsyncNotifier<List<TrainerDiscoveryRequest>> {
  @override
  Future<List<TrainerDiscoveryRequest>> build() {
    ref.watch(authStateProvider);
    return ref
        .read(trainerProfileRepositoryProvider)
        .getIncomingRequests();
  }

  Future<void> respond(String relationshipId, {required bool accept}) async {
    await ref
        .read(trainerProfileRepositoryProvider)
        .respondToRequest(relationshipId, accept: accept);
    ref.invalidateSelf();
  }
}

final incomingRequestsProvider =
    AsyncNotifierProvider<IncomingRequestsNotifier,
        List<TrainerDiscoveryRequest>>(
  IncomingRequestsNotifier.new,
);

// ── Send connection request ───────────────────────────────────────────────────

Future<void> sendDiscoveryRequest(Ref ref, String trainerId) {
  return ref.read(trainerProfileRepositoryProvider).sendConnectionRequest(trainerId);
}
```

- [ ] **Step 6.2: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/providers/trainer_discovery_provider.dart
```

Expected: no errors.

- [ ] **Step 6.3: Commit**

```bash
git add lib/features/trainer/presentation/providers/trainer_discovery_provider.dart
git commit -m "feat: Riverpod providers for trainer discovery, admin review, incoming requests"
```

---

## Task 7: TrainerLocationPickerWidget

**Files:**
- Create: `lib/features/trainer/presentation/widgets/trainer_location_picker_widget.dart`

- [ ] **Step 7.1: Create the location picker widget**

Create `lib/features/trainer/presentation/widgets/trainer_location_picker_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class TrainerLocationPickerWidget extends StatefulWidget {
  const TrainerLocationPickerWidget({
    super.key,
    this.initialLatLng,
    required this.onLocationPicked,
  });

  final LatLng? initialLatLng;
  final void Function(LatLng latLng) onLocationPicked;

  @override
  State<TrainerLocationPickerWidget> createState() =>
      _TrainerLocationPickerWidgetState();
}

class _TrainerLocationPickerWidgetState
    extends State<TrainerLocationPickerWidget> {
  late final MapController _mapController;
  LatLng? _pickedLocation;

  // Default center: Germany (Munich)
  static const _defaultCenter = LatLng(48.1351, 11.5820);
  static const _defaultZoom = 10.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pickedLocation = widget.initialLatLng;
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onTap(TapPosition _, LatLng latLng) {
    setState(() => _pickedLocation = latLng);
    widget.onLocationPicked(latLng);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _pickedLocation ?? _defaultCenter,
            initialZoom: _defaultZoom,
            onTap: _onTap,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.alexandermessinger.corejourney',
            ),
            if (_pickedLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _pickedLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),
        if (_pickedLocation == null)
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Tippe auf die Karte',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7.2: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/widgets/trainer_location_picker_widget.dart
```

Expected: no errors.

- [ ] **Step 7.3: Commit**

```bash
git add lib/features/trainer/presentation/widgets/trainer_location_picker_widget.dart
git commit -m "feat: TrainerLocationPickerWidget — interactive map pin for trainer location"
```

---

## Task 8: TrainerProfileSetupScreen + TrainerProfilePendingScreen

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart`
- Create: `lib/features/trainer/presentation/screens/trainer_profile_pending_screen.dart`

- [ ] **Step 8.1: Create TrainerProfileSetupScreen**

Create `lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/trainer_discovery_provider.dart';
import '../widgets/trainer_location_picker_widget.dart';

class TrainerProfileSetupScreen extends ConsumerStatefulWidget {
  const TrainerProfileSetupScreen({super.key});

  @override
  ConsumerState<TrainerProfileSetupScreen> createState() =>
      _TrainerProfileSetupScreenState();
}

class _TrainerProfileSetupScreenState
    extends ConsumerState<TrainerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  LatLng? _pickedLocation;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    if (_pickedLocation == null) {
      setState(() => _errorMessage = l10n.trainerSetupLocationMissing);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(trainerProfileRepositoryProvider);
      await repo.upsertProfile(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        contactEmail: _emailController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      );
      await repo.updateLocation(
        _pickedLocation!.latitude,
        _pickedLocation!.longitude,
      );
      ref.invalidate(ownTrainerProfileProvider);
      if (mounted) context.go(Routes.trainerProfilePending);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerSetupTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayNameController,
              decoration:
                  InputDecoration(labelText: l10n.trainerSetupDisplayNameLabel),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? l10n.validationRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioController,
              decoration: InputDecoration(labelText: l10n.trainerSetupBioLabel),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              decoration:
                  InputDecoration(labelText: l10n.trainerSetupEmailLabel),
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  (v == null || !v.contains('@')) ? l10n.validationInvalidEmail : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: l10n.trainerSetupPhoneLabel),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Text(l10n.trainerSetupLocationTitle,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.trainerSetupLocationHint,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: TrainerLocationPickerWidget(
                  onLocationPicked: (latLng) =>
                      setState(() => _pickedLocation = latLng),
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.trainerSetupSubmit),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.2: Create TrainerProfilePendingScreen**

Create `lib/features/trainer/presentation/screens/trainer_profile_pending_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class TrainerProfilePendingScreen extends StatelessWidget {
  const TrainerProfilePendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  size: 72, color: AppColors.primary),
              const SizedBox(height: 24),
              Text(
                l10n.trainerSetupPendingTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.trainerSetupPendingBody,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.3: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart lib/features/trainer/presentation/screens/trainer_profile_pending_screen.dart
```

Expected: no errors (Routes.trainerProfilePending will be unresolved until Task 13 — that's OK at analyze-time if not imported; if it is imported and missing, add a placeholder constant temporarily).

- [ ] **Step 8.4: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart lib/features/trainer/presentation/screens/trainer_profile_pending_screen.dart
git commit -m "feat: TrainerProfileSetupScreen + TrainerProfilePendingScreen"
```

---

## Task 9: Admin Trainer Review

**Files:**
- Modify: `lib/features/admin/presentation/providers/admin_provider.dart`
- Modify: `lib/features/admin/presentation/screens/admin_panel_screen.dart`

- [ ] **Step 9.1: Add pending trainers providers to admin_provider.dart**

In `lib/features/admin/presentation/providers/admin_provider.dart`, append after the existing `adminUsersProvider`:

```dart
// ── Pending trainers ──────────────────────────────────────────────────────────

import '../../features/trainer/presentation/providers/trainer_discovery_provider.dart'
    as trainer_providers;

// Re-export for admin panel convenience
final adminPendingTrainersProvider = trainer_providers.pendingTrainersProvider;
```

Actually, to keep it simple and avoid circular imports, directly use `pendingTrainersProvider` from trainer_discovery_provider in the admin panel screen. No changes needed to admin_provider.dart.

- [ ] **Step 9.2: Add "Trainer-Anträge" tab to AdminPanelScreen**

In `lib/features/admin/presentation/screens/admin_panel_screen.dart`:

1. Add import at the top:
```dart
import '../../../trainer/presentation/providers/trainer_discovery_provider.dart';
import '../../../trainer/domain/models/trainer_profile.dart';
```

2. Change `DefaultTabController(length: 2,` to `DefaultTabController(length: 3,`

3. Add to `TabBar`:
```dart
          Tab(text: l10n.adminTrainerReviewTab),
```

4. Add to `TabBarView`:
```dart
            const _TrainerReviewTab(),
```

5. Add the `_TrainerReviewTab` widget class at the bottom of the file:

```dart
class _TrainerReviewTab extends ConsumerWidget {
  const _TrainerReviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncTrainers = ref.watch(pendingTrainersProvider);

    return asyncTrainers.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (trainers) {
        if (trainers.isEmpty) {
          return Center(child: Text(l10n.adminTrainerNoPending));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trainers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _TrainerReviewCard(trainer: trainers[i]),
        );
      },
    );
  }
}

class _TrainerReviewCard extends ConsumerWidget {
  const _TrainerReviewCard({required this.trainer});

  final TrainerProfile trainer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(pendingTrainersProvider.notifier);

    Future<void> onApprove() async {
      await notifier.approve(trainer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminTrainerApproveSuccess)),
        );
      }
    }

    Future<void> onSuspend() async {
      await notifier.suspend(trainer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.adminTrainerSuspendSuccess)),
        );
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (trainer.photoUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(trainer.photoUrl!),
                    radius: 24,
                  )
                else
                  const CircleAvatar(
                    radius: 24,
                    child: Icon(Icons.person),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trainer.displayName,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (trainer.contactEmail != null)
                        Text(trainer.contactEmail!,
                            style: Theme.of(context).textTheme.bodySmall),
                      if (trainer.contactPhone != null)
                        Text(trainer.contactPhone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            if (trainer.bio != null) ...[
              const SizedBox(height: 8),
              Text(trainer.bio!),
            ],
            const SizedBox(height: 8),
            Text(
              'Eingereicht: ${trainer.submittedAt.toLocal().toString().substring(0, 10)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onApprove,
                    child: Text(l10n.adminTrainerApprove),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onSuspend,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(l10n.adminTrainerSuspend),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

Also add `final l10n = AppLocalizations.of(context);` to the `build` method of `AdminPanelScreen` (before the `return`).

- [ ] **Step 9.3: Run flutter analyze**

```bash
flutter analyze lib/features/admin/
```

Expected: no errors.

- [ ] **Step 9.4: Commit**

```bash
git add lib/features/admin/
git commit -m "feat: Trainer-Anträge tab in AdminPanelScreen — approve/suspend pending trainers"
```

---

## Task 10: TrainerDiscoveryScreen

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_discovery_screen.dart`

- [ ] **Step 10.1: Create the discovery screen**

Create `lib/features/trainer/presentation/screens/trainer_discovery_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerDiscoveryScreen extends ConsumerStatefulWidget {
  const TrainerDiscoveryScreen({super.key});

  @override
  ConsumerState<TrainerDiscoveryScreen> createState() =>
      _TrainerDiscoveryScreenState();
}

class _TrainerDiscoveryScreenState
    extends ConsumerState<TrainerDiscoveryScreen> {
  double _radiusKm = 25;
  Position? _userPosition;
  String? _locationError;
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              AppLocalizations.of(context).trainerDiscoveryLocationDenied;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = pos;
        _loadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loadingLocation) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_locationError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.trainerDiscoveryTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_locationError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _loadingLocation = true;
                      _locationError = null;
                    });
                    _fetchLocation();
                  },
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final params = NearbyParams(
      lat: _userPosition!.latitude,
      lng: _userPosition!.longitude,
      radiusKm: _radiusKm,
    );
    final asyncTrainers = ref.watch(nearbyTrainersProvider(params));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerDiscoveryTitle)),
      body: Column(
        children: [
          // Radius slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(l10n.trainerDiscoveryRadiusLabel(_radiusKm.round())),
                Expanded(
                  child: Slider(
                    value: _radiusKm,
                    min: 5,
                    max: 100,
                    divisions: 19,
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncTrainers.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(e.toString())),
              data: (trainers) => _TrainerResults(
                trainers: trainers,
                userLat: _userPosition!.latitude,
                userLng: _userPosition!.longitude,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainerResults extends StatefulWidget {
  const _TrainerResults({
    required this.trainers,
    required this.userLat,
    required this.userLng,
    required this.l10n,
  });

  final List<TrainerProfile> trainers;
  final double userLat;
  final double userLng;
  final AppLocalizations l10n;

  @override
  State<_TrainerResults> createState() => _TrainerResultsState();
}

class _TrainerResultsState extends State<_TrainerResults>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.trainers.isEmpty) {
      return Center(child: Text(widget.l10n.trainerDiscoveryEmpty));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Karte'),
            Tab(icon: Icon(Icons.list_outlined), text: 'Liste'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _MapView(
                trainers: widget.trainers,
                userLat: widget.userLat,
                userLng: widget.userLng,
              ),
              _ListView(trainers: widget.trainers, l10n: widget.l10n),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    required this.trainers,
    required this.userLat,
    required this.userLng,
  });

  final List<TrainerProfile> trainers;
  final double userLat;
  final double userLng;

  @override
  Widget build(BuildContext context) {
    final userLatLng = LatLng(userLat, userLng);

    return FlutterMap(
      options: MapOptions(
        initialCenter: userLatLng,
        initialZoom: 10,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.alexandermessinger.corejourney',
        ),
        MarkerLayer(
          markers: [
            // User location
            Marker(
              point: userLatLng,
              width: 20,
              height: 20,
              child: const Icon(Icons.my_location,
                  color: AppColors.info, size: 20),
            ),
            // Trainer pins (approximate)
            for (final t in trainers)
              if (t.publicLatitude != null && t.publicLongitude != null)
                Marker(
                  point: LatLng(t.publicLatitude!, t.publicLongitude!),
                  width: 36,
                  height: 36,
                  child: GestureDetector(
                    onTap: () => context.push(
                      Routes.trainerPublicProfile,
                      extra: t,
                    ),
                    child: const Icon(Icons.person_pin_circle,
                        color: AppColors.primary, size: 36),
                  ),
                ),
          ],
        ),
      ],
    );
  }
}

class _ListView extends StatelessWidget {
  const _ListView({required this.trainers, required this.l10n});

  final List<TrainerProfile> trainers;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: trainers.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final t = trainers[i];
        return ListTile(
          leading: t.photoUrl != null
              ? CircleAvatar(backgroundImage: NetworkImage(t.photoUrl!))
              : const CircleAvatar(child: Icon(Icons.person)),
          title: Row(
            children: [
              Text(t.displayName),
              if (t.verified) ...[
                const SizedBox(width: 4),
                const Icon(Icons.verified,
                    color: AppColors.primary, size: 16),
              ],
            ],
          ),
          subtitle: t.distanceKm != null
              ? Text(l10n.trainerDiscoveryDistanceLabel(t.distanceKm!))
              : null,
          onTap: () => context.push(Routes.trainerPublicProfile, extra: t),
        );
      },
    );
  }
}
```

- [ ] **Step 10.2: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_discovery_screen.dart
```

Expected: no errors (Routes.trainerPublicProfile unresolved until Task 13 — OK at analyze if not imported yet).

- [ ] **Step 10.3: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_discovery_screen.dart
git commit -m "feat: TrainerDiscoveryScreen — map + list + radius slider"
```

---

## Task 11: TrainerPublicProfileScreen

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart`

- [ ] **Step 11.1: Create the public profile screen**

Create `lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_profile.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerPublicProfileScreen extends ConsumerStatefulWidget {
  const TrainerPublicProfileScreen({super.key, required this.trainer});

  final TrainerProfile trainer;

  @override
  ConsumerState<TrainerPublicProfileScreen> createState() =>
      _TrainerPublicProfileScreenState();
}

class _TrainerPublicProfileScreenState
    extends ConsumerState<TrainerPublicProfileScreen> {
  bool _isRequesting = false;
  bool _requestSent = false;
  String? _errorMessage;

  Future<void> _sendRequest() async {
    setState(() {
      _isRequesting = true;
      _errorMessage = null;
    });
    try {
      await sendDiscoveryRequest(ref, widget.trainer.id);
      setState(() => _requestSent = true);
    } on Exception catch (e) {
      final msg = e.toString();
      if (msg.contains('Anfrage bereits gesendet') ||
          msg.contains('already')) {
        final l10n = AppLocalizations.of(context);
        setState(() =>
            _errorMessage = l10n.trainerDiscoveryRequestAlreadySent);
      } else if (msg.contains('bereits verbunden') || msg.contains('connected')) {
        final l10n = AppLocalizations.of(context);
        setState(() =>
            _errorMessage = l10n.trainerDiscoveryRequestAlreadyConnected);
      } else {
        setState(() => _errorMessage = msg);
      }
    } finally {
      if (mounted) setState(() => _isRequesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = widget.trainer;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerPublicProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: t.photoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(t.photoUrl!),
                    radius: 48,
                  )
                : const CircleAvatar(
                    radius: 48,
                    child: Icon(Icons.person, size: 48),
                  ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (t.verified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified,
                      color: AppColors.primary, size: 22),
                ],
              ],
            ),
          ),
          if (t.verified)
            Center(
              child: Text(
                l10n.trainerPublicProfileVerified,
                style: const TextStyle(color: AppColors.primary),
              ),
            ),
          if (t.distanceKm != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                l10n.trainerDiscoveryDistanceLabel(t.distanceKm!),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
          if (t.bio != null) ...[
            const SizedBox(height: 24),
            Text(t.bio!),
          ],
          const SizedBox(height: 32),
          if (_requestSent)
            Center(
              child: Text(
                l10n.trainerDiscoveryRequestSent,
                style: const TextStyle(color: AppColors.success),
              ),
            )
          else ...[
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            FilledButton(
              onPressed: _isRequesting ? null : _sendRequest,
              child: _isRequesting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.trainerDiscoverySendRequest),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 11.2: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart
```

Expected: no errors.

- [ ] **Step 11.3: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_public_profile_screen.dart
git commit -m "feat: TrainerPublicProfileScreen — profile view + send connection request"
```

---

## Task 12: TrainerRequestsScreen

**Files:**
- Create: `lib/features/trainer/presentation/screens/trainer_requests_screen.dart`
- Modify: `lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`

- [ ] **Step 12.1: Create the requests screen**

Create `lib/features/trainer/presentation/screens/trainer_requests_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_discovery_request.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerRequestsScreen extends ConsumerWidget {
  const TrainerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncRequests = ref.watch(incomingRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerRequestsTitle)),
      body: asyncRequests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(child: Text(l10n.trainerRequestNoRequests));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerWidget {
  const _RequestCard({required this.request});

  final TrainerDiscoveryRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(incomingRequestsProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    request.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              request.createdAt.toLocal().toString().substring(0, 10),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => notifier.respond(
                      request.relationshipId,
                      accept: true,
                    ),
                    child: Text(l10n.trainerRequestAccept),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => notifier.respond(
                      request.relationshipId,
                      accept: false,
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    child: Text(l10n.trainerRequestDecline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 12.2: Add requests button to TrainerDashboardScreen**

In `lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`, in the `AppBar`'s `actions` list, add before the last existing action (or as a new action):

```dart
            // Add this import at the top of the file:
            // import '../../../../core/navigation/app_router.dart';
            // (already imported if Routes is used)
            IconButton(
              icon: const Icon(Icons.inbox_outlined),
              tooltip: 'Verbindungsanfragen',
              onPressed: () => context.push(Routes.trainerRequests),
            ),
```

- [ ] **Step 12.3: Run flutter analyze**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_requests_screen.dart lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart
```

Expected: no errors.

- [ ] **Step 12.4: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_requests_screen.dart lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart
git commit -m "feat: TrainerRequestsScreen + inbox button in trainer dashboard"
```

---

## Task 13: Routes + AppShell + AppRouter Wiring

**Files:**
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/core/navigation/app_shell.dart`

- [ ] **Step 13.1: Add route constants to app_router.dart**

In `lib/core/navigation/app_router.dart`, in the `Routes` class, add:

```dart
  static const trainerDiscovery = '/trainers';
  static const trainerProfileSetup = '/trainer/profile-setup';
  static const trainerProfilePending = '/trainer/profile-pending';
  static const trainerPublicProfile = '/trainers/:trainerId';
  static const trainerRequests = '/trainer/requests';
```

- [ ] **Step 13.2: Add imports for new screens to app_router.dart**

At the top of `lib/core/navigation/app_router.dart`, add:

```dart
import '../../features/trainer/presentation/screens/trainer_discovery_screen.dart';
import '../../features/trainer/presentation/screens/trainer_profile_setup_screen.dart';
import '../../features/trainer/presentation/screens/trainer_profile_pending_screen.dart';
import '../../features/trainer/presentation/screens/trainer_public_profile_screen.dart';
import '../../features/trainer/presentation/screens/trainer_requests_screen.dart';
import '../../features/trainer/domain/models/trainer_profile.dart';
```

- [ ] **Step 13.3: Add trainerDiscovery to the ShellRoute**

In `app_router.dart`, inside the `ShellRoute` routes list, add after the `community` route:

```dart
          GoRoute(
            path: Routes.trainerDiscovery,
            name: 'trainer-discovery',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const TrainerDiscoveryScreen(),
            ),
          ),
```

- [ ] **Step 13.4: Add non-shell routes (setup, pending, public profile, requests)**

After the ShellRoute closing bracket (before `errorBuilder`), add:

```dart
      GoRoute(
        path: Routes.trainerProfileSetup,
        name: 'trainer-profile-setup',
        builder: (context, state) => const TrainerProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.trainerProfilePending,
        name: 'trainer-profile-pending',
        builder: (context, state) => const TrainerProfilePendingScreen(),
      ),
      GoRoute(
        path: Routes.trainerPublicProfile,
        name: 'trainer-public-profile',
        builder: (context, state) {
          final trainer = state.extra as TrainerProfile;
          return TrainerPublicProfileScreen(trainer: trainer);
        },
      ),
      GoRoute(
        path: Routes.trainerRequests,
        name: 'trainer-requests',
        builder: (context, state) => const TrainerRequestsScreen(),
      ),
```

- [ ] **Step 13.5: Add Discovery tab to AppShell**

In `lib/core/navigation/app_shell.dart`:

1. Change `_tabRoutes` to:
```dart
  static const _tabRoutes = [
    Routes.dashboard,
    Routes.community,
    Routes.trainerDiscovery,
    Routes.profile,
  ];
```

2. Change `NavigationBar` destinations to 4:
```dart
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Trainer',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
```

- [ ] **Step 13.6: Run flutter analyze on navigation**

```bash
flutter analyze lib/core/navigation/
```

Expected: no errors.

- [ ] **Step 13.7: Run full flutter analyze**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney && flutter analyze
```

Expected: zero errors, zero warnings.

- [ ] **Step 13.8: Run all tests**

```bash
flutter test
```

Expected: all tests pass.

- [ ] **Step 13.9: Commit**

```bash
git add lib/core/navigation/
git commit -m "feat: wire trainer discovery tab + all new routes into AppShell and AppRouter"
```

---

## Post-Integration Checklist

After all tasks are complete, do a manual smoke-test on the dev device:

- [ ] **Auth: trainer flow** — Activate trainer role → automatically push to `/trainer/profile-setup` → fill form + pin location → submit → see pending screen
- [ ] **Admin flow** — Log in as admin → open Admin Panel → "Trainer-Anträge" tab shows submitted trainer → tap "Freigeben" → trainer disappears from list
- [ ] **Discovery flow** — Log in as regular user → tap "Trainer" tab → location permission dialog → map shows trainer pins + list → tap trainer → see public profile → "Anfrage senden" → success message
- [ ] **Trainer request response** — Log in as trainer → tap inbox icon in dashboard → see pending request → "Annehmen" → client now shows as active in trainer clients list
- [ ] **Duplicate request** — Try sending a second request to same trainer → error message shown, no crash

---

## Self-Review Against Spec

Spec sections vs tasks:

| Spec requirement | Task |
|---|---|
| PostGIS, trainer_profiles, trainer_profile_private | Task 2 |
| location_private never exposed to clients | Task 2: find_trainers_nearby returns only location_public |
| location_public computed server-side with jitter | Task 2: _jitter_location + upsert_trainer_location |
| Admin approval workflow | Task 2 (RPCs) + Task 9 (UI) |
| Trainer self-registration | Task 8 |
| Trainer pending screen | Task 8 |
| find_trainers_nearby RPC | Task 2 |
| Discovery tab in AppShell | Task 13 |
| Map + list + radius slider | Task 10 |
| TrainerPublicProfileScreen | Task 11 |
| Send connection request (send_discovery_request) | Task 2 + 11 |
| Trainer accepts/declines | Task 2 + 12 |
| Accept = deactivate old relationship + create chat | Task 2: respond_discovery_request |
| Multiple pending requests allowed | Task 2: unique index only per trainer-client pair |
| Phase-1: one active relationship per client | Task 2: respond_discovery_request deactivates others |
| flutter_map (OpenStreetMap, no API key) | Task 1 + 7 + 10 |
| geolocator for user GPS | Task 1 + 10 |
| Invite-code flow unchanged | Not modified — still works via accept_invite |
| Push notification after approval | Not in Phase 1 (spec deferred: notification is best-effort, push token system exists) |
| contact_email / admin_notes never in find_trainers_nearby | Task 2: verified in RPC return columns |
