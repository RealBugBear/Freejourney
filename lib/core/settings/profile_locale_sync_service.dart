import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_languages.dart';
import '../logging/app_logger.dart';

abstract interface class ProfileLocaleSyncService {
  Future<void> syncLocale({
    required String userId,
    required String languageCode,
  });
}

class SupabaseProfileLocaleSyncService implements ProfileLocaleSyncService {
  const SupabaseProfileLocaleSyncService(this._client);

  final SupabaseClient _client;

  @override
  Future<void> syncLocale({
    required String userId,
    required String languageCode,
  }) async {
    // The registry owns the fallback policy; `profiles.locale` only ever
    // receives a code the app actually supports. Region subtags ("en-US")
    // are reduced to the language subtag first.
    final locale = AppLanguages.normalize(
      languageCode.toLowerCase().split(RegExp('[-_]')).first,
    );

    try {
      await _client
          .from('profiles')
          .update({'locale': locale}).eq('id', userId);
    } catch (error, stackTrace) {
      // Locale sync must never block language selection or sign-in. The local
      // setting remains authoritative until the next auth/settings refresh.
      appLogger.w(
        'Profile locale sync failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final profileLocaleSyncServiceProvider = Provider<ProfileLocaleSyncService>(
  (ref) => SupabaseProfileLocaleSyncService(Supabase.instance.client),
);
