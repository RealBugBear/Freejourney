import '../../../config/launch_flags.dart';
import '../../progress/presentation/providers/progress_provider.dart'
    show freePackageIds, packageOrder;

/// Abo-/Kaufart eines Entitlements — Werte spiegeln den CHECK-Constraint
/// auf `profiles.premium_type` (Migration 2026070701).
enum PremiumType {
  monthly,
  yearly,
  lifetime,

  /// Gründungsnutzer-Freischaltcode (T24).
  code;

  static PremiumType? fromDb(String? value) => switch (value) {
        'monthly' => PremiumType.monthly,
        'yearly' => PremiumType.yearly,
        'lifetime' => PremiumType.lifetime,
        'code' => PremiumType.code,
        _ => null,
      };
}

/// Premium-Status eines Kontos, gelesen aus `profiles` (server-verwaltet —
/// Clients können die Felder wegen `trg_prevent_direct_premium_change`
/// nicht selbst setzen).
class Entitlement {
  const Entitlement({
    required this.isPremium,
    this.type,
    this.validUntil,
  });

  static const none = Entitlement(isPremium: false);

  final bool isPremium;
  final PremiumType? type;
  final DateTime? validUntil;

  /// `lifetime` und `code` laufen nie ab (validUntil = null); bei Abos
  /// entscheidet `premium_valid_until` (Webhook hält is_premium aktuell,
  /// der Client prüft defensiv zusätzlich das Datum).
  bool isActive(DateTime now) {
    if (!isPremium) return false;
    final until = validUntil;
    if (until == null) return true;
    return now.isBefore(until);
  }

  factory Entitlement.fromProfileRow(Map<String, dynamic> row) {
    final validUntilRaw = row['premium_valid_until'] as String?;
    return Entitlement(
      isPremium: row['is_premium'] as bool? ?? false,
      type: PremiumType.fromDb(row['premium_type'] as String?),
      validUntil:
          validUntilRaw != null ? DateTime.tryParse(validUntilRaw) : null,
    );
  }

  Map<String, dynamic> toCacheJson() => {
        'is_premium': isPremium,
        'premium_type': switch (type) {
          PremiumType.monthly => 'monthly',
          PremiumType.yearly => 'yearly',
          PremiumType.lifetime => 'lifetime',
          PremiumType.code => 'code',
          null => null,
        },
        'premium_valid_until': validUntil?.toIso8601String(),
      };
}

/// Zentrale Paket-Freischalt-Logik (T23).
///
/// [paywallEnabled] ist injizierbar, damit beide Zweige testbar sind —
/// im Produktiv-Code läuft immer [kPaywallEnabled] hinein.
///
/// - Paywall AUS → heutiges Launch-Verhalten: [freePackageIds] (die ersten
///   drei Pakete) sind frei, spätere gesperrt.
/// - Paywall AN → nur das erste Paket ([packageOrder].first, Moro) ist frei
///   (Design §3); alles Weitere braucht ein aktives Entitlement.
bool isPackageUnlocked(
  String packageId, {
  required Entitlement entitlement,
  required DateTime now,
  bool paywallEnabled = kPaywallEnabled,
}) {
  if (!paywallEnabled) return freePackageIds.contains(packageId);
  if (packageId == packageOrder.first) return true;
  return entitlement.isActive(now);
}

/// Ziel nach Paket-Abschluss (Design §3: „Paywall-Trigger“).
enum PostCompletionDestination {
  /// Nächstes Paket ist freigeschaltet → direkt in den Trainingsstart.
  trainingStart,

  /// Paywall aktiv und kein Entitlement → Paywall-Screen.
  paywall,

  /// Heutiges Verhalten bei deaktivierter Paywall: Packages-Übersicht.
  packages,
}

PostCompletionDestination postCompletionDestination(
  String nextPackageId, {
  required Entitlement entitlement,
  required DateTime now,
  bool paywallEnabled = kPaywallEnabled,
}) {
  final unlocked = isPackageUnlocked(
    nextPackageId,
    entitlement: entitlement,
    now: now,
    paywallEnabled: paywallEnabled,
  );
  if (unlocked) return PostCompletionDestination.trainingStart;
  return paywallEnabled
      ? PostCompletionDestination.paywall
      : PostCompletionDestination.packages;
}
