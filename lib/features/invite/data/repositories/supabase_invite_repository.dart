import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/invite_overview.dart';
import '../../domain/models/invite_redeem_result.dart';
import '../../domain/repositories/invite_repository.dart';

class SupabaseInviteRepository implements InviteRepository {
  SupabaseInviteRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<InviteOverview> getMyInviteOverview() async {
    final res = await _client.rpc('get_my_invite_overview');
    final map = unwrapInviteRpcPayload(res);
    return InviteOverview.fromJson(map);
  }

  @override
  Future<InviteRedeemResult> redeemInviteCode(String code) async {
    final res = await _client.rpc(
      'redeem_invite_code',
      params: {'p_code': code},
    );
    final map = unwrapInviteRpcPayload(res);
    return InviteRedeemResult.fromRpc(map['result'] as String?);
  }

  @override
  Future<void> logShareActionTapped() async {
    await _client.rpc('log_invite_share_action_tapped');
  }

  @override
  Future<void> logLandingView(String code) async {
    await _client.rpc(
      'log_invite_landing_view',
      params: {'p_code': code},
    );
  }
}

/// Shared jsonb unwrap for invite RPCs — tested directly by unit tests.
Map<String, dynamic> unwrapInviteRpcPayload(dynamic res) {
  return switch (res) {
    final Map<String, dynamic> map => map,
    final Map map => Map<String, dynamic>.from(map),
    final List list when list.isNotEmpty =>
      Map<String, dynamic>.from(list.first as Map),
    _ => throw FormatException('Unexpected invite RPC payload: $res'),
  };
}
