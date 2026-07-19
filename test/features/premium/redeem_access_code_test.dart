import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/premium/data/premium_repository.dart';
import 'package:corejourney/features/premium/domain/entitlement.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockFunctionsClient extends Mock implements FunctionsClient {}

class _MockSharedPreferences extends Mock implements SharedPreferences {}

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
      expect(
        mapRedeemAccessCodeError('campaign_inactive'),
        RedeemAccessCodeError.campaignInactive,
      );
      expect(
        mapRedeemAccessCodeError('role_not_eligible'),
        RedeemAccessCodeError.roleNotEligible,
      );
      expect(
        mapRedeemAccessCodeError('redemption_limit_reached'),
        RedeemAccessCodeError.redemptionLimitReached,
      );
      expect(
        mapRedeemAccessCodeError('offer_unavailable'),
        RedeemAccessCodeError.offerUnavailable,
      );
      expect(
        mapRedeemAccessCodeError('invalid_platform'),
        RedeemAccessCodeError.invalidPlatform,
      );
      expect(
        mapRedeemAccessCodeError('benefit_code_secret_missing'),
        RedeemAccessCodeError.benefitCodeSecretMissing,
      );
      expect(
        mapRedeemAccessCodeError('unauthorized'),
        RedeemAccessCodeError.unauthorized,
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

  group('RedeemAccessCodeResult', () {
    test('keeps the legacy T24 success response as permanent Premium access',
        () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'success': true,
          'premium_type': 'code',
          'redeemed_at': '2026-07-19T10:00:00Z',
        },
      });

      expect(result.isLegacyResponse, isTrue);
      expect(result.benefitKind, BenefitKind.internalGrant);
      expect(result.entitlementKey, EntitlementKey.premium);
      expect(result.isPermanent, isTrue);
      expect(result.grantOrigin, GrantOrigin.benefitCode);
      expect(result.grantsAccess, isTrue);
    });

    test('malformed 2xx response does not claim legacy access', () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': null,
      });

      expect(result.benefitKind, BenefitKind.unknown);
      expect(result.grantsAccess, isFalse);
    });

    test('parses a new time-limited Studio internal grant', () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'internal_grant',
          'entitlement_key': 'studio',
          'expires_at': '2026-09-01T00:00:00Z',
          'is_permanent': false,
          'source': 'pilot',
          'grant_id': '4ab3e285-77c3-4d18-a488-c3aa89f58038',
          'redeemed_at': '2026-07-19T10:00:00Z',
        },
      });

      expect(result.isLegacyResponse, isFalse);
      expect(result.benefitKind, BenefitKind.internalGrant);
      expect(result.entitlementKey, EntitlementKey.studio);
      expect(result.expiresAt, DateTime.utc(2026, 9));
      expect(result.isPermanent, isFalse);
      expect(result.grantOrigin, GrantOrigin.pilot);
      expect(result.grantId, '4ab3e285-77c3-4d18-a488-c3aa89f58038');
      expect(result.redeemedAt, DateTime.utc(2026, 7, 19, 10));
      expect(result.grantsAccess, isTrue);
    });

    test('store offer is structured but never claims access', () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'store_offer',
          'entitlement_key': 'premium',
          'expires_at': null,
          'is_permanent': false,
          'offer': {
            'platform': 'ios',
            'reference': 'apple-offer-reference',
          },
        },
      });

      expect(result.benefitKind, BenefitKind.storeOffer);
      expect(result.grantsAccess, isFalse);
      expect(
        result.offerReferenceFor(TargetPlatform.iOS),
        'apple-offer-reference',
      );
      expect(result.offerReferenceFor(TargetPlatform.android), isNull);
    });

    test('accepts direct Apple and Google offer references', () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'store_offer',
          'entitlement_key': 'studio',
          'expires_at': null,
          'is_permanent': false,
          'apple_offer_ref': 'apple-ref',
          'google_offer_ref': 'google-ref',
        },
      });

      expect(result.appleOfferRef, 'apple-ref');
      expect(result.googleOfferRef, 'google-ref');
      expect(result.grantsAccess, isFalse);
    });

    test('unknown new benefit fails closed', () {
      final result = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'future_kind',
          'entitlement_key': 'premium',
          'expires_at': null,
          'is_permanent': true,
        },
      });

      expect(result.benefitKind, BenefitKind.unknown);
      expect(result.grantsAccess, isFalse);
    });

    test('malformed internal grant shape never claims access', () {
      final missingFiniteExpiry = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'internal_grant',
          'entitlement_key': 'premium',
          'expires_at': 'not-a-timestamp',
          'is_permanent': false,
        },
      });
      final missingKey = RedeemAccessCodeResult.fromResponse({
        'success': true,
        'data': {
          'benefit_kind': 'internal_grant',
          'expires_at': null,
          'is_permanent': true,
        },
      });

      expect(missingFiniteExpiry.benefitKind, BenefitKind.unknown);
      expect(missingFiniteExpiry.grantsAccess, isFalse);
      expect(missingKey.benefitKind, BenefitKind.unknown);
      expect(missingKey.grantsAccess, isFalse);
    });
  });

  test('maps Flutter platforms to the server contract', () {
    expect(paidPlatformFor(TargetPlatform.iOS), 'ios');
    expect(paidPlatformFor(TargetPlatform.android), 'android');
    expect(paidPlatformFor(TargetPlatform.macOS), 'unknown');
  });

  test('maps a thrown non-2xx FunctionException to the domain error', () async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final functions = _MockFunctionsClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.functions).thenReturn(functions);
    when(() => auth.currentUser).thenReturn(
      const User(
        id: '25190000-0000-4000-8000-000000000001',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-07-19T00:00:00Z',
      ),
    );
    when(
      () => functions.invoke(
        any(),
        body: any(named: 'body'),
      ),
    ).thenThrow(
      const FunctionException(
        status: 403,
        details: {'error': 'role_not_eligible'},
      ),
    );

    final repository = PremiumRepository(
      client,
      _MockSharedPreferences(),
      platform: 'ios',
    );

    await expectLater(
      repository.redeemAccessCode(' synthetic-code '),
      throwsA(
        isA<RedeemAccessCodeException>().having(
          (error) => error.error,
          'error',
          RedeemAccessCodeError.roleNotEligible,
        ),
      ),
    );
    verify(
      () => functions.invoke(
        'redeem-access-code',
        body: any(named: 'body'),
      ),
    ).called(1);
  });

  test('delegates refreshed auth headers and maps a thrown 401', () async {
    final client = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    final functions = _MockFunctionsClient();
    when(() => client.auth).thenReturn(auth);
    when(() => client.functions).thenReturn(functions);
    when(() => auth.currentUser).thenReturn(
      const User(
        id: '25190000-0000-4000-8000-000000000001',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2026-07-19T00:00:00Z',
      ),
    );
    when(
      () => functions.invoke(
        any(),
        body: any(named: 'body'),
      ),
    ).thenThrow(const FunctionException(status: 401));

    final repository = PremiumRepository(
      client,
      _MockSharedPreferences(),
      platform: 'ios',
    );

    await expectLater(
      repository.redeemAccessCode('synthetic-code'),
      throwsA(
        isA<RedeemAccessCodeException>().having(
          (error) => error.error,
          'error',
          RedeemAccessCodeError.unauthorized,
        ),
      ),
    );
    verify(
      () => functions.invoke(
        'redeem-access-code',
        body: any(named: 'body'),
      ),
    ).called(1);
  });
}
