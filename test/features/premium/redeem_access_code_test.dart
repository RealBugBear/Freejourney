import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/premium/data/premium_repository.dart';

void main() {
  group('mapRedeemAccessCodeError', () {
    test('maps known backend error codes', () {
      expect(
        mapRedeemAccessCodeError('invalid_code'),
        RedeemAccessCodeError.invalidCode,
      );
      expect(
        mapRedeemAccessCodeError('already_redeemed'),
        RedeemAccessCodeError.alreadyRedeemed,
      );
      expect(
        mapRedeemAccessCodeError('expired_code'),
        RedeemAccessCodeError.expired,
      );
      expect(
        mapRedeemAccessCodeError('unsupported_code_type'),
        RedeemAccessCodeError.unsupported,
      );
    });

    test('treats unknown payloads as unknown', () {
      expect(
        mapRedeemAccessCodeError('something_else'),
        RedeemAccessCodeError.unknown,
      );
      expect(
        mapRedeemAccessCodeError(''),
        RedeemAccessCodeError.unknown,
      );
    });
  });
}
