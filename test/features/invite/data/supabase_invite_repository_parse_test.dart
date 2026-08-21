import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/data/repositories/supabase_invite_repository.dart';
import 'package:corejourney/features/invite/domain/models/invite_redeem_result.dart';

void main() {
  test('redeem result is read from object payload', () {
    final map = unwrapInviteRpcPayload({'result': 'already_referred'});
    expect(
      InviteRedeemResult.fromRpc(map['result'] as String?),
      InviteRedeemResult.alreadyReferred,
    );
  });

  test('list-wrapped jsonb payload is unwrapped', () {
    final map = unwrapInviteRpcPayload([
      {'code': 'ABCD2345', 'activated_count': 0},
    ]);
    expect(map['code'], 'ABCD2345');
  });

  test('empty or scalar payload throws FormatException', () {
    expect(() => unwrapInviteRpcPayload(<dynamic>[]), throwsFormatException);
    expect(() => unwrapInviteRpcPayload('nope'), throwsFormatException);
  });
}
