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
      final original =
          _active(PremiumType.yearly, until: DateTime.utc(2027, 1, 1));
      final restored = Entitlement.fromProfileRow(original.toCacheJson());
      expect(restored.isPremium, original.isPremium);
      expect(restored.type, original.type);
      expect(restored.validUntil, original.validUntil);
    });
  });

  group('account-effective Premium + Studio status', () {
    test('parses canonical RPC object and exposes independent grant origins',
        () {
      final account = AccountEntitlements.fromRpc({
        'premium': {
          'is_active': true,
          'expires_at': null,
          'is_permanent': true,
          'source': 'benefit_code',
        },
        'studio': {
          'is_active': true,
          'expires_at': '2026-08-01T00:00:00Z',
          'is_permanent': false,
          'source': 'pilot',
        },
      });

      expect(account.premium.isActiveAt(now), isTrue);
      expect(account.premium.grantOrigins, [GrantOrigin.benefitCode]);
      expect(account.studio.isActiveAt(now), isTrue);
      expect(account.studio.grantOrigins, [GrantOrigin.pilot]);
      expect(account.premium.toLegacyPremium().type, PremiumType.code);
    });

    test('active code survives an expired store row for the same key', () {
      final account = AccountEntitlements.fromRpc([
        {
          'entitlement_key': 'premium',
          'is_active': false,
          'expires_at': '2026-07-01T00:00:00Z',
          'is_permanent': false,
          'source': 'revenuecat',
        },
        {
          'entitlement_key': 'premium',
          'is_active': true,
          'expires_at': null,
          'is_permanent': true,
          'source': 'benefit_code',
        },
      ]);

      expect(account.premium.isActiveAt(now), isTrue);
      expect(account.premium.isPermanent, isTrue);
      expect(account.premium.expiresAt, isNull);
    });

    test('expired review grant stays inactive without affecting Premium', () {
      final account = AccountEntitlements.fromRpc({
        'premium': {
          'is_active': true,
          'expires_at': null,
          'is_permanent': true,
          'source': 'admin',
        },
        'studio': {
          'is_active': true,
          'expires_at': '2026-07-06T00:00:00Z',
          'source': 'review',
        },
      }).evaluatedAt(now);

      expect(account.premium.isActive, isTrue);
      expect(account.studio.isActive, isFalse);
    });

    test('malformed active RPC rows fail closed before entering the cache', () {
      final missingFiniteExpiry = AccountEntitlements.fromRpc({
        'premium': {
          'is_active': true,
          'is_permanent': false,
          'source': 'revenuecat',
        },
        'studio': {
          'is_active': true,
          'is_permanent': true,
          'expires_at': 'not-a-timestamp',
          'source': 'pilot',
        },
      });

      expect(missingFiniteExpiry.premium.isActive, isFalse);
      expect(missingFiniteExpiry.premium.isPermanent, isFalse);
      expect(missingFiniteExpiry.studio.isActive, isFalse);
      expect(missingFiniteExpiry.studio.isPermanent, isFalse);
    });
  });

  group('bounded offline entitlement cache', () {
    final verifiedAt = DateTime.utc(2026, 7, 7);

    CachedAccountEntitlements cacheWith({DateTime? premiumExpiry}) =>
        CachedAccountEntitlements(
          verifiedAt: verifiedAt,
          entitlements: AccountEntitlements(
            premium: EffectiveEntitlement(
              key: EntitlementKey.premium,
              isActive: true,
              isPermanent: premiumExpiry == null,
              expiresAt: premiumExpiry,
              grantOrigins: const [GrantOrigin.benefitCode],
            ),
            studio: EffectiveEntitlement.studioNone,
          ),
        );

    test('allows a verified permanent grant for at most 72 hours', () {
      final cache = cacheWith();
      expect(
        cache
            .readAt(verifiedAt.add(const Duration(hours: 72)))
            ?.premium
            .isActive,
        isTrue,
      );
      expect(
        cache.readAt(
          verifiedAt.add(const Duration(hours: 72, milliseconds: 1)),
        ),
        isNull,
      );
    });

    test('never keeps access active past expires_at inside the 72h window', () {
      final expiry = verifiedAt.add(const Duration(hours: 12));
      final cache = cacheWith(premiumExpiry: expiry);

      expect(
        cache
            .readAt(expiry.subtract(const Duration(milliseconds: 1)))
            ?.premium
            .isActive,
        isTrue,
      );
      expect(cache.readAt(expiry)?.premium.isActive, isFalse);
    });

    test('cache JSON roundtrip retains verification time and both keys', () {
      final original = cacheWith(
        premiumExpiry: verifiedAt.add(const Duration(hours: 24)),
      );
      final restored = CachedAccountEntitlements.fromJson(original.toJson());

      expect(restored.verifiedAt, verifiedAt);
      expect(
        restored
            .readAt(verifiedAt.add(const Duration(hours: 1)))
            ?.premium
            .grantOrigins,
        [GrantOrigin.benefitCode],
      );
      expect(restored.entitlements.studio.key, EntitlementKey.studio);
    });

    test('cache persists local verification instants as UTC', () {
      final localVerifiedAt = DateTime(2026, 7, 7, 12, 30);
      final original = CachedAccountEntitlements(
        verifiedAt: localVerifiedAt,
        entitlements: AccountEntitlements.none,
      );

      final json = original.toJson();
      final restored = CachedAccountEntitlements.fromJson(json);

      expect(json['verified_at'], endsWith('Z'));
      expect(restored.verifiedAt.isUtc, isTrue);
      expect(restored.verifiedAt, localVerifiedAt.toUtc());
    });

    test('future-dated cache fails closed', () {
      expect(
        cacheWith().readAt(verifiedAt.subtract(const Duration(seconds: 1))),
        isNull,
      );
    });
  });

  group('paid rollout separation', () {
    const activePremium = EffectiveEntitlement(
      key: EntitlementKey.premium,
      isActive: true,
      isPermanent: true,
    );

    test('sales off blocks a new sale but never revokes valid feature access',
        () {
      const rollout = PaidRollout(
        key: EntitlementKey.premium,
        salesAudience: RolloutAudience.off,
        featureAudience: RolloutAudience.public,
      );

      expect(rollout.canStartSale(), isFalse);
      expect(
        rollout.hasFeatureAccess(entitlement: activePremium, now: now),
        isTrue,
      );
    });

    test('incident_disabled is a separate explicit access stop', () {
      final rollouts = PaidRollouts.fromRpc({
        'premium': {
          'sales_rollout': 'off',
          'feature_rollout': 'incident_disabled',
          'sales_configured': true,
          'feature_configured': true,
        },
        'studio': {
          'sales_rollout': 'cohort',
          'feature_rollout': null,
          'sales_configured': true,
          'feature_configured': false,
        },
      });

      expect(rollouts.premium.incidentDisabled, isTrue);
      expect(
        rollouts.premium.hasFeatureAccess(entitlement: activePremium, now: now),
        isFalse,
      );
      expect(rollouts.studio.featureAudience, RolloutAudience.public);
      expect(rollouts.studio.featureConfigured, isFalse);
    });

    test('unconfigured safe default fails closed only for sales', () {
      expect(PaidRollouts.safeDefault.premium.canStartSale(), isFalse);
      expect(
        PaidRollouts.safeDefault.premium
            .hasFeatureAccess(entitlement: activePremium, now: now),
        isTrue,
      );
    });

    test('unconfigured values cannot open sales or disable valid access', () {
      final rollouts = PaidRollouts.fromRpc({
        'premium': {
          'sales_rollout': 'public',
          'feature_rollout': 'incident_disabled',
          'incident_disabled': true,
          'sales_configured': false,
          'feature_configured': false,
        },
      });

      expect(rollouts.premium.canStartSale(), isFalse);
      expect(rollouts.premium.incidentDisabled, isFalse);
      expect(
        rollouts.premium.hasFeatureAccess(
          entitlement: activePremium,
          now: now,
        ),
        isTrue,
      );
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
