import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/settings/settings_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/premium_repository.dart';
import '../../domain/entitlement.dart';
import '../../domain/purchase_service.dart';

final premiumRepositoryProvider = Provider<PremiumRepository>(
  (ref) => PremiumRepository(
    Supabase.instance.client,
    ref.watch(sharedPreferencesProvider),
  ),
);

/// Aktueller Premium-Status des Kontos. Nach einem Kauf/einer Code-Einlösung
/// invalidieren (`ref.invalidate(entitlementProvider)`).
final entitlementProvider = FutureProvider<Entitlement>((ref) {
  ref.watch(authStateProvider);
  return ref.read(premiumRepositoryProvider).getEntitlement();
});

/// Kaufweg — in T23 bewusst der Stub („noch nicht verfügbar“);
/// T25 überschreibt mit der RevenueCat-Implementierung.
final purchaseServiceProvider = Provider<PurchaseService>(
  (ref) => const StubPurchaseService(),
);
