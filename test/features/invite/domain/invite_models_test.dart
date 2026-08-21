import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/domain/models/invite_overview.dart';
import 'package:corejourney/features/invite/domain/models/invite_redeem_result.dart';

void main() {
  group('InviteOverview.fromJson', () {
    test('parses code and activated_count', () {
      final overview = InviteOverview.fromJson({
        'code': 'ABCD2345',
        'activated_count': 3,
      });
      expect(overview.code, 'ABCD2345');
      expect(overview.activatedCount, 3);
    });

    test('accepts whole numeric activated_count from jsonb', () {
      final overview = InviteOverview.fromJson({
        'code': 'ABCD2345',
        'activated_count': 2.0,
      });
      expect(overview.activatedCount, 2);
    });

    test('rejects invalid code shape', () {
      expect(
        () => InviteOverview.fromJson({
          'code': 'bad',
          'activated_count': 0,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => InviteOverview.fromJson({
          'code': 'IIIIIIII', // I is outside the alphabet
          'activated_count': 0,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects negative and fractional activated_count', () {
      expect(
        () => InviteOverview.fromJson({
          'code': 'ABCD2345',
          'activated_count': -1,
        }),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => InviteOverview.fromJson({
          'code': 'ABCD2345',
          'activated_count': 2.5,
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws when code missing', () {
      expect(
        () => InviteOverview.fromJson({'activated_count': 0}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('InviteRedeemResult.fromRpc', () {
    test('maps every known result value', () {
      expect(
        InviteRedeemResult.fromRpc('accepted'),
        InviteRedeemResult.accepted,
      );
      expect(
        InviteRedeemResult.fromRpc('unknown_code'),
        InviteRedeemResult.unknownCode,
      );
      expect(
        InviteRedeemResult.fromRpc('code_inactive'),
        InviteRedeemResult.codeInactive,
      );
      expect(
        InviteRedeemResult.fromRpc('own_code'),
        InviteRedeemResult.ownCode,
      );
      expect(
        InviteRedeemResult.fromRpc('already_referred'),
        InviteRedeemResult.alreadyReferred,
      );
      expect(
        InviteRedeemResult.fromRpc('account_too_old'),
        InviteRedeemResult.accountTooOld,
      );
    });

    test('null or unknown values throw FormatException', () {
      expect(
        () => InviteRedeemResult.fromRpc(null),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => InviteRedeemResult.fromRpc('weird'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
