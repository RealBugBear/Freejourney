import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/domain/models/invite_overview.dart';
import 'package:corejourney/features/invite/domain/models/invite_redeem_result.dart';
import 'package:corejourney/features/invite/domain/repositories/invite_repository.dart';
import 'package:corejourney/features/invite/presentation/providers/invite_providers.dart';

class _FakeInviteRepository implements InviteRepository {
  _FakeInviteRepository({
    required this.overview,
    this.redeemResult = InviteRedeemResult.accepted,
  });

  InviteOverview overview;
  InviteRedeemResult redeemResult;
  int overviewCalls = 0;
  int redeemCalls = 0;
  int shareCalls = 0;
  int landingCalls = 0;
  String? lastRedeemCode;
  String? lastLandingCode;

  @override
  Future<InviteOverview> getMyInviteOverview() async {
    overviewCalls++;
    return overview;
  }

  @override
  Future<InviteRedeemResult> redeemInviteCode(String code) async {
    redeemCalls++;
    lastRedeemCode = code;
    return redeemResult;
  }

  @override
  Future<void> logShareActionTapped() async {
    shareCalls++;
  }

  @override
  Future<void> logLandingView(String code) async {
    landingCalls++;
    lastLandingCode = code;
  }
}

ProviderContainer _container(_FakeInviteRepository fake) {
  return ProviderContainer(
    overrides: [
      inviteRepositoryProvider.overrideWithValue(fake),
    ],
  );
}

void main() {
  test('inviteOverviewProvider returns overview from repository', () async {
    final fake = _FakeInviteRepository(
      overview: const InviteOverview(code: 'ABCD2345', activatedCount: 1),
    );
    final container = _container(fake);
    addTearDown(container.dispose);

    final overview = await container.read(inviteOverviewProvider.future);

    expect(overview.code, 'ABCD2345');
    expect(overview.activatedCount, 1);
    expect(fake.overviewCalls, 1);
  });

  test('inviteActionsProvider redeem forwards code and result', () async {
    final fake = _FakeInviteRepository(
      overview: const InviteOverview(code: 'ABCD2345', activatedCount: 0),
      redeemResult: InviteRedeemResult.ownCode,
    );
    final container = _container(fake);
    addTearDown(container.dispose);

    final result =
        await container.read(inviteActionsProvider.notifier).redeem('OWNCODE1');

    expect(result, InviteRedeemResult.ownCode);
    expect(fake.redeemCalls, 1);
    expect(fake.lastRedeemCode, 'OWNCODE1');
  });

  test('inviteActionsProvider logs share and landing', () async {
    final fake = _FakeInviteRepository(
      overview: const InviteOverview(code: 'ABCD2345', activatedCount: 0),
    );
    final container = _container(fake);
    addTearDown(container.dispose);

    final actions = container.read(inviteActionsProvider.notifier);
    await actions.logShareActionTapped();
    await actions.logLandingView('LANDING1');

    expect(fake.shareCalls, 1);
    expect(fake.landingCalls, 1);
    expect(fake.lastLandingCode, 'LANDING1');
  });
}
