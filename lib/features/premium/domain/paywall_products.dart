/// Paywall-Produkte (Trio B, Founder-Entscheidung D4 2026-07-07).
///
/// Preise sind hier NUR Anzeige-Konstanten für die Stub-Phase (T23).
/// Sobald RevenueCat/IAP verkabelt ist (T25), kommen Preise lokalisiert
/// aus dem Store — diese Datei liefert dann nur noch Produkt-Identität
/// und Anzeige-Reihenfolge.
library;

enum PaywallProductId { monthly, yearly, lifetime }

class PaywallProduct {
  const PaywallProduct({
    required this.id,
    required this.displayPrice,
    required this.highlighted,
  });

  final PaywallProductId id;

  /// Anzeigepreis der Stub-Phase (DE-Markt); T25 ersetzt durch Store-Preis.
  final String displayPrice;

  /// Jahres-Abo ist der hervorgehobene Standard (rationaler Sweet Spot bei
  /// 10–12 Monaten Programmdauer, siehe docs/MONETARISIERUNG_EVALUATION.md).
  final bool highlighted;
}

const paywallProducts = [
  PaywallProduct(
    id: PaywallProductId.monthly,
    displayPrice: '12,99 €',
    highlighted: false,
  ),
  PaywallProduct(
    id: PaywallProductId.yearly,
    displayPrice: '89,99 €',
    highlighted: true,
  ),
  PaywallProduct(
    id: PaywallProductId.lifetime,
    displayPrice: '149,00 €',
    highlighted: false,
  ),
];
