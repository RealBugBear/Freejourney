# Chat, Video & Premium — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Provision package community channels via DB trigger, add bottom-nav shell with chat tab, gate video calls behind a `subscription_tier` premium flag, add trainer actions (accept/propose) to call-request bubbles, and add a post-training community share prompt.

**Architecture:** DB triggers handle community channel provisioning atomically on enrollment. A `get_channel_list()` SQL function eliminates the existing N+1 query. GoRouter `ShellRoute` wraps the four persistent screens with a `NavigationBar`. Premium is a `subscription_tier` text column on `profiles`, managed by an admin-only Edge Function.

**Tech Stack:** Flutter 3.x, Riverpod, go_router, Supabase (PostgreSQL triggers + RLS + Edge Functions Deno), Agora (video, testing mode)

**Working directory:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`
**Supabase project:** `sxvpiggednbftfqeokyd`  
**Run app:** `make run` (DEV device) · `make run-sim` (simulator)  
**Analyze:** `flutter analyze lib/ 2>&1 | grep "error •"`

---

## File Map

| File | Action | Responsibility |
|------|--------|----------------|
| `supabase/migrations/20260415_subscription_tier.sql` | Create | `subscription_tier` column, protect trigger, admin RLS policy |
| `supabase/migrations/20260415_get_channel_list.sql` | Create | `get_channel_list()` DB function — replaces N+1 |
| `supabase/migrations/20260415_enrollment_community_trigger.sql` | Create | UNIQUE constraint + `trg_enrollment_join_community` |
| `supabase/migrations/20260415_backfill_community_channels.sql` | Create | One-time backfill for existing enrollments |
| `supabase/functions/set-subscription-tier/index.ts` | Create | Admin-only Edge Function to set user's tier |
| `lib/core/navigation/app_shell.dart` | Create | `AppShell` widget — `NavigationBar` with 4 tabs + unread badge |
| `lib/core/navigation/app_router.dart` | Modify | Add `ShellRoute` wrapping dashboard/packages/chat/profile |
| `lib/features/chat/domain/repositories/chat_repository.dart` | Modify | Remove `joinCommunityChannel` from interface |
| `lib/features/chat/data/repositories/supabase_chat_repository.dart` | Modify | `getChannels()` → `get_channel_list` RPC; remove `joinCommunityChannel` |
| `lib/features/trainer/presentation/providers/trainer_provider.dart` | Modify | Add `subscriptionTierProvider` + `chatPartnerIdProvider` |
| `lib/features/chat/presentation/screens/chat_channel_screen.dart` | Modify | Premium video button for practitioner; trainer appointment button |
| `lib/features/chat/presentation/widgets/message_bubble.dart` | Modify | `_CallRequestBubble` → trainer accept/propose buttons |
| `lib/features/training/presentation/screens/training_session_screen.dart` | Modify | Post-training community share prompt |
| `lib/features/admin/presentation/providers/admin_provider.dart` | Modify | Add `AdminUser` model + `setSubscriptionTier()` + users list |
| `lib/features/admin/presentation/screens/admin_panel_screen.dart` | Modify | Add "Premium verwalten" section |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Modify | Remove chat icon from AppBar |
| `lib/features/chat/presentation/screens/chat_inbox_screen.dart` | Modify | Sections "Mein Trainer" / "Meine Pakete"; fix empty state text |

---

## Task 1: DB Migration A — subscription_tier on profiles

Run this SQL in the Supabase Dashboard SQL editor for project `sxvpiggednbftfqeokyd`.

**Files:**
- Create: `supabase/migrations/20260415_subscription_tier.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260415_subscription_tier.sql
-- Adds subscription_tier to profiles, protects it from direct client writes,
-- and grants admin users read access to all profiles.

-- 1. Add column
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_tier TEXT NOT NULL DEFAULT 'free'
  CONSTRAINT profiles_subscription_tier_check CHECK (subscription_tier IN ('free', 'premium'));

-- 2. Trigger to prevent authenticated users from changing subscription_tier directly
--    (mirrors the existing prevent_direct_role_change pattern)
CREATE OR REPLACE FUNCTION public.prevent_direct_tier_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() != 'service_role' AND OLD.subscription_tier IS DISTINCT FROM NEW.subscription_tier THEN
    RAISE EXCEPTION
      'Changing subscription_tier directly is not permitted. '
      'Use the set-subscription-tier Edge Function.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_direct_tier_change ON public.profiles;
CREATE TRIGGER trg_prevent_direct_tier_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_tier_change();

-- 3. Allow admin users to read all profiles
--    (needed for admin panel user list; existing policy only allows reading own row)
DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'profiles' AND policyname = 'profiles_admin_read_all'
  ) THEN
    CREATE POLICY profiles_admin_read_all ON public.profiles
      FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM public.profiles p
          WHERE p.id = auth.uid() AND p.role = 'admin'
        )
      );
  END IF;
END $$;
```

- [ ] **Step 2: Run in Supabase Dashboard**

Open: `https://supabase.com/dashboard/project/sxvpiggednbftfqeokyd/sql/new`

Paste the SQL and click **Run**.

Expected output: `Success. No rows returned.`

- [ ] **Step 3: Verify**

Run this verification query:
```sql
SELECT id, display_name, role, subscription_tier
FROM profiles
LIMIT 5;
```
Expected: column `subscription_tier` present, all rows show `free`.

- [ ] **Step 4: Commit the migration file**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add supabase/migrations/20260415_subscription_tier.sql
git commit -m "feat(db): add subscription_tier to profiles with trigger protection"
```

---

## Task 2: DB Migration B — get_channel_list() function

Replaces the N+1 query in `SupabaseChatRepository.getChannels()`.

**Files:**
- Create: `supabase/migrations/20260415_get_channel_list.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260415_get_channel_list.sql
-- Single-query replacement for the N+1 channel list query.
-- Returns channels the calling user is a member of, with last message
-- and unread count, sorted: direct first, then community; newest-last-message first.

CREATE OR REPLACE FUNCTION public.get_channel_list(p_user_id uuid)
RETURNS TABLE (
  id                    uuid,
  type                  text,
  package_id            text,
  created_at            timestamptz,
  member_role           text,
  last_read_at          timestamptz,
  last_message_content  text,
  last_message_at       timestamptz,
  unread_count          bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH memberships AS (
    SELECT
      ccm.channel_id,
      ccm.role          AS member_role,
      ccm.last_read_at
    FROM chat_channel_members ccm
    WHERE ccm.user_id = p_user_id
  ),
  last_msgs AS (
    SELECT DISTINCT ON (cm.channel_id)
      cm.channel_id,
      cm.content      AS last_message_content,
      cm.created_at   AS last_message_at
    FROM chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.deleted_at IS NULL
    ORDER BY cm.channel_id, cm.created_at DESC
  ),
  unread AS (
    SELECT
      cm.channel_id,
      COUNT(*)::bigint AS unread_count
    FROM chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.created_at > m.last_read_at
      AND cm.sender_id  != p_user_id
      AND cm.deleted_at IS NULL
    GROUP BY cm.channel_id
  )
  SELECT
    c.id,
    c.type,
    c.package_id,
    c.created_at,
    m.member_role,
    m.last_read_at,
    lm.last_message_content,
    lm.last_message_at,
    COALESCE(u.unread_count, 0) AS unread_count
  FROM chat_channels c
  JOIN memberships m   ON m.channel_id = c.id
  LEFT JOIN last_msgs lm ON lm.channel_id = c.id
  LEFT JOIN unread u     ON u.channel_id  = c.id
  ORDER BY
    CASE WHEN c.type = 'direct' THEN 0 ELSE 1 END,
    lm.last_message_at DESC NULLS LAST;
$$;
```

- [ ] **Step 2: Run in Supabase Dashboard**

Open: `https://supabase.com/dashboard/project/sxvpiggednbftfqeokyd/sql/new`

Paste and run. Expected: `Success. No rows returned.`

- [ ] **Step 3: Verify**

```sql
SELECT * FROM get_channel_list('<your-test-user-uuid>');
```
Replace with a real UUID from `auth.users`. Expected: rows matching the user's channels, or empty if they have none.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260415_get_channel_list.sql
git commit -m "feat(db): add get_channel_list() function to replace N+1 channel query"
```

---

## Task 3: DB Migration C — unique constraint + enrollment→community trigger

**Files:**
- Create: `supabase/migrations/20260415_enrollment_community_trigger.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260415_enrollment_community_trigger.sql
-- 1. Unique constraint so ON CONFLICT works for community channels.
-- 2. Trigger: when a user enrolls in a package, auto-create/join the community channel.

-- 1. Unique constraint on community channels (direct channels are excluded via CHECK constraint
--    which ensures package_id IS NULL for direct, so (direct, NULL) never conflicts with
--    (community, <id>))
ALTER TABLE public.chat_channels
  ADD CONSTRAINT uq_chat_channels_community_package
  UNIQUE (type, package_id);

-- 2. Trigger function
CREATE OR REPLACE FUNCTION public.fn_enrollment_join_community()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel_id  uuid;
  v_trainer_id  uuid;
BEGIN
  -- Only act on active enrollments
  IF NEW.status != 'active' THEN
    RETURN NEW;
  END IF;

  -- Create community channel if it doesn't exist yet (idempotent)
  INSERT INTO public.chat_channels (type, package_id)
  VALUES ('community', NEW.package_id)
  ON CONFLICT ON CONSTRAINT uq_chat_channels_community_package DO NOTHING;

  SELECT id INTO v_channel_id
  FROM public.chat_channels
  WHERE type = 'community' AND package_id = NEW.package_id;

  -- Add enrolling user as member
  INSERT INTO public.chat_channel_members (channel_id, user_id, role)
  VALUES (v_channel_id, NEW.user_id, 'member')
  ON CONFLICT (channel_id, user_id) DO NOTHING;

  -- Find the user's active trainer and add as moderator
  SELECT trainer_id INTO v_trainer_id
  FROM public.trainer_client_relationships
  WHERE client_id = NEW.user_id AND status = 'active'
  LIMIT 1;

  IF v_trainer_id IS NOT NULL THEN
    INSERT INTO public.chat_channel_members (channel_id, user_id, role)
    VALUES (v_channel_id, v_trainer_id, 'moderator')
    ON CONFLICT (channel_id, user_id) DO UPDATE SET role = 'moderator';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enrollment_join_community ON public.enrollments;
CREATE TRIGGER trg_enrollment_join_community
  AFTER INSERT ON public.enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_enrollment_join_community();
```

- [ ] **Step 2: Run in Supabase Dashboard**

Paste and run. Expected: `Success. No rows returned.`

- [ ] **Step 3: Verify trigger exists**

```sql
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_table = 'enrollments';
```
Expected: row with `trg_enrollment_join_community`, `INSERT`, `AFTER`.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260415_enrollment_community_trigger.sql
git commit -m "feat(db): auto-provision community channel on enrollment via trigger"
```

---

## Task 4: Backfill existing enrollments

Users already enrolled won't be affected by the trigger (only fires on INSERT). This one-time script backfills them.

**Files:**
- Create: `supabase/migrations/20260415_backfill_community_channels.sql`

- [ ] **Step 1: Write the backfill script**

```sql
-- supabase/migrations/20260415_backfill_community_channels.sql
-- One-time backfill: provision community channels for all existing active enrollments.
-- Safe to re-run (all operations are idempotent via ON CONFLICT).

DO $$
DECLARE
  rec         RECORD;
  v_channel_id uuid;
  v_trainer_id uuid;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, package_id
    FROM public.enrollments
    WHERE status = 'active'
  LOOP
    -- Ensure community channel exists
    INSERT INTO public.chat_channels (type, package_id)
    VALUES ('community', rec.package_id)
    ON CONFLICT ON CONSTRAINT uq_chat_channels_community_package DO NOTHING;

    SELECT id INTO v_channel_id
    FROM public.chat_channels
    WHERE type = 'community' AND package_id = rec.package_id;

    -- Add user
    INSERT INTO public.chat_channel_members (channel_id, user_id, role)
    VALUES (v_channel_id, rec.user_id, 'member')
    ON CONFLICT (channel_id, user_id) DO NOTHING;

    -- Add trainer
    SELECT trainer_id INTO v_trainer_id
    FROM public.trainer_client_relationships
    WHERE client_id = rec.user_id AND status = 'active'
    LIMIT 1;

    IF v_trainer_id IS NOT NULL THEN
      INSERT INTO public.chat_channel_members (channel_id, user_id, role)
      VALUES (v_channel_id, v_trainer_id, 'moderator')
      ON CONFLICT (channel_id, user_id) DO UPDATE SET role = 'moderator';
    END IF;
  END LOOP;
END;
$$;
```

- [ ] **Step 2: Run in Supabase Dashboard**

Paste and run. Expected: `DO` (PL/pgSQL block completed).

- [ ] **Step 3: Verify**

```sql
SELECT c.package_id, COUNT(ccm.user_id) AS member_count
FROM chat_channels c
JOIN chat_channel_members ccm ON ccm.channel_id = c.id
WHERE c.type = 'community'
GROUP BY c.package_id;
```
Expected: one row per package that has active enrollments.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260415_backfill_community_channels.sql
git commit -m "feat(db): backfill community channel membership for existing enrollments"
```

---

## Task 5: Edge Function — set-subscription-tier

Admin-only function that sets a user's `subscription_tier` via service_role.

**Files:**
- Create: `supabase/functions/set-subscription-tier/index.ts`

- [ ] **Step 1: Write the Edge Function**

```typescript
// supabase/functions/set-subscription-tier/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    // Verify caller's identity
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // Admin-only
    const { data: profile } = await serviceClient
      .from('profiles').select('role').eq('id', user.id).single()
    if (profile?.role !== 'admin') {
      return new Response(JSON.stringify({ error: 'Forbidden' }), {
        status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const body = await req.json() as { user_id?: string; tier?: string }
    const { user_id, tier } = body

    if (!user_id || !tier) {
      return new Response(JSON.stringify({ error: 'user_id and tier are required' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }
    if (!['free', 'premium'].includes(tier)) {
      return new Response(JSON.stringify({ error: 'tier must be "free" or "premium"' }), {
        status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    const { error: updateError } = await serviceClient
      .from('profiles')
      .update({ subscription_tier: tier })
      .eq('id', user_id)
    if (updateError) {
      return new Response(JSON.stringify({ error: updateError.message }), {
        status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({ success: true, user_id, tier }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    )
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
```

- [ ] **Step 2: Deploy the Edge Function**

In the Supabase Dashboard:
1. Go to `https://supabase.com/dashboard/project/sxvpiggednbftfqeokyd/functions`
2. Click **"Create a new function"** → name it `set-subscription-tier`
3. Paste the code above → Save
4. Go to **Settings** tab → **disable "Verify JWT"** (same as create-trainer-code)

- [ ] **Step 3: Commit**

```bash
git add supabase/functions/set-subscription-tier/index.ts
git commit -m "feat(functions): add set-subscription-tier admin edge function"
```

---

## Task 6: ChatRepository — getChannels() refactor

Replaces the N+1 loop with a single `get_channel_list` RPC call. Removes dead `joinCommunityChannel` code.

**Files:**
- Modify: `lib/features/chat/domain/repositories/chat_repository.dart`
- Modify: `lib/features/chat/data/repositories/supabase_chat_repository.dart`

- [ ] **Step 1: Remove `joinCommunityChannel` from interface**

In `lib/features/chat/domain/repositories/chat_repository.dart`, remove line 11:

```dart
// Remove this line:
  Future<void> joinCommunityChannel(String packageId);
```

The file after removal:
```dart
import '../models/chat_channel.dart';
import '../models/chat_message.dart';

abstract class ChatRepository {
  // ── Channels ──────────────────────────────────────────────────────────────

  Future<List<ChatChannel>> getChannels();

  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId);

  Future<void> markChannelRead(String channelId);

  // ── Messages ──────────────────────────────────────────────────────────────

  /// Real-time stream of the most recent [pageSize] messages.
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize = 30});

  /// Load messages older than [before] for infinite scroll.
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  });

  Future<void> sendMessage(String channelId, String content);

  /// Sends a call-request message. Only Practitioners call this.
  Future<void> sendCallRequest(String channelId);

  Future<void> deleteMessage(String messageId);

  // ── Typing indicator ──────────────────────────────────────────────────────

  Future<void> broadcastTyping(String channelId);

  Stream<Set<String>> watchTypingUsers(String channelId);
}
```

- [ ] **Step 2: Rewrite `getChannels()` in the repository; remove `joinCommunityChannel`**

Replace the `getChannels()` method and remove `joinCommunityChannel()` in `lib/features/chat/data/repositories/supabase_chat_repository.dart`.

Replace everything from `// ── Channels ──` through the end of `joinCommunityChannel` with:

```dart
  // ── Channels ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatChannel>> getChannels() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client.rpc(
      'get_channel_list',
      params: {'p_user_id': userId},
    ) as List;

    return rows.map((row) {
      final m = row as Map<String, dynamic>;
      final roleStr = m['member_role'] as String? ?? 'member';
      final role = roleStr == 'moderator' ? MemberRole.moderator : MemberRole.member;

      final lastMsgContent = m['last_message_content'] as String?;
      final lastMsgAtStr = m['last_message_at'] as String?;
      final lastMessageAt =
          lastMsgAtStr != null ? DateTime.parse(lastMsgAtStr) : null;
      final unreadCount = (m['unread_count'] as num?)?.toInt() ?? 0;

      return ChatChannel.fromJson(
        m,
        currentUserRole: role,
        lastMessageContent: lastMsgContent,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
    }).toList();
  }
```

Also remove the entire `joinCommunityChannel` method (lines 115–147 in the original file).

- [ ] **Step 3: Verify no compile errors**

```bash
flutter analyze lib/features/chat/ 2>&1 | grep "error •"
```
Expected: no output (no errors).

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/domain/repositories/chat_repository.dart \
        lib/features/chat/data/repositories/supabase_chat_repository.dart
git commit -m "refactor(chat): replace N+1 getChannels() with get_channel_list RPC; remove dead joinCommunityChannel"
```

---

## Task 7: subscriptionTierProvider + chatPartnerIdProvider

Two new providers needed by the chat UI.

**Files:**
- Modify: `lib/features/trainer/presentation/providers/trainer_provider.dart`

- [ ] **Step 1: Add `subscriptionTierProvider` and `chatPartnerIdProvider`**

Append to the end of `lib/features/trainer/presentation/providers/trainer_provider.dart`:

```dart
// ── Subscription tier ─────────────────────────────────────────────────────────

/// Returns 'free' or 'premium' for the currently signed-in user.
/// Re-runs on auth state change (same pattern as userRoleProvider).
final subscriptionTierProvider = FutureProvider<String>((ref) async {
  ref.watch(authStateProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return 'free';
  final res = await Supabase.instance.client
      .from('profiles')
      .select('subscription_tier')
      .eq('id', userId)
      .single();
  return res['subscription_tier'] as String? ?? 'free';
});

// ── Chat partner ──────────────────────────────────────────────────────────────

/// For a direct channel, returns the OTHER participant's user_id.
/// Returns null for community channels or if not found.
final chatPartnerIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, channelId) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final rows = await Supabase.instance.client
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', channelId)
      .neq('user_id', userId);

  final list = rows as List;
  if (list.isEmpty) return null;
  return list.first['user_id'] as String?;
});
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/trainer/presentation/providers/trainer_provider.dart 2>&1 | grep "error •"
```
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add lib/features/trainer/presentation/providers/trainer_provider.dart
git commit -m "feat(providers): add subscriptionTierProvider and chatPartnerIdProvider"
```

---

## Task 8: AppShell + ShellRoute (bottom navigation)

Creates a persistent 4-tab bottom navigation using GoRouter's `ShellRoute`.

**Files:**
- Create: `lib/core/navigation/app_shell.dart`
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: Create `AppShell` widget**

Create `lib/core/navigation/app_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/providers/chat_providers.dart';
import 'app_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    Routes.dashboard,
    Routes.packages,
    Routes.chatInbox,
    Routes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);
    final unread = ref.watch(totalUnreadCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(_tabs[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Training',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: unread > 99
                  ? const Text('99+')
                  : Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: unread > 99
                  ? const Text('99+')
                  : Text('$unread'),
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Nachrichten',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Add `ShellRoute` to `app_router.dart`**

In `lib/core/navigation/app_router.dart`:

1. Add import at the top:
```dart
import 'app_shell.dart';
import '../../features/packages/presentation/screens/packages_screen.dart';
```

2. Add `packages` route constant to the `Routes` class:
```dart
  static const packages = '/packages';
```

3. Replace the flat `routes: [...]` list inside `GoRouter(...)` with a `ShellRoute` wrapping the 4 top-level screens. The full updated routes list:

```dart
    routes: [
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.consent,
        name: 'consent',
        builder: (context, state) => const ConsentScreen(),
      ),
      // ── Shell: persists bottom navigation bar ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            name: 'dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.packages,
            name: 'packages',
            builder: (context, state) => const PackagesScreen(),
          ),
          GoRoute(
            path: Routes.chatInbox,
            name: 'chat-inbox',
            builder: (context, state) => const ChatInboxScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // ── Detail screens: no bottom nav ────────────────────────────────────
      GoRoute(
        path: Routes.intakeAssessment,
        name: 'intake-assessment',
        builder: (context, state) => const IntakeAssessmentScreen(),
      ),
      GoRoute(
        path: Routes.durationRecommendation,
        name: 'duration-recommendation',
        builder: (context, state) => const DurationRecommendationScreen(),
      ),
      GoRoute(
        path: Routes.completionQuestionnaire,
        name: 'completion-questionnaire',
        builder: (context, state) {
          final enrollmentId = state.extra as String? ?? '';
          return CompletionQuestionnaireScreen(enrollmentId: enrollmentId);
        },
      ),
      GoRoute(
        path: Routes.trainingSession,
        name: 'training-session',
        builder: (context, state) {
          final packageId = state.extra as String? ?? 'moro';
          return TrainingSessionScreen(packageId: packageId);
        },
      ),
      GoRoute(
        path: Routes.moodHistory,
        name: 'mood-history',
        builder: (context, state) => const MoodHistoryScreen(),
      ),
      GoRoute(
        path: Routes.journal,
        name: 'journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.trainerClients,
        name: 'trainer-clients',
        builder: (context, state) => const TrainerClientsScreen(),
      ),
      GoRoute(
        path: Routes.trainerClientDetail,
        name: 'trainer-client-detail',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          return TrainerClientDetailScreen(clientId: clientId);
        },
      ),
      GoRoute(
        path: Routes.trainerDashboard,
        name: 'trainer-dashboard',
        builder: (context, state) => const TrainerDashboardScreen(),
      ),
      GoRoute(
        path: Routes.appointmentScheduler,
        name: 'appointment-scheduler',
        builder: (context, state) {
          final clientId = state.pathParameters['clientId']!;
          final client = state.extra as TrainerClient?;
          return AppointmentSchedulerScreen(
            client: client ??
                TrainerClient(
                  relationshipId: '',
                  clientId: clientId,
                  displayName: 'Trainee',
                  currentDay: 1,
                  dailyStreak: 0,
                ),
          );
        },
      ),
      GoRoute(
        path: Routes.appointmentProposals,
        name: 'appointment-proposals',
        builder: (context, state) => const AppointmentProposalScreen(),
      ),
      GoRoute(
        path: Routes.chatChannel,
        name: 'chat-channel',
        builder: (context, state) {
          final channelId = state.pathParameters['channelId']!;
          final channel = state.extra as ChatChannel?;
          return ChatChannelScreen(channelId: channelId, channel: channel);
        },
      ),
      GoRoute(
        path: Routes.devTools,
        name: 'dev-tools',
        builder: (context, state) => const DevToolsScreen(),
      ),
      GoRoute(
        path: Routes.adminPanel,
        name: 'admin-panel',
        builder: (context, state) => const AdminPanelScreen(),
      ),
    ],
```

Note: The `redirect` function in `GoRouter` redirects to `Routes.dashboard` after login — this stays unchanged.

- [ ] **Step 3: Remove chat icon from DashboardScreen AppBar**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, find and remove the chat IconButton in the AppBar actions (around line 129). Also remove the import of `chat_providers.dart` if it's no longer used for anything else.

Find the AppBar actions block and remove:
```dart
// Remove these lines from AppBar actions:
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline),
                    onPressed: () => context.push(Routes.chatInbox),
                  ),
```

Also remove the unused import if present:
```dart
// Remove if no longer referenced:
import '../../../chat/presentation/providers/chat_providers.dart';
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/core/navigation/ lib/features/dashboard/ 2>&1 | grep "error •"
```
Expected: no output.

- [ ] **Step 5: Run and verify bottom nav appears**

```bash
make run-sim
```

Verify:
- Bottom nav shows 4 tabs: Home, Training, Nachrichten, Profil
- Tapping each tab navigates correctly
- Dashboard no longer has chat icon in AppBar

- [ ] **Step 6: Commit**

```bash
git add lib/core/navigation/app_shell.dart \
        lib/core/navigation/app_router.dart \
        lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat(nav): add ShellRoute with 4-tab bottom navigation and chat unread badge"
```

---

## Task 9: Chat inbox — sections + empty state fix

**Files:**
- Modify: `lib/features/chat/presentation/screens/chat_inbox_screen.dart`

- [ ] **Step 1: Replace inbox body**

In `lib/features/chat/presentation/screens/chat_inbox_screen.dart`, replace the entire `data: (channels)` block (lines 31–49) with:

```dart
        data: (channels) {
          if (channels.isEmpty) return const _EmptyState();

          final direct = channels.where((c) => c.type == ChannelType.direct).toList();
          final community = channels.where((c) => c.type == ChannelType.community).toList();

          return ListView(
            children: [
              if (direct.isNotEmpty) ...[
                const _SectionHeader(title: 'MEIN TRAINER'),
                ...direct.map((c) => _ChannelListTile(channel: c, onTap: () => _open(context, c))),
              ],
              if (community.isNotEmpty) ...[
                const _SectionHeader(title: 'MEINE PAKETE'),
                ...community.map((c) => _ChannelListTile(channel: c, onTap: () => _open(context, c))),
              ],
            ],
          );
        },
```

- [ ] **Step 2: Fix the empty state text**

Replace `_EmptyState.build` content text:
```dart
// Replace:
            'Verlinke dich mit einem Trainer, um direkte Nachrichten zu nutzen.\n'
            'Community-Channels erscheinen wenn du einem Block beitrittst.',
// With:
            'Hier erscheinen deine Chats.\n'
            'Absolviere dein erstes Training, um dem Community-Chat beizutreten.',
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/chat/presentation/screens/chat_inbox_screen.dart 2>&1 | grep "error •"
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/chat/presentation/screens/chat_inbox_screen.dart
git commit -m "feat(chat): inbox sections 'Mein Trainer' / 'Meine Pakete'; fix empty state text"
```

---

## Task 10: Direct chat — practitioner video button + trainer appointment button

**Files:**
- Modify: `lib/features/chat/presentation/screens/chat_channel_screen.dart`

- [ ] **Step 1: Add imports**

At the top of `chat_channel_screen.dart`, add:
```dart
import '../../../trainer/presentation/providers/trainer_provider.dart';
```
(Already imports `go_router` via context.push usage — if not, add `import 'package:go_router/go_router.dart';`)

Also add:
```dart
import '../../../../core/navigation/app_router.dart';
import '../../../trainer/domain/models/trainer_client.dart';
```

- [ ] **Step 2: Replace the AppBar actions block**

Find the current AppBar actions block (lines ~199–210):
```dart
        actions: [
          // Trainer: start call directly. (Video feature — Task 2 of Plan 2)
          if (isModerator && channel?.type == ChannelType.direct)
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Call starten',
              onPressed: _startCall,
            ),
        ],
```

Replace with:
```dart
        actions: [
          // Trainer: start call + propose appointment
          if (isModerator && channel?.type == ChannelType.direct) ...[
            IconButton(
              icon: const Icon(Icons.event_outlined),
              tooltip: 'Termin vorschlagen',
              onPressed: () => _proposeAppointment(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Call starten',
              onPressed: _startCall,
            ),
          ],
          // Practitioner (client): request video call (premium gate)
          if (isPractitioner)
            Consumer(builder: (context, ref, _) {
              final tier = ref.watch(subscriptionTierProvider).valueOrNull ?? 'free';
              final isPremium = tier == 'premium';
              return IconButton(
                icon: Icon(
                  isPremium ? Icons.videocam_outlined : Icons.videocam_off_outlined,
                ),
                tooltip: isPremium ? 'Video-Call anfragen' : 'Premium-Feature',
                onPressed: isPremium ? _sendCallRequest : () => _showPremiumSheet(context),
              );
            }),
        ],
```

- [ ] **Step 3: Add `_proposeAppointment` and `_showPremiumSheet` methods**

Add these methods to `_ChatChannelScreenState` (before or after `_sendCallRequest`):

```dart
  Future<void> _proposeAppointment(BuildContext context, WidgetRef ref) async {
    final partnerIdAsync = ref.read(chatPartnerIdProvider(widget.channelId));
    final clientId = await partnerIdAsync.when(
      data: (id) async => id,
      loading: () async => null,
      error: (_, __) async => null,
    );
    if (clientId == null || !mounted) return;
    context.push(
      Routes.appointmentScheduler.replaceFirst(':clientId', clientId),
    );
  }

  void _showPremiumSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_outlined, size: 48),
            const SizedBox(height: 16),
            Text(
              'Video-Calls sind ein Premium-Feature',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Mit einem Premium-Abo kannst du deinen Trainer direkt per Video-Call erreichen.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Verstanden'),
            ),
          ],
        ),
      ),
    );
  }
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/chat/presentation/screens/chat_channel_screen.dart 2>&1 | grep "error •"
```

- [ ] **Step 5: Test on device**

```bash
make run-sim
```

Open a direct channel as a practitioner account → verify videocam-off icon appears.  
Open as trainer → verify calendar icon + videocam icon appear.

- [ ] **Step 6: Commit**

```bash
git add lib/features/chat/presentation/screens/chat_channel_screen.dart
git commit -m "feat(chat): add premium video button for practitioners; trainer appointment shortcut"
```

---

## Task 11: _CallRequestBubble — trainer accept/propose buttons

When a practitioner sends a call request, the trainer sees actionable buttons.

**Files:**
- Modify: `lib/features/chat/presentation/widgets/message_bubble.dart`
- Modify: `lib/features/chat/presentation/screens/chat_channel_screen.dart`

- [ ] **Step 1: Update `_CallRequestBubble` signature**

In `message_bubble.dart`, replace the `_CallRequestBubble` class:

```dart
class _CallRequestBubble extends StatelessWidget {
  const _CallRequestBubble({
    required this.isOwn,
    this.onAccept,
    this.onProposeAppointment,
  });
  final bool isOwn;
  final VoidCallback? onAccept;
  final VoidCallback? onProposeAppointment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showActions = !isOwn && (onAccept != null || onProposeAppointment != null);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_outlined, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  isOwn
                      ? 'Call-Anfrage gesendet'
                      : 'Klient möchte einen Video-Call',
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onAccept != null)
                    FilledButton.tonal(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Annehmen', style: TextStyle(fontSize: 12)),
                    ),
                  if (onAccept != null && onProposeAppointment != null)
                    const SizedBox(width: 8),
                  if (onProposeAppointment != null)
                    OutlinedButton(
                      onPressed: onProposeAppointment,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade900,
                        side: BorderSide(color: Colors.teal.shade300),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Termin', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Update `MessageBubble` to pass callbacks**

`MessageBubble` needs `onAcceptCall` and `onProposeAppointment` parameters. Update its signature and the `_CallRequestBubble` instantiation:

```dart
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isModerator,
    this.onDeleteRequested,
    this.onAcceptCall,
    this.onProposeAppointment,
  });

  final ChatMessage message;
  final bool isModerator;
  final VoidCallback? onDeleteRequested;
  final VoidCallback? onAcceptCall;
  final VoidCallback? onProposeAppointment;

  @override
  Widget build(BuildContext context) {
    final currentUserId =
        Supabase.instance.client.auth.currentUser?.id ?? '';
    final isOwn = message.isOwnMessage(currentUserId);

    if (message.isDeleted) return _DeletedBubble(isOwn: isOwn);
    if (message.isBotResponse) return _BotBubble(message: message);
    if (message.isCallRequest) return _CallRequestBubble(
      isOwn: isOwn,
      onAccept: isModerator ? onAcceptCall : null,
      onProposeAppointment: isModerator ? onProposeAppointment : null,
    );

    // ... rest of build unchanged
```

- [ ] **Step 3: Wire callbacks in `ChatChannelScreen`**

In `chat_channel_screen.dart`, find the `MessageBubble(...)` instantiation in the `ListView.builder` and add the callbacks:

```dart
                        return MessageBubble(
                          message: msg,
                          isModerator: isModerator,
                          onDeleteRequested: (isModerator ||
                                  msg.isOwnMessage(_currentUserId()))
                              ? () => _confirmDelete(msg)
                              : null,
                          onAcceptCall: isModerator ? _startCall : null,
                          onProposeAppointment: isModerator
                              ? () => _proposeAppointment(context, ref)
                              : null,
                        );
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/features/chat/ 2>&1 | grep "error •"
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/presentation/widgets/message_bubble.dart \
        lib/features/chat/presentation/screens/chat_channel_screen.dart
git commit -m "feat(chat): call-request bubble shows accept/propose-appointment for trainer"
```

---

## Task 12: Post-training community share prompt

After training → mood checkin → share prompt → community chat.

**Files:**
- Modify: `lib/features/training/presentation/screens/training_session_screen.dart`

- [ ] **Step 1: Add share prompt method**

In `training_session_screen.dart`, add this method to `_TrainingSessionScreenState` (before `_onWillPop`):

```dart
  Future<void> _showShareWithCommunityPrompt(String packageId) async {
    // Fetch community channel id for this package
    final res = await Supabase.instance.client
        .from('chat_channels')
        .select('id')
        .eq('type', 'community')
        .eq('package_id', packageId)
        .maybeSingle();

    if (res == null || !mounted) return;
    final channelId = res['id'] as String;

    final share = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erfahrung teilen?'),
        content: const Text(
          'Teile dein heutiges Training mit der Community.\n'
          'Andere Teilnehmer desselben Pakets freuen sich über deinen Bericht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Nein danke'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Teilen'),
          ),
        ],
      ),
    );

    if (share == true && mounted) {
      context.push(
        Routes.chatChannel.replaceFirst(':channelId', channelId),
      );
    }
  }
```

Also add the required import at the top of the file if not already present:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/navigation/app_router.dart';
```

- [ ] **Step 2: Call the prompt after mood checkin**

Find the section after `showMoodCheckinSheet(...)` and `context.pop()`:

```dart
    // One coupled mood + note check-in after training.
    if (enrollment != null) {
      await showMoodCheckinSheet(
        context,
        enrollmentId: enrollment.id,
        onSaved: () {
          ref.invalidate(moodDailyAggregatesProvider);
          ref.invalidate(moodNotesProvider);
        },
      );
    }

    if (!mounted) return;

    if (mounted) context.pop();
```

Replace with:
```dart
    // One coupled mood + note check-in after training.
    if (enrollment != null) {
      await showMoodCheckinSheet(
        context,
        enrollmentId: enrollment.id,
        onSaved: () {
          ref.invalidate(moodDailyAggregatesProvider);
          ref.invalidate(moodNotesProvider);
        },
      );
    }

    if (!mounted) return;

    // Offer to share experience in the package community chat
    await _showShareWithCommunityPrompt(pkg);

    if (!mounted) return;
    context.pop();
```

Note: `pkg` is already in scope (it's `widget.packageId` accessed via `final pkg = widget.packageId` or directly). Check the existing variable name at the top of `_completeSession` and use it.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/training/ 2>&1 | grep "error •"
```

- [ ] **Step 4: Test**

```bash
make run-sim
```

Complete a training session. Verify:
1. Mood checkin sheet appears ✓
2. After dismissing, share dialog appears ✓
3. "Teilen" → navigates to community chat ✓
4. "Nein danke" → returns to dashboard ✓

- [ ] **Step 5: Commit**

```bash
git add lib/features/training/presentation/screens/training_session_screen.dart
git commit -m "feat(training): post-session community share prompt"
```

---

## Task 13: Admin Panel — Premium user management

**Files:**
- Modify: `lib/features/admin/presentation/providers/admin_provider.dart`
- Modify: `lib/features/admin/presentation/screens/admin_panel_screen.dart`

- [ ] **Step 1: Add `AdminUser` model and providers to `admin_provider.dart`**

Append to `lib/features/admin/presentation/providers/admin_provider.dart`:

```dart
// ── Admin user list (for premium management) ──────────────────────────────────

class AdminUser {
  const AdminUser({
    required this.id,
    required this.displayName,
    required this.role,
    required this.subscriptionTier,
  });

  final String id;
  final String displayName;
  final String role;
  final String subscriptionTier;

  bool get isPremium => subscriptionTier == 'premium';

  factory AdminUser.fromJson(Map<String, dynamic> json) => AdminUser(
        id: json['id'] as String,
        displayName: json['display_name'] as String? ?? json['id'] as String,
        role: json['role'] as String? ?? 'practitioner',
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
      );
}

class AdminUsersNotifier extends AsyncNotifier<List<AdminUser>> {
  @override
  Future<List<AdminUser>> build() => _fetch();

  Future<List<AdminUser>> _fetch() async {
    final res = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, role, subscription_tier')
        .order('display_name');
    return (res as List)
        .cast<Map<String, dynamic>>()
        .map(AdminUser.fromJson)
        .toList();
  }

  Future<void> setTier(String userId, String tier) async {
    final session = Supabase.instance.client.auth.currentSession;
    final response = await Supabase.instance.client.functions.invoke(
      'set-subscription-tier',
      body: {'user_id': userId, 'tier': tier},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );
    final data = response.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error'] as String);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final adminUsersProvider =
    AsyncNotifierProvider<AdminUsersNotifier, List<AdminUser>>(
  AdminUsersNotifier.new,
);
```

- [ ] **Step 2: Add premium section to `admin_panel_screen.dart`**

In `lib/features/admin/presentation/screens/admin_panel_screen.dart`, add a new tab or section for premium management. The simplest approach: add a second `FloatingActionButton`-less scaffold section at the bottom of the existing ListView.

Add a "Premium" tab by converting `AdminPanelScreen` to use a `DefaultTabController`. Replace the entire `Scaffold` in `AdminPanelScreen.build` with:

```dart
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                ref.read(adminProvider.notifier).refresh();
                ref.invalidate(adminUsersProvider);
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Trainer-Codes'),
              Tab(text: 'Premium'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TrainerCodesTab(),
            _PremiumTab(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            // Only show FAB on Trainer-Codes tab
            return ValueListenableBuilder<TabController?>(
              valueListenable: ValueNotifier(DefaultTabController.of(context)),
              builder: (context, tabController, _) {
                // Simpler: always show, only act on tab 0
                return FloatingActionButton.extended(
                  icon: const Icon(Icons.add),
                  label: const Text('Code generieren'),
                  onPressed: () => _generateCode(context, ref),
                );
              },
            );
          },
        ),
      ),
    );
  }
```

Then extract the existing body content into `_TrainerCodesTab`:

```dart
class _TrainerCodesTab extends ConsumerWidget {
  const _TrainerCodesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codesAsync = ref.watch(adminProvider);
    return codesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Fehler: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
      data: (codes) {
        if (codes.isEmpty) {
          return const Center(
            child: Text(
              'Noch keine Trainer-Codes generiert.\nTippe unten auf „Code generieren".',
              textAlign: TextAlign.center,
            ),
          );
        }
        final active = codes.where((c) => c.isActive).toList();
        final used = codes.where((c) => c.isUsed).toList();
        final expired = codes.where((c) => c.isExpired).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (active.isNotEmpty) ...[
              _SectionHeader('Aktiv (${active.length})'),
              ...active.map((c) => _CodeTile(code: c)),
              const SizedBox(height: 8),
            ],
            if (used.isNotEmpty) ...[
              _SectionHeader('Verwendet (${used.length})'),
              ...used.map((c) => _CodeTile(code: c)),
              const SizedBox(height: 8),
            ],
            if (expired.isNotEmpty) ...[
              _SectionHeader('Abgelaufen (${expired.length})'),
              ...expired.map((c) => _CodeTile(code: c)),
            ],
          ],
        );
      },
    );
  }
}
```

And add `_PremiumTab`:

```dart
class _PremiumTab extends ConsumerWidget {
  const _PremiumTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    return usersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Fehler: $e')),
      data: (users) {
        final practitioners = users
            .where((u) => u.role == 'practitioner')
            .toList();
        if (practitioners.isEmpty) {
          return const Center(child: Text('Keine Nutzer gefunden.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: practitioners.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = practitioners[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                ),
              ),
              title: Text(user.displayName),
              subtitle: Text(user.isPremium ? 'Premium' : 'Free'),
              trailing: Switch(
                value: user.isPremium,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(adminUsersProvider.notifier)
                        .setTier(user.id, value ? 'premium' : 'free');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler: $e')),
                      );
                    }
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
```

Also add `import '../providers/admin_provider.dart';` if not already covering `AdminUser` and `adminUsersProvider`.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/admin/ 2>&1 | grep "error •"
```

- [ ] **Step 4: Full analyze**

```bash
flutter analyze lib/ 2>&1 | grep "error •" | grep -v "notification_service\|clock_provider\|reminder_settings\|secure_storage\|logger\|training_exercise_screen\|training_movement\|training_position\|rhythm_visualizer\|main_staging"
```
Expected: no output (only pre-existing errors excluded).

- [ ] **Step 5: Commit**

```bash
git add lib/features/admin/presentation/providers/admin_provider.dart \
        lib/features/admin/presentation/screens/admin_panel_screen.dart
git commit -m "feat(admin): premium user management tab with tier toggle"
```

---

## Task 14: E2E Smoke Test

Manual verification of the complete flow on device.

- [ ] **Step 1: Launch app**

```bash
make run
```

- [ ] **Step 2: Test bottom navigation**
- Tap all 4 tabs → each navigates correctly
- Tap chat tab → shows inbox (may be empty or show existing channels)

- [ ] **Step 3: Test trainer activation flow (as practitioner account)**
- Open Profile tab → "Trainer werden" tile visible
- Enter a code generated from admin → role changes to trainer
- Trainer Dashboard appears after role change

- [ ] **Step 4: Test community channel provisioning**
- Sign in as a test practitioner account with an active enrollment
- Navigate to Nachrichten tab → "MEINE PAKETE" section should show the package community channel
- If not: run the backfill SQL manually (Task 4)

- [ ] **Step 5: Test video call gate**
- Sign in as practitioner with `subscription_tier = 'free'`
- Open trainer direct chat → videocam-off icon visible
- Tap → premium sheet appears

- [ ] **Step 6: Test premium toggle (admin)**
- Sign in as admin → Admin Panel → Premium tab
- Toggle a user to Premium → switch updates
- Sign in as that user → videocam icon is now active in trainer chat

- [ ] **Step 7: Test post-training share prompt**
- Complete a training session as a practitioner
- After mood checkin → share dialog appears
- Tap "Teilen" → navigates to community channel

- [ ] **Step 8: Commit any final fixes**

```bash
git add -p  # stage only intentional changes
git commit -m "fix: post-E2E smoke test corrections"
```
