# Chat, Video & Premium — Design Spec
**Date:** 2026-04-14  
**Status:** Approved  
**Working directory:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`  
**Supabase project:** `sxvpiggednbftfqeokyd`

---

## Context

CoreJourney ist eine Flutter-App für Fitness-Coaching. Trainer betreuen Klienten in strukturierten Trainingspaketen (MORO, TLR, Spinal Galant). Die Chat-Infrastruktur (Tabellen, RLS, Bot-FAQs) ist vollständig migriert aber noch nicht erreichbar: Community-Channels werden nie provisioniert, die Navigation ist versteckt, und Premium-Features existieren nicht.

### Was bereits existiert (nicht anfassen)
- `chat_channels`, `chat_channel_members`, `chat_messages`, `bot_faqs` — vollständig mit RLS
- `get_or_create_direct_channel()` RPC (SECURITY DEFINER)
- `chat-triage-bot` Edge Function (reagiert auf Keywords, eskaliert zum Trainer)
- `agora-token` Edge Function + `VideoCallScreen`
- `joinCommunityChannel()` in `SupabaseChatRepository` — definiert aber nie aufgerufen
- `AppointmentSchedulerScreen` + `create_appointment_proposal` RPC

---

## Architektur-Entscheidungen

### 1. Subscription Tier statt Boolean
`profiles.subscription_tier TEXT DEFAULT 'free' CHECK (IN ('free', 'premium'))` — exakt das gleiche Muster wie die bestehende `role` Spalte. Erweiterbar auf `trial`, `enterprise` ohne Schema-Migration. Geschützt durch denselben Trigger-Mechanismus wie `role`.

### 2. Community-Channel-Provisioning via DB-Trigger
`joinCommunityChannel()` im Flutter-Code ist totes Code und wird entfernt. Stattdessen: DB-Trigger `trg_enrollment_join_community` auf `enrollments AFTER INSERT`. Atomisch, kein Race-Condition-Risiko, kein Client-Code nötig.

Logik des Triggers:
1. Wenn `NEW.status = 'active'`
2. Erstelle Community-Channel für `NEW.package_id` falls nicht vorhanden (idempotent via `ON CONFLICT DO NOTHING`)
3. Trage `NEW.user_id` als `member` ein
4. Finde aktiven Trainer des Users via `trainer_client_relationships` → trage ihn als `moderator` ein

### 3. N+1 Query Fix via DB-Funktion
`getChannels()` macht heute 2N+2 Roundtrips. Ersatz: `get_channel_list(p_user_id uuid)` als SECURITY DEFINER SQL-Funktion die in einem Query Channels + last_message + unread_count zurückgibt.

---

## Design nach Bereichen

### Bereich 1 — Daten & Backend (Migrationen)

**Migration A: `subscription_tier` auf `profiles`**
```sql
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS
  subscription_tier TEXT NOT NULL DEFAULT 'free'
  CHECK (subscription_tier IN ('free', 'premium'));

-- Trigger analog zu prevent_direct_role_change:
CREATE OR REPLACE FUNCTION prevent_direct_tier_change() ...
  IF auth.role() != 'service_role' AND OLD.subscription_tier IS DISTINCT FROM NEW.subscription_tier THEN
    RAISE EXCEPTION '...';
  END IF;
```

**Migration B: `get_channel_list` DB-Funktion**
```sql
CREATE OR REPLACE FUNCTION get_channel_list(p_user_id uuid)
RETURNS TABLE (
  id uuid, type text, package_id text, created_at timestamptz,
  member_role text, last_read_at timestamptz,
  last_message_content text, last_message_at timestamptz,
  unread_count bigint
)
LANGUAGE sql SECURITY DEFINER AS $$
  WITH memberships AS (
    SELECT ccm.channel_id, ccm.role, ccm.last_read_at
    FROM chat_channel_members ccm
    WHERE ccm.user_id = p_user_id
  ),
  last_msgs AS (
    SELECT DISTINCT ON (channel_id)
      channel_id, content, created_at
    FROM chat_messages
    WHERE deleted_at IS NULL
    ORDER BY channel_id, created_at DESC
  ),
  unread AS (
    SELECT cm.channel_id, COUNT(*) AS cnt
    FROM chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.created_at > m.last_read_at
      AND cm.sender_id != p_user_id
      AND cm.deleted_at IS NULL
    GROUP BY cm.channel_id
  )
  SELECT c.id, c.type, c.package_id, c.created_at,
         m.role, m.last_read_at,
         lm.content, lm.created_at,
         COALESCE(u.cnt, 0)
  FROM chat_channels c
  JOIN memberships m ON m.channel_id = c.id
  LEFT JOIN last_msgs lm ON lm.channel_id = c.id
  LEFT JOIN unread u ON u.channel_id = c.id
  ORDER BY CASE WHEN c.type = 'direct' THEN 0 ELSE 1 END, lm.created_at DESC NULLS LAST;
$$;
```

**Migration C: `trg_enrollment_join_community` Trigger**

Voraussetzung: `chat_channels` benötigt eine UNIQUE-Constraint auf `(type, package_id)` damit `ON CONFLICT DO NOTHING` greift. Diese wird in derselben Migration hinzugefügt.

```sql
-- Unique constraint so community channels are deduplicated per package
ALTER TABLE chat_channels
  ADD CONSTRAINT uq_chat_channels_community_package
  UNIQUE (type, package_id)
  DEFERRABLE INITIALLY DEFERRED;
-- Note: DEFERRABLE so existing direct channels (package_id IS NULL) don't conflict.
-- The CHECK constraint already ensures direct channels have package_id = NULL,
-- so (direct, NULL) won't conflict with (community, <package_id>).

CREATE OR REPLACE FUNCTION fn_enrollment_join_community()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_channel_id uuid;
  v_trainer_id uuid;
BEGIN
  IF NEW.status != 'active' THEN RETURN NEW; END IF;

  -- Idempotent channel creation
  INSERT INTO chat_channels (type, package_id)
  VALUES ('community', NEW.package_id)
  ON CONFLICT ON CONSTRAINT uq_chat_channels_community_package DO NOTHING;

  SELECT id INTO v_channel_id FROM chat_channels
  WHERE type = 'community' AND package_id = NEW.package_id;

  -- Add user as member
  INSERT INTO chat_channel_members (channel_id, user_id, role)
  VALUES (v_channel_id, NEW.user_id, 'member')
  ON CONFLICT DO NOTHING;

  -- Add trainer as moderator
  SELECT trainer_id INTO v_trainer_id
  FROM trainer_client_relationships
  WHERE client_id = NEW.user_id AND status = 'active'
  LIMIT 1;

  IF v_trainer_id IS NOT NULL THEN
    INSERT INTO chat_channel_members (channel_id, user_id, role)
    VALUES (v_channel_id, v_trainer_id, 'moderator')
    ON CONFLICT (channel_id, user_id) DO UPDATE SET role = 'moderator';
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_enrollment_join_community
  AFTER INSERT ON enrollments
  FOR EACH ROW EXECUTE FUNCTION fn_enrollment_join_community();
```

**Edge Function: `set-subscription-tier`** (service-role only, admin-only)
- Input: `{ user_id, tier }` — setzt `subscription_tier` via service_role client
- Geschützt durch Admin-Check analog zu `create-trainer-code`
- "Verify JWT" deaktiviert, Auth-Check intern

---

### Bereich 2 — Navigation

**Bottom Navigation (4 Tabs):**
| Tab | Icon | Route |
|-----|------|-------|
| Home | `home_outlined` | `/dashboard` |
| Training | `fitness_center_outlined` | (bestehend) |
| Nachrichten | `chat_bubble_outline` | `/chat` |
| Profil | `person_outline` | `/profile` |

- Unread-Badge auf dem Chat-Tab (roter Punkt wenn `totalUnread > 0`)
- Bestehender Chat-Icon im Dashboard-Header wird entfernt

**GoRouter ShellRoute:**
Die Bottom Navigation muss über alle 4 Top-Level-Screens persistieren. Das erfordert einen `ShellRoute` in `app_router.dart` (GoRouter-Standard für persistente Bottom Nav). Der `ShellRoute` wraps Dashboard, Training, Chat, Profil. Ein neues Widget `AppShell` rendert die `NavigationBar` und zeigt das `child` des ShellRoute darüber.

```dart
ShellRoute(
  builder: (context, state, child) => AppShell(child: child),
  routes: [
    GoRoute(path: '/dashboard', ...),
    GoRoute(path: '/chat', ...),
    GoRoute(path: '/profile', ...),
    // Training-Route (bestehend, muss in Shell)
  ],
)
```

Detail-Screens (ChatChannelScreen, VideoCallScreen etc.) liegen AUSSERHALB der Shell — sie navigieren mit `context.push()` und haben keine Bottom Nav.

**Chat-Inbox-Struktur:**
```
Nachrichten
├── MEIN TRAINER
│   └── [Trainer-Name] · letzte Nachricht · Zeit · Unread-Badge
└── MEINE PAKETE
    ├── MORO Community · letzte Nachricht · Zeit
    └── TLR Community · letzte Nachricht · Zeit
```

---

### Bereich 3 — Nach dem Training (Post-Session Share)

Nach Abschluss einer Trainingseinheit existiert bereits ein Journal-Prompt. Darunter wird ein neuer sekundärer Button ergänzt:

```
[ Tagebucheintrag schreiben ]   ← bestehend
[ Mit Community teilen      ]   ← neu (sekundär, OutlinedButton)
```

"Mit Community teilen" → navigiert direkt in den Community-Channel des aktuellen Pakets (`/chat/:channelId`). Channel-ID wird via `get_channel_list` bereits im Riverpod-State gecacht — kein extra Query nötig.

Wenn kein Community-Channel existiert (User hat noch keinen Trainer): Button wird nicht angezeigt.

---

### Bereich 4 — Direkter Trainer-Chat (Aktionen)

**AppBar-Aktionen im `ChatChannelScreen` für Direct Channels:**

Für Klient (Premium):
- Kamera-Icon (`videocam_outlined`) → öffnet Video-Call-Flow
- Tippt Free-User drauf → `BottomSheet` mit Erklärung + "Premium freischalten" (vorerst Platzhalter-CTA, noch kein Payment)

Für Klient (Free):
- Kamera-Icon mit `lock` Overlay → öffnet Erklärungssheet

Für Trainer:
- Kalender-Icon (`event_outlined`) → öffnet `AppointmentSchedulerScreen` mit `clientId` des Chat-Partners

**Bot-Verhalten:** unverändert — `chat-triage-bot` wird weiterhin nach jeder Nachricht aufgerufen, reagiert unsichtbar.

---

### Bereich 5 — Video-Call-Flow (Premium)

Bestehend: `VideoCallScreen` + `agora-token` Edge Function (Testing Mode, leeres Token).

Neu:
1. Premium-Klient tippt Kamera-Icon im Trainer-Chat
2. `sendCallRequest()` schreibt `is_call_request: true` Message in den Channel → Trainer sieht die Anfrage als spezielle MessageBubble mit "Annehmen" / "Termin vorschlagen" Buttons
3. "Annehmen" → `VideoCallScreen` öffnet sich bei beiden
4. "Termin vorschlagen" → `AppointmentSchedulerScreen`

**`MessageBubble` für Call-Requests:**
- Statt normalem Text-Bubble: spezielles Card-Widget mit Kamera-Icon, Text "Video-Call angefragt", und (für Trainer) zwei Action-Buttons

---

## Dateien die geändert werden

### Neue Migrationen
- `supabase/migrations/20260415_subscription_tier.sql`
- `supabase/migrations/20260415_get_channel_list.sql`
- `supabase/migrations/20260415_enrollment_community_trigger.sql`

### Neue Edge Function
- `supabase/functions/set-subscription-tier/index.ts`

### Flutter — geändert
- `lib/core/navigation/app_router.dart` — `ShellRoute` für 4 Top-Level-Screens, bestehende Top-Level-Routes in Shell verschieben
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — Chat-Icon aus AppBar entfernen
- `lib/features/chat/data/repositories/supabase_chat_repository.dart` — `getChannels()` auf `get_channel_list` RPC umstellen, `joinCommunityChannel()` entfernen
- `lib/features/chat/presentation/screens/chat_inbox_screen.dart` — Sektionen "Mein Trainer" / "Meine Pakete"
- `lib/features/chat/presentation/screens/chat_channel_screen.dart` — AppBar-Aktionen (Video, Termin), Call-Request-MessageBubble
- `lib/features/chat/presentation/widgets/message_bubble.dart` — `is_call_request` Variante mit Action-Buttons
- `lib/features/training/presentation/screens/training_session_screen.dart` — Post-Session "Mit Community teilen" Button
- `lib/features/trainer/presentation/providers/trainer_provider.dart` — `userRoleProvider` um `subscription_tier` erweitern oder eigener `subscriptionTierProvider`

### Flutter — neu
- `lib/features/chat/presentation/providers/unread_count_provider.dart` — aggregierter unread count für Badge
- `lib/core/navigation/app_shell.dart` — `AppShell` Widget mit `NavigationBar` (4 Tabs, Unread-Badge auf Chat-Tab)

### Admin Panel
- `lib/features/admin/presentation/screens/admin_panel_screen.dart` — Sektion "Premium verwalten": User-Liste + Toggle per User
- `lib/features/admin/presentation/providers/admin_provider.dart` — `setSubscriptionTier()` via `set-subscription-tier` Edge Function

---

## Was explizit NICHT gebaut wird (YAGNI)

- Kein Payment-Flow (Stripe etc.) — vorerst manuell via Admin Panel
- Kein globaler Chat
- Kein eigener Bot-Kanal
- Kein Push-Notification-System (bereits als "deferred" markiert)
- Kein Message-Editing (nur Soft-Delete)
- Keine Gruppen-Videocalls (nur 1:1 Trainer ↔ Klient)
- Kein Subscription-Ablaufdatum (kein `valid_until` — manuell verwaltet)

---

## Reihenfolge der Implementierung

1. **DB-Migrationen** (A, B, C) — müssen zuerst im Supabase Dashboard laufen
2. **Edge Function `set-subscription-tier`** deployen
3. **`SupabaseChatRepository.getChannels()`** auf `get_channel_list` umstellen
4. **Bottom Navigation** — Chat-Tab + Unread-Badge
5. **Chat-Inbox** — Sektionen
6. **Direct Chat Aktionen** — Video-Button (Premium-Gate) + Termin-Button (Trainer)
7. **MessageBubble Call-Request Variante**
8. **Post-Session Share-Button**
9. **Admin Panel Premium-Verwaltung**
10. **Manuelle Migrations ausführen** + E2E-Test
