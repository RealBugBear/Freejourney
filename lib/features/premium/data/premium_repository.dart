import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entitlement.dart';

enum RedeemAccessCodeError {
  invalidCode,
  alreadyRedeemed,
  expired,
  unsupported,
  campaignInactive,
  roleNotEligible,
  redemptionLimitReached,
  offerUnavailable,
  invalidPlatform,
  benefitCodeSecretMissing,
  unauthorized,
  unknown,
}

RedeemAccessCodeError mapRedeemAccessCodeError(String? code) => switch (code) {
      'invalid_code' => RedeemAccessCodeError.invalidCode,
      'already_redeemed' => RedeemAccessCodeError.alreadyRedeemed,
      'expired_code' => RedeemAccessCodeError.expired,
      'unsupported_code_type' => RedeemAccessCodeError.unsupported,
      'campaign_inactive' => RedeemAccessCodeError.campaignInactive,
      'role_not_eligible' => RedeemAccessCodeError.roleNotEligible,
      'redemption_limit_reached' =>
        RedeemAccessCodeError.redemptionLimitReached,
      'offer_unavailable' => RedeemAccessCodeError.offerUnavailable,
      'invalid_platform' => RedeemAccessCodeError.invalidPlatform,
      'benefit_code_secret_missing' =>
        RedeemAccessCodeError.benefitCodeSecretMissing,
      'unauthorized' => RedeemAccessCodeError.unauthorized,
      _ => RedeemAccessCodeError.unknown,
    };

class RedeemAccessCodeException implements Exception {
  RedeemAccessCodeException(this.error);

  final RedeemAccessCodeError error;
}

enum BenefitKind {
  internalGrant,
  storeOffer,
  unknown;

  static BenefitKind fromApi(String? value) => switch (value) {
        'internal_grant' || 'grant' || 'legacy' => BenefitKind.internalGrant,
        'store_offer' || 'offer' => BenefitKind.storeOffer,
        _ => BenefitKind.unknown,
      };
}

/// Structured success response for both legacy founder codes and new benefit
/// campaigns. Store offers deliberately report [grantsAccess] as false: the
/// store flow must complete before the app may claim entitlement access.
class RedeemAccessCodeResult {
  const RedeemAccessCodeResult({
    required this.benefitKind,
    this.entitlementKey,
    this.expiresAt,
    this.isPermanent = false,
    this.appleOfferRef,
    this.googleOfferRef,
    this.grantOrigin,
    this.grantId,
    this.redeemedAt,
    this.isLegacyResponse = false,
  });

  const RedeemAccessCodeResult.legacy()
      : benefitKind = BenefitKind.internalGrant,
        entitlementKey = EntitlementKey.premium,
        expiresAt = null,
        isPermanent = true,
        appleOfferRef = null,
        googleOfferRef = null,
        grantOrigin = GrantOrigin.benefitCode,
        grantId = null,
        redeemedAt = null,
        isLegacyResponse = true;

  final BenefitKind benefitKind;
  final EntitlementKey? entitlementKey;
  final DateTime? expiresAt;
  final bool isPermanent;
  final String? appleOfferRef;
  final String? googleOfferRef;
  final GrantOrigin? grantOrigin;
  final String? grantId;
  final DateTime? redeemedAt;
  final bool isLegacyResponse;

  bool get grantsAccess =>
      benefitKind == BenefitKind.internalGrant &&
      entitlementKey != null &&
      (isPermanent ? expiresAt == null : expiresAt != null);

  String? offerReferenceFor(TargetPlatform platform) => switch (platform) {
        TargetPlatform.iOS => appleOfferRef,
        TargetPlatform.android => googleOfferRef,
        _ => null,
      };

  factory RedeemAccessCodeResult.fromResponse(dynamic response) {
    if (response is! Map) {
      return const RedeemAccessCodeResult(benefitKind: BenefitKind.unknown);
    }

    final envelope = response.cast<String, dynamic>();
    var json = envelope;
    final nestedData = envelope['data'];
    if (nestedData is Map) json = nestedData.cast<String, dynamic>();

    if (envelope['success'] != true) {
      return const RedeemAccessCodeResult(benefitKind: BenefitKind.unknown);
    }

    // T24 returned `{success: true, data: {success: true,
    // premium_type: code, ...}}`. Only that recognizable shape gets the
    // compatibility result; malformed 2xx responses fail closed.
    if (!json.containsKey('benefit_kind')) {
      final isLegacySuccess = json['success'] == true &&
          json['premium_type'] == 'code' &&
          _parseDate(json['redeemed_at']) != null;
      return isLegacySuccess
          ? const RedeemAccessCodeResult.legacy()
          : const RedeemAccessCodeResult(benefitKind: BenefitKind.unknown);
    }

    final benefitKind = BenefitKind.fromApi(json['benefit_kind']?.toString());
    final entitlementKey =
        EntitlementKey.fromDb(json['entitlement_key']?.toString());
    final permanentValue = json['is_permanent'];
    final expiresValue = json['expires_at'];
    final expiresAt = _parseDate(expiresValue);
    final offer = json['offer'];
    String? appleOfferRef = _nonEmptyString(json['apple_offer_ref']);
    String? googleOfferRef = _nonEmptyString(json['google_offer_ref']);
    if (offer is Map) {
      final offerJson = offer.cast<String, dynamic>();
      final reference = _nonEmptyString(
        offerJson['reference'] ?? offerJson['offer_ref'],
      );
      switch (offerJson['platform']?.toString()) {
        case 'ios':
        case 'app_store':
          appleOfferRef ??= reference;
        case 'android':
        case 'play_store':
          googleOfferRef ??= reference;
      }
    }

    final hasCanonicalBaseShape = (json['benefit_kind'] == 'internal_grant' ||
            json['benefit_kind'] == 'store_offer') &&
        entitlementKey != null &&
        permanentValue is bool &&
        json.containsKey('expires_at');
    final hasValidBenefitShape = switch (benefitKind) {
      BenefitKind.internalGrant => hasCanonicalBaseShape &&
          (permanentValue == true ? expiresValue == null : expiresAt != null),
      BenefitKind.storeOffer => hasCanonicalBaseShape &&
          permanentValue == false &&
          expiresValue == null &&
          (appleOfferRef != null || googleOfferRef != null),
      BenefitKind.unknown => false,
    };
    if (!hasValidBenefitShape) {
      return const RedeemAccessCodeResult(benefitKind: BenefitKind.unknown);
    }

    return RedeemAccessCodeResult(
      benefitKind: benefitKind,
      entitlementKey: entitlementKey,
      expiresAt: expiresAt,
      isPermanent: permanentValue as bool,
      appleOfferRef: appleOfferRef,
      googleOfferRef: googleOfferRef,
      grantOrigin: json['source'] == null
          ? null
          : GrantOrigin.fromDb(json['source']?.toString()),
      grantId: _nonEmptyString(json['grant_id']),
      redeemedAt: _parseDate(json['redeemed_at']),
    );
  }
}

String? _nonEmptyString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _parseDate(dynamic value) => switch (value) {
      DateTime date => date,
      String text => DateTime.tryParse(text),
      _ => null,
    };

String paidPlatformFor(TargetPlatform platform) => switch (platform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => 'unknown',
    };

/// Reads effective account entitlements from the server ledger. The legacy
/// [getEntitlement] API remains available for all T23 callers.
///
/// SharedPreferences is only a bounded convenience cache: no snapshot is
/// trusted for more than 72 hours and a time-limited grant is never active
/// after its own expiry. Server-side authorization remains authoritative.
class PremiumRepository {
  PremiumRepository(
    this._client,
    this._prefs, {
    DateTime Function()? now,
    String? platform,
  })  : _now = now ?? DateTime.now,
        _platform = platform ?? paidPlatformFor(defaultTargetPlatform);

  final SupabaseClient _client;
  final SharedPreferences _prefs;
  final DateTime Function() _now;
  final String _platform;

  static String _cacheKey(String userId) =>
      'effective_entitlements_cache_v2_$userId';

  Future<Entitlement> getEntitlement() async {
    final entitlements = await getEffectiveEntitlements();
    return entitlements.premium.toLegacyPremium();
  }

  Future<AccountEntitlements> getEffectiveEntitlements() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return AccountEntitlements.none;

    try {
      final response = await _client.rpc('get_my_effective_entitlements');
      final entitlements =
          AccountEntitlements.fromRpc(response).evaluatedAt(_now());
      await _writeCache(userId, entitlements);
      return entitlements;
    } catch (error) {
      // During the additive rollout, an older backend may not have the RPC
      // yet. Only that explicit case falls back to the existing T23 profile
      // projection; network failures use the bounded cache immediately.
      if (_isMissingRpc(error)) {
        final legacy = await _readLegacyProfile(userId);
        if (legacy != null) return legacy;
      }
      return _readCache(userId) ?? AccountEntitlements.none;
    }
  }

  Future<AccountEntitlements?> _readLegacyProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select('is_premium, premium_type, premium_valid_until')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return AccountEntitlements.none;
      final legacy = Entitlement.fromProfileRow(row);
      final result = AccountEntitlements(
        premium: EffectiveEntitlement.fromLegacy(legacy),
        studio: EffectiveEntitlement.studioNone,
      ).evaluatedAt(_now());
      await _writeCache(userId, result);
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    String userId,
    AccountEntitlements entitlements,
  ) async {
    final cached = CachedAccountEntitlements(
      verifiedAt: _now(),
      entitlements: entitlements,
    );
    await _prefs.setString(_cacheKey(userId), jsonEncode(cached.toJson()));
  }

  AccountEntitlements? _readCache(String userId) {
    final raw = _prefs.getString(_cacheKey(userId));
    if (raw == null) return null;
    try {
      final cached = CachedAccountEntitlements.fromJson(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
      return cached.readAt(_now());
    } catch (_) {
      return null;
    }
  }

  Future<PaidRollouts> getPaidRollouts() async {
    try {
      final response = await _client.rpc(
        'get_paid_rollout',
        params: {'p_platform': _platform},
      );
      return PaidRollouts.fromRpc(response);
    } catch (_) {
      // Safe default blocks new sales but does not revoke valid access.
      return PaidRollouts.safeDefault;
    }
  }

  Future<RedeemAccessCodeResult> redeemAccessCode(String code) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw RedeemAccessCodeException(RedeemAccessCodeError.unauthorized);
    }

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw RedeemAccessCodeException(RedeemAccessCodeError.invalidCode);
    }

    try {
      final response = await _client.functions.invoke(
        'redeem-access-code',
        body: {'code': normalized, 'platform': _platform},
      );

      // functions_client currently throws FunctionException for non-2xx, but
      // retain this branch so a future transport behavior cannot bypass the
      // same stable domain-error mapping.
      if (response.status >= 400) {
        throw RedeemAccessCodeException(
          _mapFunctionFailure(response.status, response.data),
        );
      }
      return RedeemAccessCodeResult.fromResponse(response.data);
    } on FunctionException catch (error) {
      throw RedeemAccessCodeException(
        _mapFunctionFailure(error.status, error.details),
      );
    }
  }
}

RedeemAccessCodeError _mapFunctionFailure(int status, dynamic details) {
  final errorCode = details is Map ? details['error']?.toString() : null;
  if (errorCode == null && status == 401) {
    return RedeemAccessCodeError.unauthorized;
  }
  return mapRedeemAccessCodeError(errorCode);
}

bool _isMissingRpc(Object error) {
  if (error is! PostgrestException) return false;
  return error.code == 'PGRST202' || error.code == '42883';
}
