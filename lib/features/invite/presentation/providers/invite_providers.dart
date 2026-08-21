import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_invite_repository.dart';
import '../../domain/models/invite_overview.dart';
import '../../domain/models/invite_redeem_result.dart';
import '../../domain/repositories/invite_repository.dart';

final inviteRepositoryProvider = Provider<InviteRepository>(
  (ref) => SupabaseInviteRepository(Supabase.instance.client),
);

/// Personal invite code + activated count. Refreshes on auth changes.
final inviteOverviewProvider = FutureProvider<InviteOverview>((ref) async {
  ref.watch(authStateProvider);
  return ref.read(inviteRepositoryProvider).getMyInviteOverview();
});

/// Thin notifier for redeem / share / landing actions used by later UI phases.
class InviteActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<InviteRedeemResult> redeem(String code) {
    return ref.read(inviteRepositoryProvider).redeemInviteCode(code);
  }

  Future<void> logShareActionTapped() {
    return ref.read(inviteRepositoryProvider).logShareActionTapped();
  }

  Future<void> logLandingView(String code) {
    return ref.read(inviteRepositoryProvider).logLandingView(code);
  }
}

final inviteActionsProvider =
    AsyncNotifierProvider<InviteActionsNotifier, void>(
  InviteActionsNotifier.new,
);
