import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'package:corejourney/core/navigation/app_router.dart';
import 'package:corejourney/core/storage/pending_invite_store.dart';
import 'package:corejourney/features/invite/domain/models/invite_redeem_result.dart';
import 'package:corejourney/features/invite/domain/models/invite_overview.dart';
import 'package:corejourney/features/invite/domain/repositories/invite_repository.dart';
import 'package:corejourney/features/invite/presentation/invite_messages.dart';
import 'package:corejourney/features/invite/presentation/providers/invite_providers.dart';
import 'package:corejourney/features/invite/presentation/screens/invite_redeem_screen.dart';
import 'package:corejourney/features/invite/presentation/widgets/invite_confirm_sheet.dart';
import 'package:corejourney/l10n/app_localizations.dart';

class _FakeInviteRepo implements InviteRepository {
  _FakeInviteRepo(this.redeemResult);

  InviteRedeemResult? redeemResult;
  Object? redeemError;
  String? lastCode;
  int redeemCalls = 0;

  @override
  Future<InviteOverview> getMyInviteOverview() async {
    return const InviteOverview(code: 'ABCDEFGH', activatedCount: 0);
  }

  @override
  Future<InviteRedeemResult> redeemInviteCode(String code) async {
    redeemCalls++;
    lastCode = code;
    if (redeemError != null) throw redeemError!;
    return redeemResult!;
  }

  @override
  Future<void> logShareActionTapped() async {}

  @override
  Future<void> logLandingView(String code) async {}
}

Widget _harness({
  required InviteRepository repo,
  String? initialCode,
  bool isOnboarding = false,
}) {
  return ProviderScope(
    overrides: [
      inviteRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: InviteRedeemScreen(
        initialCode: initialCode,
        isOnboarding: isOnboarding,
      ),
    ),
  );
}

Widget _onboardingHarness({required InviteRepository repo}) {
  final router = GoRouter(
    initialLocation: '${Routes.inviteAccept}?onboarding=1',
    routes: [
      GoRoute(
        path: Routes.inviteAccept,
        builder: (context, state) => ProviderScope(
          overrides: [
            inviteRepositoryProvider.overrideWithValue(repo),
          ],
          child: InviteRedeemScreen(
            initialCode: 'ABCDEFGH',
            isOnboarding: true,
          ),
        ),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (_, __) => const Scaffold(body: Text('Dashboard')),
      ),
    ],
  );

  return MaterialApp.router(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('invite_redeem_');
    pendingInviteStore = PendingInviteStore(
      memoryOnly: true,
      clock: () => DateTime.utc(2026, 8, 21, 12),
    );
  });

  tearDown(() {
    pendingInviteStore = PendingInviteStore();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('confirm sheet shows code, benefit, and privacy body',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () =>
                  showInviteConfirmSheet(context, code: 'ABCDEFGH'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(find.text(l10n.inviteConfirmTitle), findsOneWidget);
    expect(find.text('ABCDEFGH'), findsOneWidget);
    expect(find.text(l10n.inviteWhy), findsOneWidget);
    expect(find.text(l10n.inviteConfirmBody), findsOneWidget);
    expect(find.text(l10n.inviteConfirmAccept), findsOneWidget);
    expect(find.text(l10n.inviteConfirmDecline), findsOneWidget);
  });

  testWidgets('confirm sheet scrolls at 200% text scale without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2),
          ),
          child: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () =>
                    showInviteConfirmSheet(context, code: 'ABCDEFGH'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);

    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    await tester.drag(
      find.byType(SingleChildScrollView).first,
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.inviteConfirmDecline), findsOneWidget);
  });

  testWidgets('decline on confirm sheet does not call redeem RPC',
      (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted);
    await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-decline')));
    await tester.pumpAndSettle();

    expect(repo.redeemCalls, 0);
    expect(find.byType(InviteRedeemScreen), findsOneWidget);
  });

  testWidgets('onboarding skip navigates to dashboard', (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted);
    await tester.pumpWidget(_onboardingHarness(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invite-redeem-skip')));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(repo.redeemCalls, 0);
  });

  testWidgets('onboarding decline stays on redeem screen', (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted);
    await tester.pumpWidget(_onboardingHarness(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-decline')));
    await tester.pumpAndSettle();

    expect(find.byType(InviteRedeemScreen), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(repo.redeemCalls, 0);
  });

  testWidgets('redeem shows dedicated message for unknown_code',
      (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.unknownCode);
    await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(InviteRedeemScreen)),
    );
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(repo.lastCode, 'ABCDEFGH');
    expect(find.text(l10n.inviteErrorUnknownCode), findsWidgets);
  });

  testWidgets('network / PostgREST errors show offline message',
      (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted)
      ..redeemError = const PostgrestException(message: 'Failed to fetch');
    await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(InviteRedeemScreen)),
    );
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.inviteErrorOffline), findsWidgets);
    expect(find.text(l10n.inviteErrorUnexpected), findsNothing);
  });

  testWidgets('SocketException shows offline message', (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted)
      ..redeemError = const SocketException('No route to host');
    await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(InviteRedeemScreen)),
    );
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.inviteErrorOffline), findsWidgets);
  });

  testWidgets('FormatException shows unexpected message, not offline',
      (tester) async {
    final repo = _FakeInviteRepo(InviteRedeemResult.accepted)
      ..redeemError = const FormatException('bad contract');
    await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(InviteRedeemScreen)),
    );
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.inviteErrorUnexpected), findsWidgets);
    expect(find.text(l10n.inviteErrorOffline), findsNothing);
  });

  for (final result in [
    InviteRedeemResult.codeInactive,
    InviteRedeemResult.ownCode,
    InviteRedeemResult.alreadyReferred,
    InviteRedeemResult.accountTooOld,
  ]) {
    testWidgets('redeem shows dedicated copy for $result', (tester) async {
      final repo = _FakeInviteRepo(result);
      await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(InviteRedeemScreen)),
      );
      await tester.tap(find.byKey(const Key('invite-redeem-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invite-confirm-accept')));
      await tester.pumpAndSettle();

      final expected = switch (result) {
        InviteRedeemResult.codeInactive => l10n.inviteErrorCodeInactive,
        InviteRedeemResult.ownCode => l10n.inviteErrorOwnCode,
        InviteRedeemResult.alreadyReferred => l10n.inviteErrorAlreadyReferred,
        InviteRedeemResult.accountTooOld => l10n.inviteErrorAccountTooOld,
        _ => fail('unexpected'),
      };
      expect(find.text(expected), findsWidgets);
    });
  }

  testWidgets('terminal non-accepted RPC results clear the pending invite code',
      (tester) async {
    const terminal = [
      InviteRedeemResult.unknownCode,
      InviteRedeemResult.codeInactive,
      InviteRedeemResult.ownCode,
      InviteRedeemResult.alreadyReferred,
      InviteRedeemResult.accountTooOld,
    ];
    for (final result in terminal) {
      await pendingInviteStore.saveCode('ABCDEFGH');
      expect(await pendingInviteStore.readValidCode(), 'ABCDEFGH');

      final repo = _FakeInviteRepo(result);
      await tester.pumpWidget(_harness(repo: repo, initialCode: 'ABCDEFGH'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('invite-redeem-submit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('invite-confirm-accept')));
      await tester.pumpAndSettle();

      expect(
        await pendingInviteStore.readValidCode(),
        isNull,
        reason: 'terminal result $result must clear pending code',
      );
    }
  });

  testWidgets('accepted RPC clears pending code', (tester) async {
    await pendingInviteStore.saveCode('ABCDEFGH');

    final repo = _FakeInviteRepo(InviteRedeemResult.accepted);
    await tester.pumpWidget(_onboardingHarness(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(await pendingInviteStore.readValidCode(), isNull);
  });

  testWidgets('decline and network errors keep the pending invite code',
      (tester) async {
    await pendingInviteStore.saveCode('ABCDEFGH');

    final declineRepo = _FakeInviteRepo(InviteRedeemResult.accepted);
    await tester.pumpWidget(
      _harness(repo: declineRepo, initialCode: 'ABCDEFGH'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-decline')));
    await tester.pumpAndSettle();

    expect(await pendingInviteStore.readValidCode(), 'ABCDEFGH');

    final offlineRepo = _FakeInviteRepo(InviteRedeemResult.accepted)
      ..redeemError = const SocketException('No route to host');
    await tester.pumpWidget(
      _harness(repo: offlineRepo, initialCode: 'ABCDEFGH'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-redeem-submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('invite-confirm-accept')));
    await tester.pumpAndSettle();

    expect(await pendingInviteStore.readValidCode(), 'ABCDEFGH');
  });

  test('inviteRedeemFailureMessage classifies errors', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(
      inviteRedeemFailureMessage(
        l10n,
        const PostgrestException(message: 'down'),
      ),
      l10n.inviteErrorOffline,
    );
    expect(
      inviteRedeemFailureMessage(l10n, const FormatException('drift')),
      l10n.inviteErrorUnexpected,
    );
  });
}
