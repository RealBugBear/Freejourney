import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/entitlement.dart';

enum RedeemAccessCodeError {
  invalidCode,
  alreadyRedeemed,
  expired,
  unsupported,
  unauthorized,
  unknown,
}

RedeemAccessCodeError mapRedeemAccessCodeError(String? code) => switch (code) {
      'invalid_code' => RedeemAccessCodeError.invalidCode,
      'already_redeemed' => RedeemAccessCodeError.alreadyRedeemed,
      'expired_code' => RedeemAccessCodeError.expired,
      'unsupported_code_type' => RedeemAccessCodeError.unsupported,
      'unauthorized' => RedeemAccessCodeError.unauthorized,
      _ => RedeemAccessCodeError.unknown,
    };

class RedeemAccessCodeException implements Exception {
  RedeemAccessCodeException(this.error);

  final RedeemAccessCodeError error;
}

/// Liest den Premium-Status aus `profiles` — mit SharedPreferences-Cache,
/// damit die Offline-first-App auch ohne Netz einen letzten bekannten
/// Stand hat. Default ist immer [Entitlement.none] (fail-closed: im
/// Zweifel kein Premium; mit kPaywallEnabled=false irrelevant, weil die
/// Unlock-Logik das Entitlement dann gar nicht befragt).
class PremiumRepository {
  PremiumRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static String _cacheKey(String userId) => 'entitlement_cache_$userId';

  Future<Entitlement> getEntitlement() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return Entitlement.none;

    try {
      final row = await _client
          .from('profiles')
          .select('is_premium, premium_type, premium_valid_until')
          .eq('id', userId)
          .maybeSingle();
      if (row == null) return Entitlement.none;
      final entitlement = Entitlement.fromProfileRow(row);
      await _prefs.setString(
        _cacheKey(userId),
        jsonEncode(entitlement.toCacheJson()),
      );
      return entitlement;
    } catch (_) {
      return _readCache(userId) ?? Entitlement.none;
    }
  }

  Entitlement? _readCache(String userId) {
    final raw = _prefs.getString(_cacheKey(userId));
    if (raw == null) return null;
    try {
      return Entitlement.fromProfileRow(
        (jsonDecode(raw) as Map).cast<String, dynamic>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> redeemAccessCode(String code) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw RedeemAccessCodeException(RedeemAccessCodeError.unauthorized);
    }

    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw RedeemAccessCodeException(RedeemAccessCodeError.invalidCode);
    }

    final session = _client.auth.currentSession;
    final response = await _client.functions.invoke(
      'redeem-access-code',
      body: {'code': normalized},
      headers: {
        if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status >= 400) {
      final data = response.data;
      final errorCode =
          data is Map ? data['error']?.toString() : response.status.toString();
      throw RedeemAccessCodeException(mapRedeemAccessCodeError(errorCode));
    }
  }
}
