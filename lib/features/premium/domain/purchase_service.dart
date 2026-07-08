import 'paywall_products.dart';

/// Ergebnis eines Kaufversuchs.
enum PurchaseOutcome {
  /// Kauf erfolgreich — Entitlement wird server-seitig gesetzt.
  success,

  /// Nutzer hat abgebrochen.
  cancelled,

  /// In dieser App-Version existiert noch kein Kaufweg (T23-Stub;
  /// echter IAP-Flow kommt mit T25/RevenueCat).
  notAvailable,

  /// Store-/Netzwerkfehler.
  failed,
}

/// Abstrakter Kaufweg — T23 liefert nur den Stub; T25 ersetzt ihn durch
/// die RevenueCat-Implementierung (gleiche Schnittstelle, damit Paywall-UI
/// und Tests unverändert bleiben).
abstract class PurchaseService {
  Future<PurchaseOutcome> purchase(PaywallProductId productId);
  Future<PurchaseOutcome> restorePurchases();
}

class StubPurchaseService implements PurchaseService {
  const StubPurchaseService();

  @override
  Future<PurchaseOutcome> purchase(PaywallProductId productId) async =>
      PurchaseOutcome.notAvailable;

  @override
  Future<PurchaseOutcome> restorePurchases() async =>
      PurchaseOutcome.notAvailable;
}
