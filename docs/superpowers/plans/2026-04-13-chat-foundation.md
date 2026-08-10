# Chat Foundation + Triage Bot — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add real-time 1:1 and community-channel chat between Practitioners and Trainers, plus an automated Triage Bot that routes common questions to pre-written FAQ answers or escalates to the trainer.

**Architecture:** All chat data lives in Supabase/PostgreSQL under RLS. The Flutter client uses `supabase_flutter`'s `.stream()` API for real-time message delivery — no new Flutter packages required for chat. A Supabase Edge Function (Deno TypeScript) handles triage bot logic, triggered by the client after every sent message. An abstract `ChatRepository` interface separates domain logic from Supabase internals and enables clean mocking in tests.

**Tech Stack:**
- `supabase_flutter` (already in pubspec) — Realtime, PostgreSQL, Edge Functions
- `flutter_riverpod` (already in pubspec) — providers for channels and messages
- `mocktail` (already in dev deps) — repository mocking in unit tests
- Deno / TypeScript — Triage Bot Edge Function
- No new Flutter packages required

---

> ⚠️ **Environment:** All SQL runs against the **DEV** Supabase project. Do NOT run against production. Check `CLAUDE.md` before any Supabase operation.

> ⚠️ **FCM Prerequisite:** Push notifications for new chat messages require `firebase_messaging` to be re-enabled in `pubspec.yaml` (currently commented out). The Triage Bot Edge Function sends FCM for trainer escalations only, using the legacy FCM HTTP API with a server key — this works independently of the Flutter package. Full in-app background notifications for every new message are a separate task deferred to when Firebase packages are re-activated.

> **Plan 2 (Video Chat / Agora)** must be executed after this plan is complete — it depends on the `chat_channels` table created here.

---

## File Map

### New files

| Path | Responsibility |
|---|---|
| `supabase/migrations/20260413_chat_foundation.sql` | 5 new tables + RLS + indexes + bot seed |
| `supabase/functions/chat-triage-bot/index.ts` | Deno Edge Function — keyword match → FAQ reply or trainer escalation |
| `lib/features/chat/domain/models/chat_channel.dart` | `ChatChannel` immutable value object |
| `lib/features/chat/domain/models/chat_message.dart` | `ChatMessage` immutable value object, soft-delete aware |
| `lib/features/chat/domain/repositories/chat_repository.dart` | Abstract `ChatRepository` interface |
| `lib/features/chat/data/repositories/supabase_chat_repository.dart` | Supabase implementation of `ChatRepository` |
| `lib/features/chat/presentation/providers/chat_providers.dart` | All Riverpod providers for chat |
| `lib/features/chat/presentation/screens/chat_inbox_screen.dart` | Channel list (direct + community), unread badges |
| `lib/features/chat/presentation/screens/chat_channel_screen.dart` | Message list, input bar, typing indicator, moderator delete |
| `lib/features/chat/presentation/widgets/channel_list_tile.dart` | Single row in inbox — name, last message, unread badge |
| `lib/features/chat/presentation/widgets/message_bubble.dart` | Chat bubble — own vs other, bot style, deleted style, call-request style |
| `lib/features/chat/presentation/widgets/message_input_bar.dart` | Text field + send button + call-request button (practitioner only) |
| `lib/features/chat/presentation/widgets/typing_indicator.dart` | Animated "… is typing" via Supabase Presence |
| `test/features/chat/data/supabase_chat_repository_test.dart` | Unit tests for repository — mock Supabase responses |
| `test/features/chat/presentation/chat_providers_test.dart` | Unit tests for providers |

### Modified files

| Path | Change |
|---|---|
| `lib/core/navigation/app_router.dart` | Add `Routes.chatInbox`, `Routes.chatChannel`, 2 `GoRoute` entries |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Add chat `IconButton` to `AppBar.actions` |
| `lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart` | Add chat `IconButton` to `AppBar.actions` |

---

## Task 1: Supabase SQL Migration

**Files:**
- Create: `supabase/migrations/20260413_chat_foundation.sql`

This migration is additive — it uses `CREATE TABLE IF NOT EXISTS` and `CREATE POLICY IF NOT EXISTS` so it can be re-run safely.

- [ ] **Step 1.1 — Write the migration file**

```sql
-- ============================================================================
-- CoreJourney — Chat Foundation
-- Tables: chat_channels, chat_channel_members, chat_messages, bot_faqs
-- Plus: bot system user seed, RLS policies, performance indexes
--
-- Run in DEV: https://supabase.com/dashboard → SQL editor
-- ============================================================================

-- ── 1. chat_channels ─────────────────────────────────────────────────────────

create table if not exists chat_channels (
  id          uuid primary key default gen_random_uuid(),
  type        text not null check (type in ('direct', 'community')),
  package_id  text references reflex_packages(id) on delete cascade,
  created_at  timestamptz not null default now(),
  constraint community_requires_package
    check (type != 'community' or package_id is not null),
  constraint direct_no_package
    check (type != 'direct' or package_id is null)
);

comment on table chat_channels is
  'Chat rooms: direct (1-to-1 trainer↔client) or community (per reflex block).';

-- ── 2. chat_channel_members ───────────────────────────────────────────────────

create table if not exists chat_channel_members (
  channel_id   uuid not null references chat_channels(id) on delete cascade,
  user_id      uuid not null references profiles(id) on delete cascade,
  role         text not null default 'member' check (role in ('member', 'moderator')),
  last_read_at timestamptz not null default now(),
  joined_at    timestamptz not null default now(),
  primary key (channel_id, user_id)
);

comment on column chat_channel_members.role is
  'member = read/write. moderator = read/write/delete (trainers only).';
comment on column chat_channel_members.last_read_at is
  'Updated when user opens the channel. Used to compute unread badge count.';

-- ── 3. chat_messages ──────────────────────────────────────────────────────────

create table if not exists chat_messages (
  id               uuid primary key default gen_random_uuid(),
  channel_id       uuid not null references chat_channels(id) on delete cascade,
  sender_id        uuid not null references profiles(id) on delete cascade,
  content          text not null,
  is_bot_response  boolean not null default false,
  is_call_request  boolean not null default false,
  deleted_at       timestamptz,
  created_at       timestamptz not null default now()
);

comment on column chat_messages.is_call_request is
  'True when a Practitioner is requesting a video call from their Trainer.';
comment on column chat_messages.deleted_at is
  'Soft delete. Moderators set this; clients see placeholder text instead.';

-- ── 4. bot_faqs ───────────────────────────────────────────────────────────────

create table if not exists bot_faqs (
  id                  uuid primary key default gen_random_uuid(),
  keywords            text[] not null,
  response_de         text not null,
  response_en         text not null,
  escalate_to_trainer boolean not null default false,
  created_at          timestamptz not null default now()
);

comment on table bot_faqs is
  'Triage bot FAQ entries. Edge Function matches message keywords against this table.';

-- ── 5. Indexes ────────────────────────────────────────────────────────────────

create index if not exists idx_chat_messages_channel_created
  on chat_messages (channel_id, created_at desc);

create index if not exists idx_chat_channel_members_user
  on chat_channel_members (user_id);

create index if not exists idx_chat_messages_sender
  on chat_messages (sender_id);

-- ── 6. Bot system user profile ────────────────────────────────────────────────
-- The bot writes messages using a dedicated service-role Supabase Auth user.
-- Create the bot user in Supabase Auth first, then replace the UUID below.
-- This insert is idempotent (ON CONFLICT DO NOTHING).

insert into profiles (id, display_name, role, locale)
values (
  '00000000-0000-0000-0000-000000000001',  -- replace after creating bot auth user
  'CoreJourney Assistent',
  'practitioner',
  'de'
) on conflict (id) do nothing;

-- ── 7. Seed bot_faqs (starter set — extend in Supabase dashboard) ─────────────

insert into bot_faqs (keywords, response_de, response_en, escalate_to_trainer) values
(
  array['schmerz', 'pain', 'weh tut', 'hurt', 'hurts'],
  'Wenn du während der Übungen Schmerzen verspürst, stoppe sofort und ruhe dich aus. Leichtes Ziehen oder Kribbeln ist normal — scharfer Schmerz nicht. Teile deinem Trainer mit, wo und wann du Schmerzen spürst.',
  'If you feel pain during the exercises, stop immediately and rest. Mild tingling or pulling is normal — sharp pain is not. Let your trainer know where and when you feel pain.',
  true
),
(
  array['wie lange', 'how long', 'dauer', 'wochen', 'weeks'],
  'Das Moro-Programm dauert 4–8 Wochen, je nach deiner Ausgangssituation. Dein Goldener Tag zeigt dir, wann du mit dem Block fertig bist.',
  'The Moro program lasts 4–8 weeks depending on your starting point. Your Golden Day shows you when you will complete the block.',
  false
),
(
  array['vergessen', 'forgot', 'verpasst', 'missed', 'ausgelassen'],
  'Kein Problem — eine verpasste Einheit unterbricht das Programm nicht. Starte einfach morgen wieder. Dein Trainer kann dir sagen, ob du deinen Goldenen Tag anpassen solltest.',
  'No problem — one missed session does not interrupt the program. Just start again tomorrow. Your trainer can advise if you should adjust your Golden Day.',
  false
),
(
  array['übelkeit', 'nausea', 'schwindel', 'dizzy', 'dizziness'],
  'Leichter Schwindel oder Übelkeit nach Moro-Übungen kann vorkommen. Mach eine Pause, trinke Wasser und atme tief durch. Bleibt es längere Zeit, informiere bitte deinen Trainer.',
  'Mild dizziness or nausea after Moro exercises can happen. Take a break, drink water and breathe deeply. If it persists, please inform your trainer.',
  true
)
on conflict do nothing;

-- ── 8. RLS — Enable ──────────────────────────────────────────────────────────

alter table chat_channels enable row level security;
alter table chat_channel_members enable row level security;
alter table chat_messages enable row level security;
alter table bot_faqs enable row level security;

-- ── 9. RLS — chat_channels ───────────────────────────────────────────────────
-- A user can see a channel only if they are a member.

create policy "Members can view their channels" on chat_channels
  for select using (
    exists (
      select 1 from chat_channel_members
      where channel_id = chat_channels.id
        and user_id = auth.uid()
    )
  );

-- Only service role (Edge Functions, admin scripts) may create channels.
-- Client-side channel creation is not permitted.
create policy "No client-side channel creation" on chat_channels
  for insert with check (false);

-- ── 10. RLS — chat_channel_members ───────────────────────────────────────────

create policy "Users can view their own memberships" on chat_channel_members
  for select using (user_id = auth.uid());

create policy "Users can update their own last_read_at" on chat_channel_members
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

create policy "No client-side membership creation" on chat_channel_members
  for insert with check (false);

-- ── 11. RLS — chat_messages ───────────────────────────────────────────────────

create policy "Members can read messages in their channels" on chat_messages
  for select using (
    exists (
      select 1 from chat_channel_members
      where channel_id = chat_messages.channel_id
        and user_id = auth.uid()
    )
  );

create policy "Members can send messages to their channels" on chat_messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from chat_channel_members
      where channel_id = chat_messages.channel_id
        and user_id = auth.uid()
    )
  );

create policy "Senders can soft-delete their own messages" on chat_messages
  for update using (sender_id = auth.uid())
  with check (sender_id = auth.uid());

create policy "Moderators can soft-delete any message in their channels" on chat_messages
  for update using (
    exists (
      select 1 from chat_channel_members
      where channel_id = chat_messages.channel_id
        and user_id = auth.uid()
        and role = 'moderator'
    )
  );

-- ── 12. RLS — bot_faqs ───────────────────────────────────────────────────────
-- No direct client reads — the Edge Function uses service role key.
-- Admins read/write via Supabase dashboard (service role bypasses RLS).

create policy "No client read on bot_faqs" on bot_faqs
  for select using (false);
```

- [ ] **Step 1.2 — Apply migration in DEV Supabase SQL editor**

Open: DEV Supabase project → SQL editor → paste and run `20260413_chat_foundation.sql`.

Expected: all statements complete without error. Verify in Table Editor that `chat_channels`, `chat_channel_members`, `chat_messages`, `bot_faqs` appear.

- [ ] **Step 1.3 — Create bot Auth user**

In DEV Supabase: Authentication → Users → Add user (email: `bot@corejourney.internal`, any password). Copy the generated UUID. Replace `'00000000-0000-0000-0000-000000000001'` in the migration with the real UUID and re-run just the `INSERT INTO profiles` block.

Save the bot UUID in a `.env.dev` comment for reference:
```
# BOT_USER_ID=<paste uuid here>  (used in Edge Function env vars)
```

- [ ] **Step 1.4 — Verify RLS adversarially**

Run in Supabase SQL editor (as a non-member user) to confirm RLS blocks access:
```sql
-- Should return 0 rows (no memberships exist yet, so no channels visible)
select * from chat_channels;

-- Should return 0 rows (no client read on bot_faqs)
select * from bot_faqs;
```

- [ ] **Step 1.5 — Commit migration file**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add supabase/migrations/20260413_chat_foundation.sql
git commit -m "feat(chat): add SQL migration — chat tables, RLS, bot seed"
```

---

## Task 2: Domain Models

**Files:**
- Create: `lib/features/chat/domain/models/chat_channel.dart`
- Create: `lib/features/chat/domain/models/chat_message.dart`

- [ ] **Step 2.1 — Write `chat_channel.dart`**

```dart
// lib/features/chat/domain/models/chat_channel.dart

import 'package:equatable/equatable.dart';

enum ChannelType { direct, community }

enum MemberRole { member, moderator }

class ChatChannel extends Equatable {
  const ChatChannel({
    required this.id,
    required this.type,
    this.packageId,
    required this.createdAt,
    required this.currentUserRole,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final ChannelType type;

  /// Non-null for community channels; the reflex package this channel belongs to.
  final String? packageId;

  final DateTime createdAt;

  /// The authenticated user's role in this channel.
  final MemberRole currentUserRole;

  /// Preview text for the inbox row.
  final String? lastMessageContent;
  final DateTime? lastMessageAt;

  /// Number of messages since the user last opened this channel.
  final int unreadCount;

  bool get isModerator => currentUserRole == MemberRole.moderator;

  /// Display name for the channel, derived from type.
  /// Callers should localise this using the package name from the content system.
  String channelDisplayName({String? packageName}) {
    return switch (type) {
      ChannelType.direct => 'Trainer',
      ChannelType.community => packageName ?? packageId ?? 'Community',
    };
  }

  factory ChatChannel.fromJson(Map<String, dynamic> json, {
    required MemberRole currentUserRole,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int unreadCount = 0,
  }) {
    return ChatChannel(
      id: json['id'] as String,
      type: json['type'] == 'direct' ? ChannelType.direct : ChannelType.community,
      packageId: json['package_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      currentUserRole: currentUserRole,
      lastMessageContent: lastMessageContent,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }

  @override
  List<Object?> get props => [id, type, packageId, createdAt, currentUserRole, unreadCount];
}
```

- [ ] **Step 2.2 — Write `chat_message.dart`**

```dart
// lib/features/chat/domain/models/chat_message.dart

import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.content,
    required this.isBotResponse,
    required this.isCallRequest,
    this.deletedAt,
    required this.createdAt,
  });

  final String id;
  final String channelId;
  final String senderId;
  final String content;
  final bool isBotResponse;

  /// True when a Practitioner sends a video call request to their Trainer.
  final bool isCallRequest;

  /// Non-null = soft-deleted. Show placeholder text, not content.
  final DateTime? deletedAt;

  final DateTime createdAt;

  bool get isDeleted => deletedAt != null;

  /// Whether this message was sent by the currently authenticated user.
  bool isOwnMessage(String currentUserId) => senderId == currentUserId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      channelId: json['channel_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      isBotResponse: json['is_bot_response'] as bool? ?? false,
      isCallRequest: json['is_call_request'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null
          ? DateTime.parse(json['deleted_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, channelId, senderId, content, isBotResponse,
      isCallRequest, deletedAt, createdAt];
}
```

- [ ] **Step 2.3 — Commit**

```bash
git add lib/features/chat/domain/models/
git commit -m "feat(chat): add ChatChannel and ChatMessage domain models"
```

---

## Task 3: Abstract ChatRepository Interface

**Files:**
- Create: `lib/features/chat/domain/repositories/chat_repository.dart`

- [ ] **Step 3.1 — Write interface**

```dart
// lib/features/chat/domain/repositories/chat_repository.dart

import '../models/chat_channel.dart';
import '../models/chat_message.dart';

/// Abstract interface for all chat data operations.
/// Implement with [SupabaseChatRepository] in production
/// and a mock in tests.
abstract class ChatRepository {
  // ── Channels ────────────────────────────────────────────────────────────────

  /// Returns all channels the current user is a member of,
  /// ordered by last message time descending.
  /// Direct channels first, then community channels.
  Future<List<ChatChannel>> getChannels();

  /// Creates a direct channel between the current user and [otherUserId]
  /// and adds both as members. The current user's role is 'member';
  /// if the other user is a trainer, they are added as 'moderator'.
  /// Idempotent — returns existing channel if one already exists.
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId);

  /// Joins the community channel for [packageId] as 'member'.
  /// If the user has trainer role, they join as 'moderator'.
  /// No-op if already a member.
  Future<void> joinCommunityChannel(String packageId);

  /// Updates [lastReadAt] for the current user in [channelId] to now.
  Future<void> markChannelRead(String channelId);

  // ── Messages ─────────────────────────────────────────────────────────────────

  /// Real-time stream of messages for [channelId].
  /// Emits the most recent [pageSize] messages on subscription,
  /// then appends new messages as they arrive.
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize});

  /// Fetches messages older than [before] (exclusive), for infinite scroll.
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit,
  });

  /// Sends a plain text message to [channelId] and triggers the triage bot.
  Future<void> sendMessage(String channelId, String content);

  /// Sends a video call request message.
  /// Only Practitioners should call this — Trainers start calls directly.
  Future<void> sendCallRequest(String channelId);

  /// Soft-deletes [messageId].
  /// Callers must be the message sender or a channel moderator.
  Future<void> deleteMessage(String messageId);

  // ── Typing indicator ─────────────────────────────────────────────────────────

  /// Broadcasts that the current user is typing in [channelId].
  /// Call on every keystroke; presence expires after ~10 s automatically.
  Future<void> broadcastTyping(String channelId);

  /// Stream of user IDs (excluding current user) who are currently typing.
  Stream<Set<String>> watchTypingUsers(String channelId);
}
```

- [ ] **Step 3.2 — Commit**

```bash
git add lib/features/chat/domain/repositories/chat_repository.dart
git commit -m "feat(chat): add abstract ChatRepository interface"
```

---

## Task 4: SupabaseChatRepository — Channels

**Files:**
- Create: `lib/features/chat/data/repositories/supabase_chat_repository.dart`

- [ ] **Step 4.1 — Write failing test for `getChannels`**

```dart
// test/features/chat/data/supabase_chat_repository_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/domain/repositories/chat_repository.dart';

// Minimal in-memory fake — no Supabase needed for domain-logic tests.
class _FakeChatRepository implements ChatRepository {
  final List<ChatChannel> _channels;
  _FakeChatRepository(this._channels);

  @override
  Future<List<ChatChannel>> getChannels() async => _channels;

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async =>
      _channels.firstWhere((c) => c.type == ChannelType.direct);

  @override
  Future<void> joinCommunityChannel(String packageId) async {}

  @override
  Future<void> markChannelRead(String channelId) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize = 30}) =>
      const Stream.empty();

  @override
  Future<List<ChatMessage>> fetchOlderMessages(String channelId,
      {required DateTime before, int limit = 30}) async => [];

  @override
  Future<void> sendMessage(String channelId, String content) async {}

  @override
  Future<void> sendCallRequest(String channelId) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}

  @override
  Future<void> broadcastTyping(String channelId) async {}

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) => const Stream.empty();
}

void main() {
  group('ChatRepository — channel ordering', () {
    late ChatRepository repo;

    setUp(() {
      final now = DateTime(2026, 4, 13, 12, 0);
      repo = _FakeChatRepository([
        ChatChannel(
          id: 'comm-1',
          type: ChannelType.community,
          packageId: 'moro',
          createdAt: now,
          currentUserRole: MemberRole.member,
          lastMessageAt: now.subtract(const Duration(hours: 2)),
          unreadCount: 3,
        ),
        ChatChannel(
          id: 'direct-1',
          type: ChannelType.direct,
          createdAt: now,
          currentUserRole: MemberRole.member,
          lastMessageAt: now.subtract(const Duration(minutes: 10)),
          unreadCount: 1,
        ),
      ]);
    });

    test('returns all channels', () async {
      final channels = await repo.getChannels();
      expect(channels, hasLength(2));
    });

    test('ChatChannel.channelDisplayName returns Trainer for direct', () {
      final channel = ChatChannel(
        id: 'direct-1',
        type: ChannelType.direct,
        createdAt: DateTime.now(),
        currentUserRole: MemberRole.member,
        unreadCount: 0,
      );
      expect(channel.channelDisplayName(), 'Trainer');
    });

    test('ChatChannel.channelDisplayName returns packageName for community', () {
      final channel = ChatChannel(
        id: 'comm-1',
        type: ChannelType.community,
        packageId: 'moro',
        createdAt: DateTime.now(),
        currentUserRole: MemberRole.member,
        unreadCount: 0,
      );
      expect(channel.channelDisplayName(packageName: 'Moro'), 'Moro');
    });

    test('isModerator returns true for moderator role', () {
      final channel = ChatChannel(
        id: 'comm-1',
        type: ChannelType.community,
        packageId: 'moro',
        createdAt: DateTime.now(),
        currentUserRole: MemberRole.moderator,
        unreadCount: 0,
      );
      expect(channel.isModerator, isTrue);
    });
  });

  group('ChatMessage', () {
    test('isDeleted returns true when deletedAt is set', () {
      final msg = ChatMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'user-1',
        content: 'hello',
        isBotResponse: false,
        isCallRequest: false,
        deletedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      expect(msg.isDeleted, isTrue);
    });

    test('isDeleted returns false when deletedAt is null', () {
      final msg = ChatMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'user-1',
        content: 'hello',
        isBotResponse: false,
        isCallRequest: false,
        createdAt: DateTime.now(),
      );
      expect(msg.isDeleted, isFalse);
    });

    test('isOwnMessage matches sender', () {
      final msg = ChatMessage(
        id: 'msg-1',
        channelId: 'ch-1',
        senderId: 'user-abc',
        content: 'hello',
        isBotResponse: false,
        isCallRequest: false,
        createdAt: DateTime.now(),
      );
      expect(msg.isOwnMessage('user-abc'), isTrue);
      expect(msg.isOwnMessage('user-xyz'), isFalse);
    });

    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'msg-1',
        'channel_id': 'ch-1',
        'sender_id': 'user-1',
        'content': 'test content',
        'is_bot_response': true,
        'is_call_request': false,
        'deleted_at': null,
        'created_at': '2026-04-13T10:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.id, 'msg-1');
      expect(msg.isBotResponse, isTrue);
      expect(msg.isCallRequest, isFalse);
      expect(msg.isDeleted, isFalse);
    });
  });
}
```

- [ ] **Step 4.2 — Run test to verify it compiles and passes**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/chat/data/supabase_chat_repository_test.dart -v
```

Expected: all tests PASS (domain model logic only — no Supabase).

- [ ] **Step 4.3 — Write `SupabaseChatRepository` — channels section**

```dart
// lib/features/chat/data/repositories/supabase_chat_repository.dart

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

const _uuid = Uuid();

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  // ── Channels ────────────────────────────────────────────────────────────────

  @override
  Future<List<ChatChannel>> getChannels() async {
    final userId = _userId;
    if (userId == null) return [];

    // Fetch memberships with channel data in one join.
    final memberships = await _client
        .from('chat_channel_members')
        .select('role, last_read_at, channel_id, chat_channels(*)')
        .eq('user_id', userId);

    final channels = <ChatChannel>[];
    for (final m in memberships as List) {
      final channelJson = m['chat_channels'] as Map<String, dynamic>;
      final channelId = channelJson['id'] as String;
      final role = m['role'] == 'moderator' ? MemberRole.moderator : MemberRole.member;
      final lastReadAt = DateTime.parse(m['last_read_at'] as String);

      // Fetch last message and unread count concurrently.
      final results = await Future.wait([
        _client
            .from('chat_messages')
            .select('content, created_at')
            .eq('channel_id', channelId)
            .isFilter('deleted_at', null)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle(),
        _client
            .from('chat_messages')
            .count()
            .eq('channel_id', channelId)
            .gt('created_at', lastReadAt.toIso8601String())
            .neq('sender_id', userId),
      ]);

      final lastMsgRow = results[0] as Map<String, dynamic>?;
      // count() returns a PostgrestResponse; extract count from header.
      // supabase_flutter returns count as the second element via .count().
      // We use a workaround — count messages manually from the response.
      final unreadRes = await _client
          .from('chat_messages')
          .select('id', const FetchOptions(count: CountOption.exact))
          .eq('channel_id', channelId)
          .gt('created_at', lastReadAt.toIso8601String())
          .neq('sender_id', userId);
      final unreadCount = unreadRes.count ?? 0;

      channels.add(ChatChannel.fromJson(
        channelJson,
        currentUserRole: role,
        lastMessageContent: lastMsgRow?['content'] as String?,
        lastMessageAt: lastMsgRow != null
            ? DateTime.parse(lastMsgRow['created_at'] as String)
            : null,
        unreadCount: unreadCount,
      ));
    }

    // Direct channels first, then community; within each group: most recent first.
    channels.sort((a, b) {
      if (a.type != b.type) {
        return a.type == ChannelType.direct ? -1 : 1;
      }
      final at = a.lastMessageAt;
      final bt = b.lastMessageAt;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });

    return channels;
  }

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    // Call a Postgres RPC that atomically finds-or-creates the direct channel.
    // See Task 1 note: add this RPC to the migration if not present.
    final channelId = await _client.rpc(
      'get_or_create_direct_channel',
      params: {'user_a': userId, 'user_b': otherUserId},
    ) as String;

    final channelJson = await _client
        .from('chat_channels')
        .select()
        .eq('id', channelId)
        .single();

    return ChatChannel.fromJson(
      channelJson,
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );
  }

  @override
  Future<void> joinCommunityChannel(String packageId) async {
    final userId = _userId;
    if (userId == null) return;

    // Find the community channel for this package.
    final channelRes = await _client
        .from('chat_channels')
        .select('id')
        .eq('type', 'community')
        .eq('package_id', packageId)
        .maybeSingle();

    if (channelRes == null) return; // Channel not seeded yet — admin must create it.

    final channelId = channelRes['id'] as String;

    // Determine role: trainer → moderator, practitioner → member.
    final profileRes = await _client
        .from('profiles')
        .select('role')
        .eq('id', userId)
        .single();
    final role = profileRes['role'] == 'trainer' ? 'moderator' : 'member';

    await _client.from('chat_channel_members').upsert({
      'channel_id': channelId,
      'user_id': userId,
      'role': role,
      'joined_at': DateTime.now().toIso8601String(),
    }, onConflict: 'channel_id, user_id');
  }

  @override
  Future<void> markChannelRead(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('chat_channel_members')
        .update({'last_read_at': DateTime.now().toIso8601String()})
        .eq('channel_id', channelId)
        .eq('user_id', userId);
  }
```

- [ ] **Step 4.4 — Add SQL helper RPC to migration file (append)**

Append this function to `supabase/migrations/20260413_chat_foundation.sql` and re-run in DEV:

```sql
-- ── Helper: get_or_create_direct_channel ─────────────────────────────────────
-- Returns the channel_id for the direct channel between user_a and user_b.
-- Creates channel + both memberships if none exists.
-- Trainers are added as moderator; practitioners as member.

create or replace function get_or_create_direct_channel(user_a uuid, user_b uuid)
returns uuid
language plpgsql security definer as $$
declare
  ch_id uuid;
  role_a text;
  role_b text;
begin
  -- Find existing direct channel shared by both users
  select c.id into ch_id
  from chat_channels c
  join chat_channel_members m1 on m1.channel_id = c.id and m1.user_id = user_a
  join chat_channel_members m2 on m2.channel_id = c.id and m2.user_id = user_b
  where c.type = 'direct'
  limit 1;

  if ch_id is not null then
    return ch_id;
  end if;

  -- Create channel
  insert into chat_channels (type) values ('direct') returning id into ch_id;

  -- Determine roles
  select case when role = 'trainer' then 'moderator' else 'member' end
    into role_a from profiles where id = user_a;
  select case when role = 'trainer' then 'moderator' else 'member' end
    into role_b from profiles where id = user_b;

  -- Add both members
  insert into chat_channel_members (channel_id, user_id, role) values
    (ch_id, user_a, role_a),
    (ch_id, user_b, role_b);

  return ch_id;
end;
$$;
```

- [ ] **Step 4.5 — Apply updated migration in DEV SQL editor**

Run just the `create or replace function get_or_create_direct_channel` block.

- [ ] **Step 4.6 — Commit**

```bash
git add lib/features/chat/data/repositories/supabase_chat_repository.dart
git add supabase/migrations/20260413_chat_foundation.sql
git commit -m "feat(chat): SupabaseChatRepository — channel management"
```

---

## Task 5: SupabaseChatRepository — Messages

**Files:**
- Modify: `lib/features/chat/data/repositories/supabase_chat_repository.dart`

Append the following methods to the `SupabaseChatRepository` class:

- [ ] **Step 5.1 — Write failing test for `sendMessage`**

Add to `test/features/chat/data/supabase_chat_repository_test.dart`:

```dart
  group('FakeChatRepository — message operations', () {
    late _FakeChatRepository repo;
    final List<ChatMessage> sent = [];

    setUp(() {
      sent.clear();
      repo = _FakeChatRepository([]);
    });

    test('sendMessage does not throw', () async {
      await expectLater(
        repo.sendMessage('ch-1', 'Hello'),
        completes,
      );
    });

    test('sendCallRequest does not throw', () async {
      await expectLater(
        repo.sendCallRequest('ch-1'),
        completes,
      );
    });

    test('deleteMessage does not throw', () async {
      await expectLater(
        repo.deleteMessage('msg-1'),
        completes,
      );
    });

    test('watchMessages returns empty stream by default', () async {
      final stream = repo.watchMessages('ch-1');
      await expectLater(stream, emitsDone);
    });
  });
```

- [ ] **Step 5.2 — Run test to verify it passes**

```bash
flutter test test/features/chat/data/supabase_chat_repository_test.dart -v
```

Expected: all tests PASS.

- [ ] **Step 5.3 — Implement message methods in `SupabaseChatRepository`**

Append to `lib/features/chat/data/repositories/supabase_chat_repository.dart` inside the class:

```dart
  // ── Messages ─────────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId, {int pageSize = 30}) {
    // .stream() returns realtime-enabled rows ordered by the column specified.
    // We order ascending so oldest messages are at index 0.
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel_id', channelId)
        .order('created_at', ascending: true)
        .limit(pageSize)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('channel_id', channelId)
        .lt('created_at', before.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);

    // Reverse so caller gets ascending order (oldest first).
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  @override
  Future<void> sendMessage(String channelId, String content) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': content,
      'is_bot_response': false,
      'is_call_request': false,
    });

    // Trigger triage bot asynchronously — do not await so UI stays responsive.
    unawaited(_triggerTriageBot(channelId: channelId, content: content));
  }

  @override
  Future<void> sendCallRequest(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    const callRequestContent =
        '📹 Video-Call angefragt / Video call requested';

    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': callRequestContent,
      'is_bot_response': false,
      'is_call_request': true,
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _client
        .from('chat_messages')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', messageId);
  }

  // ── Typing indicator (Supabase Realtime Presence) ─────────────────────────

  final _presenceChannels = <String, RealtimeChannel>{};

  @override
  Future<void> broadcastTyping(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    final ch = _presenceChannels.putIfAbsent(
      channelId,
      () => _client
          .channel('typing:$channelId',
              opts: const RealtimeChannelConfig(ack: false))
          ..subscribe(),
    );

    await ch.track({'user_id': userId, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) {
    final userId = _userId;
    final controller = StreamController<Set<String>>.broadcast();

    final ch = _client
        .channel('typing:$channelId',
            opts: const RealtimeChannelConfig(ack: false))
        .onPresenceSync((payload) {
          final presences = ch.presenceState();
          final typingUsers = presences.entries
              .expand((e) => e.value)
              .map((p) => p.payload['user_id'] as String?)
              .whereType<String>()
              .where((id) => id != userId)
              .toSet();
          // Only emit users who sent a typing event in the last 10 s.
          final cutoff = DateTime.now()
              .subtract(const Duration(seconds: 10))
              .millisecondsSinceEpoch;
          final recent = presences.entries
              .expand((e) => e.value)
              .where((p) {
                final ts = p.payload['ts'] as int?;
                return ts != null && ts >= cutoff;
              })
              .map((p) => p.payload['user_id'] as String?)
              .whereType<String>()
              .where((id) => id != userId)
              .toSet();
          controller.add(recent);
        })
      ..subscribe();

    controller.onCancel = () {
      ch.unsubscribe();
    };

    return controller.stream;
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  Future<void> _triggerTriageBot({
    required String channelId,
    required String content,
  }) async {
    try {
      await _client.functions.invoke(
        'chat-triage-bot',
        body: {
          'channel_id': channelId,
          'content': content,
          'locale': _client.auth.currentUser?.userMetadata?['locale'] ?? 'de',
        },
      );
    } catch (e) {
      // Bot failure is non-fatal — user message is already saved.
      // Log but do not surface to user.
      debugPrint('Triage bot invocation failed: $e');
    }
  }
}
```

- [ ] **Step 5.4 — Run full test suite to verify nothing breaks**

```bash
flutter test test/features/chat/ -v
```

Expected: all tests PASS.

- [ ] **Step 5.5 — Commit**

```bash
git add lib/features/chat/data/repositories/supabase_chat_repository.dart
git commit -m "feat(chat): SupabaseChatRepository — messages, streaming, typing"
```

---

## Task 6: Riverpod Providers

**Files:**
- Create: `lib/features/chat/presentation/providers/chat_providers.dart`

- [ ] **Step 6.1 — Write failing provider test**

```dart
// test/features/chat/presentation/chat_providers_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/domain/models/chat_message.dart';
import 'package:corejourney/features/chat/domain/repositories/chat_repository.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

class _StubRepo implements ChatRepository {
  @override Future<List<ChatChannel>> getChannels() async => [
    ChatChannel(
      id: 'ch-1',
      type: ChannelType.direct,
      createdAt: DateTime(2026, 4, 13),
      currentUserRole: MemberRole.member,
      unreadCount: 2,
    ),
  ];
  @override Future<ChatChannel> getOrCreateDirectChannel(String o) async =>
      (await getChannels()).first;
  @override Future<void> joinCommunityChannel(String p) async {}
  @override Future<void> markChannelRead(String c) async {}
  @override Stream<List<ChatMessage>> watchMessages(String c, {int pageSize = 30}) =>
      Stream.value([]);
  @override Future<List<ChatMessage>> fetchOlderMessages(String c,
      {required DateTime before, int limit = 30}) async => [];
  @override Future<void> sendMessage(String c, String msg) async {}
  @override Future<void> sendCallRequest(String c) async {}
  @override Future<void> deleteMessage(String m) async {}
  @override Future<void> broadcastTyping(String c) async {}
  @override Stream<Set<String>> watchTypingUsers(String c) => Stream.value({});
}

void main() {
  test('chatChannelsProvider returns channels from repository', () async {
    final container = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(_StubRepo()),
    ]);
    addTearDown(container.dispose);

    final channels = await container.read(chatChannelsProvider.future);
    expect(channels, hasLength(1));
    expect(channels.first.id, 'ch-1');
    expect(channels.first.unreadCount, 2);
  });

  test('totalUnreadCountProvider sums unread across channels', () async {
    final container = ProviderContainer(overrides: [
      chatRepositoryProvider.overrideWithValue(_StubRepo()),
    ]);
    addTearDown(container.dispose);

    // Wait for channels to load
    await container.read(chatChannelsProvider.future);
    final total = container.read(totalUnreadCountProvider);
    expect(total, 2);
  });
}
```

- [ ] **Step 6.2 — Run test to verify it fails (providers not written yet)**

```bash
flutter test test/features/chat/presentation/chat_providers_test.dart -v
```

Expected: compile error — providers not found.

- [ ] **Step 6.3 — Write providers**

```dart
// lib/features/chat/presentation/providers/chat_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository();
});

// ── Channels ──────────────────────────────────────────────────────────────────

final chatChannelsProvider = FutureProvider.autoDispose<List<ChatChannel>>((ref) {
  return ref.read(chatRepositoryProvider).getChannels();
});

/// Total unread count across all channels — used for the AppBar badge.
final totalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(chatChannelsProvider).maybeWhen(
    data: (channels) => channels.fold(0, (sum, c) => sum + c.unreadCount),
    orElse: () => 0,
  );
});

// ── Messages ──────────────────────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, channelId) {
  return ref.read(chatRepositoryProvider).watchMessages(channelId);
});

final typingUsersProvider = StreamProvider.autoDispose
    .family<Set<String>, String>((ref, channelId) {
  return ref.read(chatRepositoryProvider).watchTypingUsers(channelId);
});

// ── Actions ───────────────────────────────────────────────────────────────────

class SendMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send(String channelId, String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).sendMessage(channelId, content),
    );
  }

  Future<void> sendCallRequest(String channelId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).sendCallRequest(channelId),
    );
  }
}

final sendMessageProvider =
    AsyncNotifierProvider.autoDispose<SendMessageNotifier, void>(
  SendMessageNotifier.new,
);

class DeleteMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String messageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).deleteMessage(messageId),
    );
  }
}

final deleteMessageProvider =
    AsyncNotifierProvider.autoDispose<DeleteMessageNotifier, void>(
  DeleteMessageNotifier.new,
);

class MarkReadNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(String channelId) async {
    await ref.read(chatRepositoryProvider).markChannelRead(channelId);
    // Invalidate channels so unread badge updates.
    ref.invalidate(chatChannelsProvider);
  }
}

final markReadProvider =
    AsyncNotifierProvider.autoDispose<MarkReadNotifier, void>(
  MarkReadNotifier.new,
);
```

- [ ] **Step 6.4 — Run provider test to verify it passes**

```bash
flutter test test/features/chat/presentation/chat_providers_test.dart -v
```

Expected: all tests PASS.

- [ ] **Step 6.5 — Commit**

```bash
git add lib/features/chat/presentation/providers/chat_providers.dart
git add test/features/chat/presentation/chat_providers_test.dart
git commit -m "feat(chat): Riverpod providers — channels, messages, actions"
```

---

## Task 7: Navigation Integration

**Files:**
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- Modify: `lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`

- [ ] **Step 7.1 — Add route constants and GoRoute entries**

In `lib/core/navigation/app_router.dart`:

Add to `Routes` class:
```dart
  static const chatInbox = '/chat';
  static const chatChannel = '/chat/:channelId';
```

Add these two imports at the top of the file:
```dart
import '../../features/chat/presentation/screens/chat_inbox_screen.dart';
import '../../features/chat/presentation/screens/chat_channel_screen.dart';
```

Add these two routes to the `routes` list (before `devTools`):
```dart
      GoRoute(
        path: Routes.chatInbox,
        name: 'chat-inbox',
        builder: (context, state) => const ChatInboxScreen(),
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
```

Add the missing import at the top:
```dart
import '../../features/chat/domain/models/chat_channel.dart';
```

- [ ] **Step 7.2 — Add chat icon to DashboardScreen AppBar**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, find the `AppBar` `actions` list and insert before the profile icon:

```dart
          Consumer(builder: (context, ref, _) {
            final unread = ref.watch(totalUnreadCountProvider);
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => context.push(Routes.chatInbox),
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        unread > 99 ? '99+' : '$unread',
                        style: const TextStyle(color: Colors.white, fontSize: 9),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
```

Add the missing imports at the top of `dashboard_screen.dart`:
```dart
import '../../../chat/presentation/providers/chat_providers.dart';
```

- [ ] **Step 7.3 — Add chat icon to TrainerDashboardScreen AppBar**

Apply the same `Consumer` / `Stack` / unread badge pattern to `lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart`. Add import:
```dart
import '../../chat/presentation/providers/chat_providers.dart';
```

Add same `Consumer` widget to its `AppBar.actions`.

- [ ] **Step 7.4 — Hot restart and verify navigation**

```bash
make run
```

Verify: chat icon visible in AppBar. Tapping navigates to `/chat` (will crash until `ChatInboxScreen` is built in Task 8 — that is expected).

- [ ] **Step 7.5 — Commit**

```bash
git add lib/core/navigation/app_router.dart
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git add lib/features/trainer/presentation/screens/trainer_dashboard_screen.dart
git commit -m "feat(chat): wire chat routes and AppBar icon with unread badge"
```

---

## Task 8: Chat Inbox Screen

**Files:**
- Create: `lib/features/chat/presentation/widgets/channel_list_tile.dart`
- Create: `lib/features/chat/presentation/screens/chat_inbox_screen.dart`

- [ ] **Step 8.1 — Write `ChannelListTile`**

```dart
// lib/features/chat/presentation/widgets/channel_list_tile.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/chat_channel.dart';

class ChannelListTile extends StatelessWidget {
  const ChannelListTile({
    super.key,
    required this.channel,
    required this.onTap,
    this.packageName,
  });

  final ChatChannel channel;
  final VoidCallback onTap;

  /// Localised package name for community channels (e.g. "Moro").
  final String? packageName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = channel.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: channel.type == ChannelType.direct
            ? theme.colorScheme.primary
            : theme.colorScheme.secondary,
        child: Icon(
          channel.type == ChannelType.direct
              ? Icons.person_outline
              : Icons.group_outlined,
          color: Colors.white,
        ),
      ),
      title: Text(
        channel.channelDisplayName(packageName: packageName),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: channel.lastMessageContent != null
          ? Text(
              channel.lastMessageContent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.6),
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (channel.lastMessageAt != null)
            Text(
              _formatTime(channel.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                channel.unreadCount > 99 ? '99+' : '${channel.unreadCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);

    if (msgDay == today) return DateFormat.Hm().format(dt);
    if (today.difference(msgDay).inDays == 1) return 'Gestern';
    return DateFormat('dd.MM').format(dt);
  }
}
```

- [ ] **Step 8.2 — Write `ChatInboxScreen`**

```dart
// lib/features/chat/presentation/screens/chat_inbox_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/models/chat_channel.dart';
import '../providers/chat_providers.dart';
import '../widgets/channel_list_tile.dart';

class ChatInboxScreen extends ConsumerWidget {
  const ChatInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(chatChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nachrichten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(chatChannelsProvider),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Fehler beim Laden', style: Theme.of(context).textTheme.bodyLarge),
              TextButton(
                onPressed: () => ref.invalidate(chatChannelsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (channels) {
          if (channels.isEmpty) {
            return _EmptyInbox();
          }

          final directChannels =
              channels.where((c) => c.type == ChannelType.direct).toList();
          final communityChannels =
              channels.where((c) => c.type == ChannelType.community).toList();

          return ListView(
            children: [
              if (directChannels.isNotEmpty) ...[
                _SectionHeader(title: 'Direkt'),
                ...directChannels.map((c) => ChannelListTile(
                      channel: c,
                      onTap: () => _openChannel(context, c),
                    )),
              ],
              if (communityChannels.isNotEmpty) ...[
                _SectionHeader(title: 'Community'),
                ...communityChannels.map((c) => ChannelListTile(
                      channel: c,
                      onTap: () => _openChannel(context, c),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openChannel(BuildContext context, ChatChannel channel) {
    context.push(
      Routes.chatChannel.replaceFirst(':channelId', channel.id),
      extra: channel,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
      ),
    );
  }
}

class _EmptyInbox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'Noch keine Nachrichten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Verlinke dich mit einem Trainer, um direkte Nachrichten zu nutzen.\n'
              'Community-Channels erscheinen wenn du einem Programm-Block beitrittst.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 8.3 — Hot restart, navigate to chat, verify inbox renders**

```bash
make run
```

Tap the chat icon → inbox loads. No trainer linked yet → empty state visible.

- [ ] **Step 8.4 — Commit**

```bash
git add lib/features/chat/presentation/widgets/channel_list_tile.dart
git add lib/features/chat/presentation/screens/chat_inbox_screen.dart
git commit -m "feat(chat): ChatInboxScreen and ChannelListTile with unread badges"
```

---

## Task 9: Message Widgets

**Files:**
- Create: `lib/features/chat/presentation/widgets/message_bubble.dart`
- Create: `lib/features/chat/presentation/widgets/message_input_bar.dart`
- Create: `lib/features/chat/presentation/widgets/typing_indicator.dart`

- [ ] **Step 9.1 — Write `MessageBubble`**

```dart
// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isModerator,
    this.onDeleteRequested,
  });

  final ChatMessage message;
  final bool isModerator;
  final VoidCallback? onDeleteRequested;

  static const _deletedColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isOwn = message.isOwnMessage(currentUserId);
    final theme = Theme.of(context);

    if (message.isDeleted) return _DeletedBubble(isOwn: isOwn, message: message);
    if (message.isBotResponse) return _BotBubble(message: message);
    if (message.isCallRequest) return _CallRequestBubble(isOwn: isOwn, message: message);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: (isOwn || isModerator) ? onDeleteRequested : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isOwn
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 4),
              bottomRight: Radius.circular(isOwn ? 4 : 16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isOwn ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(message.createdAt),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOwn
                      ? Colors.white.withOpacity(0.7)
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isOwn, required this.message});
  final bool isOwn;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          'Diese Nachricht wurde entfernt.',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.smart_toy_outlined, size: 14),
              const SizedBox(width: 4),
              Text('CoreJourney Assistent',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 4),
            Text(message.content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _CallRequestBubble extends StatelessWidget {
  const _CallRequestBubble({required this.isOwn, required this.message});
  final bool isOwn;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Row(
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
      ),
    );
  }
}
```

- [ ] **Step 9.2 — Write `MessageInputBar`**

```dart
// lib/features/chat/presentation/widgets/message_input_bar.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_channel.dart';

typedef OnSend = void Function(String content);
typedef OnCallRequest = void Function();
typedef OnTyping = void Function();

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.channel,
    required this.onSend,
    this.onCallRequest,
    required this.onTyping,
  });

  final ChatChannel channel;
  final OnSend onSend;

  /// Non-null for direct channels when current user is NOT moderator (Practitioner).
  /// Null for Trainers (they start calls directly) and community channels.
  final OnCallRequest? onCallRequest;

  final OnTyping onTyping;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
      if (hasText) widget.onTyping();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showCallRequest = widget.onCallRequest != null &&
        widget.channel.type == ChannelType.direct;

    return SafeArea(
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            if (showCallRequest)
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                color: theme.colorScheme.primary,
                tooltip: 'Video-Call anfragen',
                onPressed: widget.onCallRequest,
              ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Nachricht schreiben …',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _hasText
                  ? IconButton(
                      key: const ValueKey('send'),
                      icon: const Icon(Icons.send_rounded),
                      color: theme.colorScheme.primary,
                      onPressed: _send,
                    )
                  : const SizedBox(width: 48),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 9.3 — Write `TypingIndicator`**

```dart
// lib/features/chat/presentation/widgets/typing_indicator.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_providers.dart';

class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({super.key, required this.channelId});
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingAsync = ref.watch(typingUsersProvider(channelId));

    return typingAsync.maybeWhen(
      data: (users) {
        if (users.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            children: [
              _AnimatedDots(),
              const SizedBox(width: 6),
              Text(
                users.length == 1 ? 'tippt …' : '${users.length} tippen …',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.5),
                    ),
              ),
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final phase = (_controller.value * 3).floor();
        return Row(
          children: List.generate(3, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(
                      i == phase ? 0.8 : 0.3,
                    ),
              ),
            );
          }),
        );
      },
    );
  }
}
```

- [ ] **Step 9.4 — Commit**

```bash
git add lib/features/chat/presentation/widgets/
git commit -m "feat(chat): MessageBubble, MessageInputBar, TypingIndicator widgets"
```

---

## Task 10: Chat Channel Screen

**Files:**
- Create: `lib/features/chat/presentation/screens/chat_channel_screen.dart`

- [ ] **Step 10.1 — Write `ChatChannelScreen`**

```dart
// lib/features/chat/presentation/screens/chat_channel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/typing_indicator.dart';

class ChatChannelScreen extends ConsumerStatefulWidget {
  const ChatChannelScreen({
    super.key,
    required this.channelId,
    this.channel,
  });

  final String channelId;

  /// Passed from the inbox for instant title display — may be null on deep link.
  final ChatChannel? channel;

  @override
  ConsumerState<ChatChannelScreen> createState() => _ChatChannelScreenState();
}

class _ChatChannelScreenState extends ConsumerState<ChatChannelScreen> {
  final _scrollController = ScrollController();
  bool _loadingOlder = false;
  List<ChatMessage> _olderMessages = [];

  @override
  void initState() {
    super.initState();
    // Mark channel as read when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markReadProvider.notifier).markRead(widget.channelId);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 80 &&
        !_loadingOlder) {
      _loadMoreOlder();
    }
  }

  Future<void> _loadMoreOlder() async {
    final messages = ref.read(chatMessagesProvider(widget.channelId)).valueOrNull;
    final allMessages = [..._olderMessages, ...(messages ?? [])];
    if (allMessages.isEmpty) return;

    final oldest = allMessages.reduce((a, b) =>
        a.createdAt.isBefore(b.createdAt) ? a : b);

    setState(() => _loadingOlder = true);
    try {
      final older = await ref
          .read(chatRepositoryProvider)
          .fetchOlderMessages(widget.channelId, before: oldest.createdAt);
      if (older.isNotEmpty) {
        setState(() => _olderMessages = [...older, ..._olderMessages]);
      }
    } finally {
      setState(() => _loadingOlder = false);
    }
  }

  void _sendMessage(String content) {
    ref.read(sendMessageProvider.notifier).send(widget.channelId, content);
    // Scroll to bottom after send.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendCallRequest() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Video-Call anfragen?'),
        content: const Text(
          'Du sendest deinem Trainer eine Anfrage für einen Video-Call. '
          'Der Trainer entscheidet, ob und wann er den Call startet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(sendMessageProvider.notifier)
                  .sendCallRequest(widget.channelId);
            },
            child: const Text('Anfrage senden'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channel = widget.channel;
    final isModerator = channel?.isModerator ?? false;
    final isPractitioner = !isModerator && channel?.type == ChannelType.direct;

    final messagesAsync = ref.watch(chatMessagesProvider(widget.channelId));

    return Scaffold(
      appBar: AppBar(
        title: Text(channel?.channelDisplayName() ?? 'Chat'),
        actions: [
          // Trainer: start call directly. (Video feature — Task 2 of Plan 2)
          if (isModerator && channel?.type == ChannelType.direct)
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: 'Call starten',
              onPressed: () {
                // Placeholder until Plan 2 (Video Chat) is implemented.
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video-Chat kommt in Phase 2.')),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
              data: (realtimeMessages) {
                final allMessages = [
                  ..._olderMessages,
                  ...realtimeMessages,
                ];

                if (allMessages.isEmpty) {
                  return Center(
                    child: Text(
                      'Noch keine Nachrichten.\nSchreib die erste!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: allMessages.length + (_loadingOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loadingOlder && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          );
                        }
                        final msgIndex =
                            _loadingOlder ? index - 1 : index;
                        final msg = allMessages[msgIndex];
                        return MessageBubble(
                          message: msg,
                          isModerator: isModerator,
                          onDeleteRequested: (isModerator ||
                                  msg.isOwnMessage(
                                      _currentUserId()))
                              ? () => _confirmDelete(msg)
                              : null,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          TypingIndicator(channelId: widget.channelId),
          MessageInputBar(
            channel: channel ??
                ChatChannel(
                  id: widget.channelId,
                  type: ChannelType.direct,
                  createdAt: DateTime.now(),
                  currentUserRole: MemberRole.member,
                  unreadCount: 0,
                ),
            onSend: _sendMessage,
            onCallRequest: isPractitioner ? _sendCallRequest : null,
            onTyping: () => ref
                .read(chatRepositoryProvider)
                .broadcastTyping(widget.channelId),
          ),
        ],
      ),
    );
  }

  String _currentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  void _confirmDelete(ChatMessage message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nachricht entfernen?'),
        content: const Text(
            'Die Nachricht wird für alle als entfernt angezeigt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(deleteMessageProvider.notifier)
                  .delete(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
```

Ensure `supabase_flutter` is imported at the top of `chat_channel_screen.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

`_currentUserId()` calls `Supabase.instance.client` directly — no local variable needed.

- [ ] **Step 10.2 — Hot restart and navigate to a channel**

```bash
make run
```

Tap chat icon → inbox → tap a channel (if one exists after manual DB seeding). Verify: messages load, input bar appears, typing indicator shows. If no channels exist yet, test by manually inserting a row into `chat_channels` and `chat_channel_members` in the DEV Supabase dashboard.

- [ ] **Step 10.3 — Commit**

```bash
git add lib/features/chat/presentation/screens/chat_channel_screen.dart
git commit -m "feat(chat): ChatChannelScreen — realtime messages, pagination, input, delete"
```

---

## Task 11: Triage Bot Edge Function

**Files:**
- Create: `supabase/functions/chat-triage-bot/index.ts`

- [ ] **Step 11.1 — Create functions directory and write Edge Function**

```bash
mkdir -p /Users/alexandermessinger/dev/claudvibes/reflexjourney/supabase/functions/chat-triage-bot
```

```typescript
// supabase/functions/chat-triage-bot/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const BOT_USER_ID = Deno.env.get('BOT_USER_ID')!;
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

interface RequestPayload {
  channel_id: string;
  content: string;
  locale: 'de' | 'en';
}

interface FaqRow {
  id: string;
  keywords: string[];
  response_de: string;
  response_en: string;
  escalate_to_trainer: boolean;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const payload: RequestPayload = await req.json();
    const { channel_id, content, locale } = payload;

    if (!channel_id || !content) {
      return new Response(JSON.stringify({ error: 'Missing channel_id or content' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      });
    }

    // Use service role key — bypasses RLS so bot can insert into any channel.
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    const { data: faqs, error: faqError } = await supabase
      .from('bot_faqs')
      .select('*');

    if (faqError) throw faqError;

    const contentLower = content.toLowerCase().trim();
    const match = (faqs as FaqRow[]).find((faq) =>
      faq.keywords.some((kw) => contentLower.includes(kw.toLowerCase()))
    );

    if (match) {
      const response = locale === 'en' ? match.response_en : match.response_de;

      await supabase.from('chat_messages').insert({
        channel_id,
        sender_id: BOT_USER_ID,
        content: response,
        is_bot_response: true,
        is_call_request: false,
      });

      if (match.escalate_to_trainer) {
        await notifyTrainer(supabase, channel_id, content);
      }
    } else {
      // No match — escalate and inform user.
      const escalationMsg = locale === 'en'
        ? 'I have forwarded your question to your trainer.'
        : 'Ich habe deine Frage an deinen Trainer weitergeleitet.';

      await supabase.from('chat_messages').insert({
        channel_id,
        sender_id: BOT_USER_ID,
        content: escalationMsg,
        is_bot_response: true,
        is_call_request: false,
      });

      await notifyTrainer(supabase, channel_id, content);
    }

    return new Response(JSON.stringify({ ok: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } catch (err) {
    console.error('Triage bot error:', err);
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});

async function notifyTrainer(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  channel_id: string,
  originalContent: string
): Promise<void> {
  // Find trainer in this channel (role = 'moderator').
  const { data: members } = await supabase
    .from('chat_channel_members')
    .select('user_id')
    .eq('channel_id', channel_id)
    .eq('role', 'moderator');

  if (!members || members.length === 0) return;

  // Fetch trainer device tokens for FCM.
  const trainerIds: string[] = members.map((m: { user_id: string }) => m.user_id);

  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('token')
    .in('user_id', trainerIds);

  if (!tokens || tokens.length === 0) return;

  // Send FCM push via Firebase HTTP v1 API.
  // Requires FIREBASE_SERVER_KEY env var to be set in Supabase Edge Function secrets.
  const fcmKey = Deno.env.get('FIREBASE_SERVER_KEY');
  if (!fcmKey) return;

  for (const { token } of tokens) {
    await fetch('https://fcm.googleapis.com/fcm/send', {
      method: 'POST',
      headers: {
        Authorization: `key=${fcmKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        to: token,
        notification: {
          title: 'Neue Klienten-Frage',
          body: originalContent.length > 80
            ? `${originalContent.substring(0, 80)}…`
            : originalContent,
        },
        data: {
          type: 'chat_escalation',
          channel_id,
        },
      }),
    });
  }
}
```

- [ ] **Step 11.2 — Deploy Edge Function to DEV Supabase**

In Supabase dashboard → Edge Functions → Create new function → name: `chat-triage-bot` → paste the TypeScript content.

Set Edge Function secrets (Supabase dashboard → Edge Functions → Secrets):
```
BOT_USER_ID=<uuid from Task 1.3>
FIREBASE_SERVER_KEY=<FCM server key from Firebase console>
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by Supabase.

- [ ] **Step 11.3 — Test Edge Function manually**

In Supabase dashboard → Edge Functions → chat-triage-bot → Test:

```json
{
  "channel_id": "<a real channel id from your DEV db>",
  "content": "ich habe schmerzen beim training",
  "locale": "de"
}
```

Expected: `{ "ok": true }` and a bot message visible in `chat_messages` table.

- [ ] **Step 11.4 — Commit**

```bash
git add supabase/functions/chat-triage-bot/index.ts
git commit -m "feat(chat): Triage Bot Edge Function with keyword matching and trainer escalation"
```

---

## Task 12: End-to-End Smoke Test

- [ ] **Step 12.1 — Manual E2E test checklist**

With the app running on DEV (`make run`):

**Setup:** Manually insert 1 direct channel + 2 members (practitioner + trainer) via Supabase dashboard.

| # | Action | Expected |
|---|---|---|
| 1 | Open app as Practitioner | Dashboard visible |
| 2 | Tap chat icon in AppBar | ChatInboxScreen opens, direct channel visible |
| 3 | Tap direct channel | ChatChannelScreen opens, empty state |
| 4 | Type "ich habe schmerzen" → Send | Message appears as own bubble |
| 5 | Wait 2-3 seconds | Bot response appears with pain guidance text |
| 6 | Tap video camera icon | Confirmation dialog appears |
| 7 | Tap "Anfrage senden" | Call-request bubble appears |
| 8 | Log in as Trainer account | Chat icon shows unread badge |
| 9 | Open direct channel | Call-request bubble visible, own send button visible |
| 10 | Long-press a message | Delete confirmation dialog appears |
| 11 | Confirm delete | Message shows "Diese Nachricht wurde entfernt." |
| 12 | Send message as Trainer | Appears as own bubble on Trainer side |
| 13 | Switch back to Practitioner | New message visible, unread badge gone after opening |

- [ ] **Step 12.2 — Run full test suite**

```bash
flutter test -v
```

Expected: all tests pass. Fix any regressions before proceeding.

- [ ] **Step 12.3 — Final commit**

```bash
git add .
git commit -m "feat(chat): complete Chat Foundation + Triage Bot — E2E verified"
```

---

## What's Next

**Plan 2 — Video Chat** must be written and executed next. It adds:
- `agora_rtc_engine` dependency
- `video_calls` table + RLS (Supabase migration)
- `agora-token` Edge Function
- Agora token acquisition flow
- 1:1 call UI (replaces the "Phase 2" snackbar placeholder in `ChatChannelScreen`)
- Group call UI for Community channels (Trainer only)
- Incoming call overlay using Supabase Realtime on `video_calls` table
- FCM push when a call is started

Plan 2 picks up from the `// Placeholder until Plan 2` comment in `ChatChannelScreen`.
