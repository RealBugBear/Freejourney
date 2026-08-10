# Navigation Restructure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Die App-Shell auf 3+1 konditionelle Tabs umbauen, navigatorische Sackgassen schließen, Community und DM als eigenständige Shell-Bereiche etablieren.

**Architecture:** Shell-first — zuerst Navigation und Routing reparieren, dann Content. Alle Channel-Screens laufen als Shell-Children (Bottom-Nav bleibt sichtbar). DM-Tab erscheint nur wenn Trainer verknüpft.

**Tech Stack:** Flutter, GoRouter, Riverpod, Supabase

---

## File Map

| Status | Datei | Was ändert sich |
|--------|-------|-----------------|
| Modify | `lib/features/trainer/presentation/providers/trainer_provider.dart` | `trainerLinkedProvider` hinzufügen |
| Modify | `lib/features/chat/presentation/providers/chat_providers.dart` | `unreadDmCountProvider` hinzufügen (nur direct channels) |
| Modify | `lib/core/navigation/app_router.dart` | Neue Route-Konstanten, Shell-Routen umbauen |
| Modify | `lib/core/navigation/app_shell.dart` | 3+1 Tabs, dynamische Tab-Liste, DM-Badge, route-basierter Index |
| Create | `lib/features/community/presentation/screens/community_screen.dart` | Neuer Placeholder-Screen |
| Create | `lib/features/chat/presentation/screens/dm_screen.dart` | DM-Inbox (nur direct channels) |
| Modify | `lib/features/trainer/presentation/screens/appointment_proposal_screen.dart` | Pop nach Bestätigung |
| Modify | `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | JournalCard, ProgramCard, ModeSelector entfernen; AppBar aufräumen |
| Delete route | `/chat`, `/mood/history` aus Router | Aus Shell und standalone entfernen |

---

## Task 1: `trainerLinkedProvider` + `unreadDmCountProvider`

**Files:**
- Modify: `lib/features/trainer/presentation/providers/trainer_provider.dart`
- Modify: `lib/features/chat/presentation/providers/chat_providers.dart`
- Test: `test/features/trainer/trainer_provider_test.dart`

- [ ] **Step 1: Test schreiben — trainerLinkedProvider false wenn kein Trainer**

```dart
// test/features/trainer/trainer_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';

void main() {
  test('trainerLinkedProvider is false when clientTrainerProvider is null', () {
    final container = ProviderContainer(
      overrides: [
        clientTrainerProvider.overrideWith((ref) => Future.value(null)),
      ],
    );
    addTearDown(container.dispose);
    // Initially loading → false (default)
    expect(container.read(trainerLinkedProvider), false);
  });

  test('trainerLinkedProvider is true when clientTrainerProvider has a name', () async {
    final container = ProviderContainer(
      overrides: [
        clientTrainerProvider.overrideWith((ref) => Future.value('Max Trainer')),
      ],
    );
    addTearDown(container.dispose);
    await container.read(clientTrainerProvider.future);
    expect(container.read(trainerLinkedProvider), true);
  });
}
```

- [ ] **Step 2: Test ausführen — sicherstellen dass er fehlschlägt**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/trainer/trainer_provider_test.dart -v
```

Erwartet: FAIL mit "trainerLinkedProvider not found"

- [ ] **Step 3: `trainerLinkedProvider` implementieren**

Am Ende von `lib/features/trainer/presentation/providers/trainer_provider.dart` hinzufügen (nach `subscriptionTierProvider`):

```dart
// ── Trainer linked (bool) ─────────────────────────────────────────────────────

/// True wenn der aktuelle User einen aktiv verknüpften Trainer hat.
/// Leitet sich von clientTrainerProvider ab — kein extra DB-Call.
final trainerLinkedProvider = Provider<bool>((ref) {
  return ref.watch(clientTrainerProvider).valueOrNull != null;
});
```

- [ ] **Step 4: `unreadDmCountProvider` in chat_providers.dart hinzufügen**

In `lib/features/chat/presentation/providers/chat_providers.dart` nach `totalUnreadCountProvider` einfügen:

```dart
/// Ungelesene Nachrichten nur in Direct-Channels (für DM-Tab-Badge).
final unreadDmCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(chatChannelsProvider).maybeWhen(
        data: (channels) => channels
            .where((c) => c.type == ChannelType.direct)
            .fold(0, (sum, c) => sum + c.unreadCount),
        orElse: () => 0,
      );
});
```

- [ ] **Step 5: Test ausführen — sicherstellen dass er besteht**

```bash
flutter test test/features/trainer/trainer_provider_test.dart -v
```

Erwartet: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/trainer/presentation/providers/trainer_provider.dart \
        lib/features/chat/presentation/providers/chat_providers.dart \
        test/features/trainer/trainer_provider_test.dart
git commit -m "feat: add trainerLinkedProvider and unreadDmCountProvider"
```

---

## Task 2: Route-Konstanten erweitern

**Files:**
- Modify: `lib/core/navigation/app_router.dart` (nur die `Routes`-Klasse)

- [ ] **Step 1: Neue Konstanten in `Routes` hinzufügen**

In `lib/core/navigation/app_router.dart` die `Routes`-Klasse erweitern. Die alten `chatInbox` und `chatChannel` Konstanten bleiben vorerst (werden in Task 8 entfernt):

```dart
class Routes {
  // bestehende Konstanten unverändert lassen, folgende hinzufügen:
  static const community = '/community';
  static const communityChannel = '/community/:channelId';
  static const dm = '/dm';
  static const dmChannel = '/dm/:channelId';
}
```

- [ ] **Step 2: Compile-Check**

```bash
flutter analyze lib/core/navigation/app_router.dart
```

Erwartet: keine Fehler

- [ ] **Step 3: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat: add community and dm route constants"
```

---

## Task 3: `AppShell` umbauen

**Files:**
- Modify: `lib/core/navigation/app_shell.dart`
- Test: `test/core/navigation/app_shell_test.dart`

- [ ] **Step 1: Test schreiben — 3 Tabs ohne Trainer**

```dart
// test/core/navigation/app_shell_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/core/navigation/app_shell.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

Widget _wrap(Widget child, {bool trainerLinked = false, int unreadDm = 0}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (_, __, c) => AppShell(child: c),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/community', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/dm', builder: (_, __) => const Scaffold()),
          GoRoute(path: '/profile', builder: (_, __) => const Scaffold()),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      trainerLinkedProvider.overrideWithValue(trainerLinked),
      unreadDmCountProvider.overrideWithValue(unreadDm),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows 3 tabs when no trainer linked', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(), trainerLinked: false));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 3);
  });

  testWidgets('shows 4 tabs when trainer linked', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(), trainerLinked: true));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 4);
  });

  testWidgets('DM tab shows badge when unread > 0', (tester) async {
    await tester.pumpWidget(_wrap(const SizedBox(), trainerLinked: true, unreadDm: 3));
    await tester.pumpAndSettle();
    expect(find.byType(Badge), findsWidgets);
  });
}
```

- [ ] **Step 2: Test ausführen — sicherstellen dass er fehlschlägt**

```bash
flutter test test/core/navigation/app_shell_test.dart -v
```

Erwartet: FAIL (AppShell hat noch alten Code)

- [ ] **Step 3: `AppShell` neu implementieren**

`lib/core/navigation/app_shell.dart` vollständig ersetzen:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/chat/presentation/providers/chat_providers.dart';
import '../../features/trainer/presentation/providers/trainer_provider.dart';
import 'app_router.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  List<String> _buildTabRoutes(bool trainerLinked) => [
        Routes.dashboard,
        Routes.community,
        if (trainerLinked) Routes.dm,
        Routes.profile,
      ];

  int _currentIndex(BuildContext context, List<String> tabRoutes) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < tabRoutes.length; i++) {
      if (location.startsWith(tabRoutes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trainerLinked = ref.watch(trainerLinkedProvider);
    final unreadDm = ref.watch(unreadDmCountProvider);
    final tabRoutes = _buildTabRoutes(trainerLinked);
    final currentIndex = _currentIndex(context, tabRoutes);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => context.go(tabRoutes[index]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Community',
          ),
          if (trainerLinked)
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadDm > 0,
                label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadDm > 0,
                label: unreadDm > 99 ? const Text('99+') : Text('$unreadDm'),
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

- [ ] **Step 4: Test ausführen**

```bash
flutter test test/core/navigation/app_shell_test.dart -v
```

Erwartet: PASS (3 Tests grün)

- [ ] **Step 5: Commit**

```bash
git add lib/core/navigation/app_shell.dart test/core/navigation/app_shell_test.dart
git commit -m "feat: rebuild AppShell with 3+1 conditional tabs and DM badge"
```

---

## Task 4: Router — neue Shell-Routen hinzufügen

**Files:**
- Modify: `lib/core/navigation/app_router.dart`

- [ ] **Step 1: Imports hinzufügen**

In `lib/core/navigation/app_router.dart` nach den bestehenden Imports einfügen:

```dart
import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/chat/presentation/screens/dm_screen.dart';
```

- [ ] **Step 2: Neue Shell-Routen einfügen**

Im `ShellRoute` — nach dem `/dashboard`-Eintrag und vor `/profile` — die neuen Routen einfügen. Den `/packages`-Eintrag aus dem ShellRoute entfernen. Den `/chat`-Eintrag mit seinen Kindern durch die neuen Einträge ersetzen:

```dart
// ENTFERNEN aus ShellRoute:
//   GoRoute(path: Routes.packages, ...)
//   GoRoute(path: Routes.chatInbox, ... routes: [ GoRoute(parentNavigatorKey: ...) ])

// HINZUFÜGEN in ShellRoute (nach /dashboard, vor /profile):

GoRoute(
  path: Routes.community,
  name: 'community',
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: const CommunityScreen(),
  ),
  routes: [
    GoRoute(
      path: ':channelId',
      name: 'community-channel',
      builder: (context, state) {
        final channelId = state.pathParameters['channelId']!;
        final channel = state.extra as ChatChannel?;
        return ChatChannelScreen(channelId: channelId, channel: channel);
      },
    ),
  ],
),
GoRoute(
  path: Routes.dm,
  name: 'dm',
  pageBuilder: (context, state) => NoTransitionPage(
    key: state.pageKey,
    child: const DmScreen(),
  ),
  routes: [
    GoRoute(
      path: ':channelId',
      name: 'dm-channel',
      builder: (context, state) {
        final channelId = state.pathParameters['channelId']!;
        final channel = state.extra as ChatChannel?;
        return ChatChannelScreen(channelId: channelId, channel: channel);
      },
    ),
  ],
),
```

- [ ] **Step 3: App kompiliert ohne Fehler**

```bash
flutter analyze lib/core/navigation/app_router.dart
```

Erwartet: keine Fehler (CommunityScreen und DmScreen fehlen noch — wenn ja, erst Task 5+6 ausführen, dann zurückkehren)

- [ ] **Step 4: Commit (nach Task 5+6 wenn nötig)**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat: add community and dm shell routes, remove packages from shell"
```

---

## Task 5: `CommunityScreen` erstellen

**Files:**
- Create: `lib/features/community/presentation/screens/community_screen.dart`
- Test: `test/features/community/community_screen_test.dart`

- [ ] **Step 1: Test schreiben**

```dart
// test/features/community/community_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/community/presentation/screens/community_screen.dart';

void main() {
  testWidgets('CommunityScreen renders placeholder', (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const CommunityScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Community'), findsOneWidget);
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
  });
}
```

- [ ] **Step 2: Test ausführen — sicherstellen dass er fehlschlägt**

```bash
flutter test test/features/community/community_screen_test.dart -v
```

Erwartet: FAIL (Datei existiert nicht)

- [ ] **Step 3: Verzeichnis und Screen anlegen**

```bash
mkdir -p /Users/alexandermessinger/dev/claudvibes/reflexjourney/lib/features/community/presentation/screens
```

`lib/features/community/presentation/screens/community_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.groups_outlined,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25),
              ),
              const SizedBox(height: 16),
              Text(
                'Community',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Hier entsteht bald deine Community.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Test ausführen**

```bash
flutter test test/features/community/community_screen_test.dart -v
```

Erwartet: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/community/ test/features/community/
git commit -m "feat: add CommunityScreen placeholder"
```

---

## Task 6: `DmScreen` erstellen

**Files:**
- Create: `lib/features/chat/presentation/screens/dm_screen.dart`
- Test: `test/features/chat/dm_screen_test.dart`

- [ ] **Step 1: Test schreiben**

```dart
// test/features/chat/dm_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/chat/presentation/screens/dm_screen.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';
import 'package:corejourney/features/chat/domain/models/chat_channel.dart';

ChatChannel _directChannel(String id) => ChatChannel(
      id: id,
      type: ChannelType.direct,
      createdAt: DateTime(2026),
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );

ChatChannel _communityChannel(String id) => ChatChannel(
      id: id,
      type: ChannelType.community,
      packageId: 'moro',
      createdAt: DateTime(2026),
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );

Widget _wrap(List<ChatChannel> channels) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, __) => const DmScreen())],
  );
  return ProviderScope(
    overrides: [
      chatChannelsProvider.overrideWith(
        (_) => Future.value(channels),
      ),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('shows only direct channels', (tester) async {
    final channels = [
      _directChannel('dm-1'),
      _communityChannel('comm-1'),
    ];
    await tester.pumpWidget(_wrap(channels));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('shows empty state when no direct channels', (tester) async {
    await tester.pumpWidget(_wrap([_communityChannel('comm-1')]));
    await tester.pumpAndSettle();
    expect(find.text('Noch keine Nachrichten'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Test ausführen — sicherstellen dass er fehlschlägt**

```bash
flutter test test/features/chat/dm_screen_test.dart -v
```

Erwartet: FAIL (DmScreen existiert nicht)

- [ ] **Step 3: `DmScreen` implementieren**

`lib/features/chat/presentation/screens/dm_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../domain/models/chat_channel.dart';
import '../providers/chat_providers.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class DmScreen extends ConsumerWidget {
  const DmScreen({super.key});

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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(chatChannelsProvider),
        ),
        data: (channels) {
          final direct =
              channels.where((c) => c.type == ChannelType.direct).toList();
          if (direct.isEmpty) return const _EmptyState();
          return ListView.builder(
            itemCount: direct.length,
            itemBuilder: (ctx, i) => _DmListTile(
              channel: direct[i],
              onTap: () => context.push(
                '/dm/${direct[i].id}',
                extra: direct[i],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DmListTile extends ConsumerWidget {
  const _DmListTile({required this.channel, required this.onTap});
  final ChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasUnread = channel.unreadCount > 0;
    final title = ref.watch(chatPartnerNameProvider(channel.id)).valueOrNull ??
        channel.channelDisplayName();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.person_outline, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
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
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : null,
      trailing: channel.lastMessageAt != null
          ? Text(
              _formatTime(channel.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            )
          : null,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.25)),
              const SizedBox(height: 16),
              Text('Noch keine Nachrichten',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Hier erscheinen deine direkten Nachrichten mit deinem Trainer.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 8),
            Text('Fehler beim Laden',
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            TextButton(
                onPressed: onRetry, child: const Text('Erneut versuchen')),
          ],
        ),
      );
}
```

- [ ] **Step 4: Test ausführen**

```bash
flutter test test/features/chat/dm_screen_test.dart -v
```

Erwartet: PASS (2 Tests grün)

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/presentation/screens/dm_screen.dart \
        test/features/chat/dm_screen_test.dart
git commit -m "feat: add DmScreen showing only direct channels"
```

---

## Task 7: Router-Kompilierung sichern (Task 4 abschließen)

Falls in Task 4 nicht bereits abgeschlossen:

- [ ] **Step 1: Analyze ausführen**

```bash
flutter analyze lib/core/navigation/app_router.dart
```

Erwartet: keine Fehler

- [ ] **Step 2: App starten und Navigation testen**

```bash
make run
```

Manuell prüfen:
- 3 Tabs sichtbar (kein Trainer verknüpft im Dev-Account)
- Community-Tab öffnet Placeholder-Screen
- Community-Tab: Settings-Icon oben rechts führt zu Settings
- Profil-Tab weiterhin erreichbar
- Alte Packages/Chat-Tabs verschwunden

- [ ] **Step 3: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat: migrate router to community/dm shell routes"
```

---

## Task 8: `AppointmentProposalScreen` — Dead-End fixen

**Files:**
- Modify: `lib/features/trainer/presentation/screens/appointment_proposal_screen.dart:99-116`

- [ ] **Step 1: Nach `widget.onConfirmed()` Navigation hinzufügen**

In `_AppointmentProposalCardState._confirm()` — direkt nach `widget.onConfirmed()` und dem SnackBar-Block — hinzufügen:

```dart
// Bestehender Code (Zeilen ~99–116):
      widget.onConfirmed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin bestätigt!')),
        );
      }
// HINZUFÜGEN danach:
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.dm);
        }
      }
```

Der vollständige `try`-Block in `_confirm` sieht danach so aus:

```dart
    try {
      await confirmProposedSlot(widget.proposal.id, _chosen!);

      if (mounted) {
        final add = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Zum Kalender hinzufügen?'),
            content: Text(
              'Soll der Termin am ${DateFormat('E, d. MMM – HH:mm', 'de_DE').format(_chosen!)} in deinen Kalender eingetragen werden?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nein'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ja, hinzufügen'),
              ),
            ],
          ),
        );
        if (add == true && mounted) await _addToCalendar();
      }

      widget.onConfirmed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin bestätigt!')),
        );
      }
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.dm);
        }
      }
    } catch (e) {
```

- [ ] **Step 2: Import sicherstellen**

Oben in der Datei muss vorhanden sein:
```dart
import 'package:go_router/go_router.dart';
import '../../../../core/navigation/app_router.dart';
```

Falls nicht vorhanden, hinzufügen.

- [ ] **Step 3: Analyze**

```bash
flutter analyze lib/features/trainer/presentation/screens/appointment_proposal_screen.dart
```

Erwartet: keine Fehler

- [ ] **Step 4: Commit**

```bash
git add lib/features/trainer/presentation/screens/appointment_proposal_screen.dart
git commit -m "fix: pop AppointmentProposalScreen after confirming slot"
```

---

## Task 9: Alte Routes aufräumen

**Files:**
- Modify: `lib/core/navigation/app_router.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

- [ ] **Step 1: `/mood/history` Route aus Router entfernen**

In `app_router.dart` den folgenden Block vollständig entfernen:

```dart
GoRoute(
  path: Routes.moodHistory,
  name: 'mood-history',
  builder: (context, state) => const MoodHistoryScreen(),
),
```

Den Import `import '../../features/mood/presentation/screens/mood_history_screen.dart';` ebenfalls entfernen wenn er nach dem Entfernen des GoRoute ungenutzt ist.

- [ ] **Step 2: `Routes.chatInbox` und `Routes.chatChannel` Konstanten entfernen**

In der `Routes`-Klasse:
```dart
// ENTFERNEN:
static const chatInbox = '/chat';
static const chatChannel = '/chat/:channelId';
```

Falls `chatInbox` oder `chatChannel` noch anderswo referenziert werden:

```bash
grep -r "chatInbox\|chatChannel\|Routes.chat" \
  /Users/alexandermessinger/dev/claudvibes/reflexjourney/lib --include="*.dart"
```

Alle gefundenen Stellen auf `/dm` bzw. `/dm/:channelId` oder `/community/:channelId` aktualisieren.

- [ ] **Step 3: Analyze ausführen**

```bash
flutter analyze lib/core/navigation/
```

Erwartet: keine Fehler

- [ ] **Step 4: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "chore: remove obsolete chat and mood-history routes"
```

---

## Task 10: Dashboard aufräumen

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

Hinweis: Der Dashboard-Screen ist groß. Lies ihn zuerst vollständig mit dem Read-Tool bevor du Änderungen machst.

- [ ] **Step 1: `dashboard_screen.dart` vollständig lesen**

```
Read: lib/features/dashboard/presentation/screens/dashboard_screen.dart
```

- [ ] **Step 2: `JournalCard`-Widget und dessen Aufruf entfernen**

Alle Widget-Definitionen und Aufrufe für `JournalCard` / journal-bezogene Cards entfernen. Den Import `journal_provider.dart` entfernen wenn danach ungenutzt.

- [ ] **Step 3: `ProgramCard`-Widget und dessen Aufruf entfernen**

Alle Widget-Definitionen und Aufrufe für `ProgramCard` / program-bezogene Cards entfernen.

- [ ] **Step 4: `ModeSelector`-Widget und dessen Aufruf entfernen**

Den Training-Mode-Selektor aus dem Dashboard entfernen. Er wandert später in Settings (separater Task außerhalb dieses Plans).

- [ ] **Step 5: AppBar-Shortcuts aufräumen**

Im Dashboard-AppBar: Profile-Icon-Button entfernen (gibt jetzt einen Tab dafür). Settings-Shortcut durch das Gear-Icon ersetzen:

```dart
AppBar(
  // title bleibt wie bisher
  actions: [
    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Einstellungen',
      onPressed: () => context.push(Routes.settings),
    ),
  ],
)
```

- [ ] **Step 6: Mood-Chart Platz geben**

Sicherstellen dass der `MoodChartWidget`-Container kein festes `height`-Constraint hat das ihn unnötig klein macht. Wenn ein festes `height` gesetzt ist: auf `null` oder einen flexiblen Wert (z.B. `MediaQuery.of(context).size.height * 0.35`) ändern, damit der Chart mehr Raum bekommt ohne Scrolling zu erzwingen.

- [ ] **Step 7: Analyze ausführen**

```bash
flutter analyze lib/features/dashboard/
```

Erwartet: keine Fehler

- [ ] **Step 8: App starten und Dashboard prüfen**

```bash
make run
```

Manuell prüfen:
- Kein JournalCard sichtbar
- Kein ProgramCard sichtbar
- Kein ModeSelector sichtbar
- Mood-Diagramm sichtbar ohne Scrollen
- Training-CTA sichtbar
- Gear-Icon in AppBar führt zu Settings

- [ ] **Step 9: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat: clean up dashboard — remove JournalCard, ProgramCard, ModeSelector"
```

---

## Abschluss-Smoke-Test

- [ ] App starten: `make run`
- [ ] Ohne Trainer: 3 Tabs sichtbar (Home, Community, Profil)
- [ ] Community-Tab: Placeholder-Screen mit Settings-Icon
- [ ] Profil-Tab: erreichbar, keine Dopplung mit AppBar
- [ ] Settings via Gear-Icon: von Home, Community und Profil aus erreichbar
- [ ] Training starten von Home: funktioniert, Bottom-Nav verschwindet während Session
- [ ] Nach Bestätigung eines Termins: landet auf DM-Tab, nicht auf leerem Screen
- [ ] Analyse sauber: `flutter analyze lib/`
