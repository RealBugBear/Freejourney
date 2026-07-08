// T23 — Paywall-Grundstruktur: sichert (1) dass die Paywall für den Launch
// deaktiviert ist, (2) die zentrale Freischalt-Logik in beiden Flag-Zweigen
// (Flag aus = heutiges Verhalten mit 3 freien Paketen; Flag an = nur Moro
// frei + Entitlement), (3) das Entitlement-Parsing inkl. Ablaufdatum und
// (4) die Ziel-Entscheidung nach Paket-Abschluss.
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/features/premium/domain/entitlement.dart';

Entitlement _active(PremiumType type, {DateTime? until}) =>
    Entitlement(isPremium: true, type: type, validUntil: until);

void main() {
  final now = DateTime(2026, 7, 7);

  test('kPaywallEnabled ist für den Launch deaktiviert (D4)', () {
    expect(
      kPaywallEnabled,
      isFalse,
      reason: 'Launch ist kostenlos (8.4); Aktivierung erst nach '
          'R8-Trigger + AGB + T25 (echter Kaufweg).',
    );
  });

  group('isPackageUnlocked — Flag AUS (heutiges Launch-Verhalten)', () {
    test('die ersten drei Pakete sind frei, spätere gesperrt', () {
      for (final id in ['moro', 'spinal_galant', 'tlr']) {
        expect(
          isPackageUnlocked(id,
              entitlement: Entitlement.none, now: now, paywallEnabled: false),
          isTrue,
          reason: '$id ist heute frei',
        );
      }
      for (final id in ['babkin', 'such_saug', 'atnr', 'landau']) {
        expect(
          isPackageUnlocked(id,
              entitlement: Entitlement.none, now: now, paywallEnabled: false),
          isFalse,
          reason: '$id ist heute gesperrt',
        );
      }
    });

    test('Entitlement ändert bei deaktivierter Paywall nichts', () {
      expect(
        isPackageUnlocked('babkin',
            entitlement: _active(PremiumType.lifetime),
            now: now,
            paywallEnabled: false),
        isFalse,
        reason: 'Flag aus = exakt heutiges Verhalten, Entitlement ungenutzt',
      );
    });
  });

  group('isPackageUnlocked — Flag AN (Design §3)', () {
    test('nur Paket 1 (moro) ist ohne Entitlement frei', () {
      expect(
        isPackageUnlocked('moro',
            entitlement: Entitlement.none, now: now, paywallEnabled: true),
        isTrue,
      );
      for (final id in ['spinal_galant', 'tlr', 'babkin']) {
        expect(
          isPackageUnlocked(id,
              entitlement: Entitlement.none, now: now, paywallEnabled: true),
          isFalse,
          reason: '$id braucht mit aktiver Paywall ein Entitlement',
        );
      }
    });

    test('lifetime und code schalten dauerhaft frei (kein Ablaufdatum)', () {
      for (final type in [PremiumType.lifetime, PremiumType.code]) {
        expect(
          isPackageUnlocked('landau',
              entitlement: _active(type), now: now, paywallEnabled: true),
          isTrue,
        );
      }
    });

    test('Abo schaltet nur bis premium_valid_until frei', () {
      final valid = _active(PremiumType.monthly,
          until: now.add(const Duration(days: 10)));
      final expired = _active(PremiumType.monthly,
          until: now.subtract(const Duration(days: 1)));
      expect(
        isPackageUnlocked('babkin',
            entitlement: valid, now: now, paywallEnabled: true),
        isTrue,
      );
      expect(
        isPackageUnlocked('babkin',
            entitlement: expired, now: now, paywallEnabled: true),
        isFalse,
        reason: 'abgelaufenes Abo darf nicht freischalten (defensiv, '
            'zusätzlich zum Webhook)',
      );
    });
  });

  group('Entitlement.fromProfileRow', () {
    test('lifetime ohne validUntil ist dauerhaft aktiv', () {
      final e = Entitlement.fromProfileRow({
        'is_premium': true,
        'premium_type': 'lifetime',
        'premium_valid_until': null,
      });
      expect(e.isActive(now), isTrue);
      expect(e.type, PremiumType.lifetime);
    });

    test('abgelaufenes Jahres-Abo ist inaktiv, aktives aktiv', () {
      final expired = Entitlement.fromProfileRow({
        'is_premium': true,
        'premium_type': 'yearly',
        'premium_valid_until': '2026-01-01T00:00:00Z',
      });
      expect(expired.isActive(now), isFalse);

      final active = Entitlement.fromProfileRow({
        'is_premium': true,
        'premium_type': 'yearly',
        'premium_valid_until': '2027-01-01T00:00:00Z',
      });
      expect(active.isActive(now), isTrue);
    });

    test('leere/unbekannte Zeile ergibt kein Premium', () {
      expect(Entitlement.fromProfileRow({}).isActive(now), isFalse);
      expect(
        Entitlement.fromProfileRow({'premium_type': 'weird'}).type,
        isNull,
      );
    });

    test('Cache-Roundtrip erhält den Status', () {
      final original = _active(PremiumType.yearly,
          until: DateTime.utc(2027, 1, 1));
      final restored = Entitlement.fromProfileRow(original.toCacheJson());
      expect(restored.isPremium, original.isPremium);
      expect(restored.type, original.type);
      expect(restored.validUntil, original.validUntil);
    });
  });

  group('postCompletionDestination', () {
    test('Flag aus: freies nächstes Paket → Trainingsstart', () {
      expect(
        postCompletionDestination('spinal_galant',
            entitlement: Entitlement.none, now: now, paywallEnabled: false),
        PostCompletionDestination.trainingStart,
      );
    });

    test('Flag aus: gesperrtes nächstes Paket → Packages (heutiges Verhalten)',
        () {
      expect(
        postCompletionDestination('babkin',
            entitlement: Entitlement.none, now: now, paywallEnabled: false),
        PostCompletionDestination.packages,
      );
    });

    test('Flag an: ohne Entitlement → Paywall', () {
      expect(
        postCompletionDestination('spinal_galant',
            entitlement: Entitlement.none, now: now, paywallEnabled: true),
        PostCompletionDestination.paywall,
      );
    });

    test('Flag an: mit aktivem Entitlement → Trainingsstart', () {
      expect(
        postCompletionDestination('babkin',
            entitlement: _active(PremiumType.lifetime),
            now: now,
            paywallEnabled: true),
        PostCompletionDestination.trainingStart,
      );
    });
  });
}
