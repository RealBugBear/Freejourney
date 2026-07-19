import '../../../config/launch_flags.dart';
import '../../progress/presentation/providers/progress_provider.dart'
    show freePackageIds, packageOrder;

/// Server-side entitlement keys. Premium and Studio are deliberately
/// independent: owning one never implies owning the other.
enum EntitlementKey {
  premium('premium'),
  studio('studio');

  const EntitlementKey(this.dbValue);

  final String dbValue;

  static EntitlementKey? fromDb(String? value) => switch (value) {
        'premium' => EntitlementKey.premium,
        'studio' => EntitlementKey.studio,
        _ => null,
      };
}

/// Non-secret origin of a grant contributing to an effective entitlement.
///
/// An account can have more than one origin at the same time. The origin is
/// presentation/debug metadata only; access is decided by the server-side
/// effective status, not by a client-side priority rule.
enum GrantOrigin {
  revenueCat('revenuecat'),
  benefitCode('benefit_code'),
  pilot('pilot'),
  review('review'),
  admin('admin'),
  legacyProfile('legacy_profile'),
  unknown('unknown');

  const GrantOrigin(this.dbValue);

  final String dbValue;

  static GrantOrigin fromDb(String? value) => switch (value) {
        'revenuecat' || 'store' => GrantOrigin.revenueCat,
        'benefit_code' || 'code' => GrantOrigin.benefitCode,
        'pilot' => GrantOrigin.pilot,
        'review' => GrantOrigin.review,
        'admin' => GrantOrigin.admin,
        'legacy_profile' || 'legacy' => GrantOrigin.legacyProfile,
        _ => GrantOrigin.unknown,
      };
}

DateTime? _dateTime(dynamic value) {
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}

bool _bool(dynamic value, {bool fallback = false}) => switch (value) {
      true || 1 || 'true' => true,
      false || 0 || 'false' => false,
      _ => fallback,
    };

List<GrantOrigin> _grantOrigins(Map<String, dynamic> row) {
  final values = <dynamic>[];
  for (final key in const [
    'grant_origins',
    'origins',
    'sources',
    'grant_origin',
    'effective_source',
    'source',
  ]) {
    final value = row[key];
    if (value is Iterable) {
      values.addAll(value);
    } else if (value != null) {
      values.add(value);
    }
  }

  final origins = <GrantOrigin>[];
  for (final value in values) {
    final origin = GrantOrigin.fromDb(value?.toString());
    if (!origins.contains(origin)) origins.add(origin);
  }
  return origins;
}

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

/// Effective status for one entitlement key as last verified by the server.
///
/// [isActive] is the status returned by the server. Consumers must use
/// [isActiveAt] (or a snapshot returned by [evaluatedAt]) so a cached,
/// time-limited grant can never remain active past [expiresAt].
class EffectiveEntitlement {
  const EffectiveEntitlement({
    required this.key,
    required this.isActive,
    this.expiresAt,
    this.isPermanent = false,
    this.grantOrigins = const <GrantOrigin>[],
    this.legacyPremiumType,
  });

  static const premiumNone = EffectiveEntitlement(
    key: EntitlementKey.premium,
    isActive: false,
  );
  static const studioNone = EffectiveEntitlement(
    key: EntitlementKey.studio,
    isActive: false,
  );

  final EntitlementKey key;
  final bool isActive;
  final DateTime? expiresAt;
  final bool isPermanent;
  final List<GrantOrigin> grantOrigins;

  /// Kept only for the T23 `profiles` projection/display compatibility.
  final PremiumType? legacyPremiumType;

  bool isActiveAt(DateTime now) {
    if (!isActive) return false;
    final expiry = expiresAt;
    if (expiry == null) return true;
    return now.isBefore(expiry);
  }

  EffectiveEntitlement evaluatedAt(DateTime now) {
    if (!isActive || isActiveAt(now)) return this;
    return EffectiveEntitlement(
      key: key,
      isActive: false,
      expiresAt: expiresAt,
      isPermanent: isPermanent,
      grantOrigins: grantOrigins,
      legacyPremiumType: legacyPremiumType,
    );
  }

  factory EffectiveEntitlement.fromJson(
    EntitlementKey key,
    Map<String, dynamic> row,
  ) {
    final reportedActive = _bool(
      row['is_active'] ??
          row['active'] ??
          row['is_entitled'] ??
          row['entitled'],
    );
    const expiryKeys = [
      'expires_at',
      'valid_until',
      'premium_valid_until',
    ];
    final expiryKey = expiryKeys.cast<String?>().firstWhere(
          (candidate) => row.containsKey(candidate),
          orElse: () => null,
        );
    final expiryValue = expiryKey == null ? null : row[expiryKey];
    final expiresAt = _dateTime(expiryValue);
    final reportedPermanent = _bool(row['is_permanent']);

    // A malformed successful response must never turn into up to 72 hours of
    // cached access. Canonical active rows are either explicitly permanent
    // with no expiry, or finite with a parseable expiry. Legacy profile rows
    // use [fromLegacy] and therefore do not rely on this inference.
    final hasValidActiveShape = !reportedActive ||
        (reportedPermanent
            ? expiryKey != null && expiryValue == null
            : expiresAt != null);
    final active = reportedActive && hasValidActiveShape;
    return EffectiveEntitlement(
      key: key,
      isActive: active,
      expiresAt: expiresAt,
      isPermanent: active && reportedPermanent,
      grantOrigins: _grantOrigins(row),
      legacyPremiumType: PremiumType.fromDb(
        (row['premium_type'] ?? row['legacy_premium_type'])?.toString(),
      ),
    );
  }

  factory EffectiveEntitlement.fromLegacy(Entitlement entitlement) {
    return EffectiveEntitlement(
      key: EntitlementKey.premium,
      isActive: entitlement.isPremium,
      expiresAt: entitlement.validUntil,
      isPermanent: entitlement.isPremium && entitlement.validUntil == null,
      grantOrigins: const [GrantOrigin.legacyProfile],
      legacyPremiumType: entitlement.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'entitlement_key': key.dbValue,
        'is_active': isActive,
        'expires_at': expiresAt?.toUtc().toIso8601String(),
        'is_permanent': isPermanent,
        'grant_origins': grantOrigins.map((origin) => origin.dbValue).toList(),
        'legacy_premium_type': switch (legacyPremiumType) {
          PremiumType.monthly => 'monthly',
          PremiumType.yearly => 'yearly',
          PremiumType.lifetime => 'lifetime',
          PremiumType.code => 'code',
          null => null,
        },
      };

  Entitlement toLegacyPremium() {
    assert(key == EntitlementKey.premium);
    final inferredType = switch (grantOrigins) {
      final origins when origins.contains(GrantOrigin.benefitCode) =>
        PremiumType.code,
      _ when isPermanent => PremiumType.lifetime,
      _ => null,
    };
    return Entitlement(
      isPremium: isActive,
      type: legacyPremiumType ?? inferredType,
      validUntil: expiresAt,
      grantOrigins: grantOrigins,
    );
  }
}

/// Account-level server snapshot. It always contains both independent keys,
/// including explicit inactive entries.
class AccountEntitlements {
  const AccountEntitlements({
    required this.premium,
    required this.studio,
  });

  static const none = AccountEntitlements(
    premium: EffectiveEntitlement.premiumNone,
    studio: EffectiveEntitlement.studioNone,
  );

  final EffectiveEntitlement premium;
  final EffectiveEntitlement studio;

  EffectiveEntitlement forKey(EntitlementKey key) => switch (key) {
        EntitlementKey.premium => premium,
        EntitlementKey.studio => studio,
      };

  AccountEntitlements evaluatedAt(DateTime now) => AccountEntitlements(
        premium: premium.evaluatedAt(now),
        studio: studio.evaluatedAt(now),
      );

  Map<String, dynamic> toJson() => {
        'premium': premium.toJson(),
        'studio': studio.toJson(),
      };

  factory AccountEntitlements.fromJson(Map<String, dynamic> json) {
    final premiumJson = json['premium'];
    final studioJson = json['studio'];
    return AccountEntitlements(
      premium: premiumJson is Map
          ? EffectiveEntitlement.fromJson(
              EntitlementKey.premium,
              premiumJson.cast<String, dynamic>(),
            )
          : EffectiveEntitlement.premiumNone,
      studio: studioJson is Map
          ? EffectiveEntitlement.fromJson(
              EntitlementKey.studio,
              studioJson.cast<String, dynamic>(),
            )
          : EffectiveEntitlement.studioNone,
    );
  }

  /// Accepts the canonical table result (one row per entitlement key) and
  /// JSON-object variants so the app remains compatible during additive DB
  /// rollout. Multiple rows for a key are merged without one grant erasing
  /// another.
  factory AccountEntitlements.fromRpc(dynamic response) {
    final unwrapped = _unwrapRpcData(response);
    final effective = <EntitlementKey, EffectiveEntitlement>{};

    void merge(EffectiveEntitlement next) {
      final current = effective[next.key];
      if (current == null) {
        effective[next.key] = next;
        return;
      }
      final origins = <GrantOrigin>[
        ...current.grantOrigins,
        ...next.grantOrigins.where(
          (origin) => !current.grantOrigins.contains(origin),
        ),
      ];
      final active = current.isActive || next.isActive;
      final permanent = (current.isActive && current.isPermanent) ||
          (next.isActive && next.isPermanent);
      final expiry = permanent
          ? null
          : switch ((current.isActive, next.isActive)) {
              (true, true) => _later(current.expiresAt, next.expiresAt),
              (true, false) => current.expiresAt,
              (false, true) => next.expiresAt,
              _ => _later(current.expiresAt, next.expiresAt),
            };
      effective[next.key] = EffectiveEntitlement(
        key: next.key,
        isActive: active,
        expiresAt: expiry,
        isPermanent: permanent,
        grantOrigins: origins,
        legacyPremiumType: current.legacyPremiumType ?? next.legacyPremiumType,
      );
    }

    void addRow(Map<String, dynamic> row, {EntitlementKey? impliedKey}) {
      final key = impliedKey ??
          EntitlementKey.fromDb(
            (row['entitlement_key'] ?? row['key'])?.toString(),
          );
      if (key != null) merge(EffectiveEntitlement.fromJson(key, row));
    }

    if (unwrapped is Iterable) {
      for (final value in unwrapped) {
        if (value is Map) addRow(value.cast<String, dynamic>());
      }
    } else if (unwrapped is Map) {
      final json = unwrapped.cast<String, dynamic>();
      final nested = json['entitlements'];
      if (nested is Iterable) {
        for (final value in nested) {
          if (value is Map) addRow(value.cast<String, dynamic>());
        }
      } else if (nested is Map) {
        _addNestedEntitlements(nested.cast<String, dynamic>(), addRow);
      } else {
        _addNestedEntitlements(json, addRow);
        _addFlatEntitlements(json, addRow);
        if (json.containsKey('entitlement_key') || json.containsKey('key')) {
          addRow(json);
        }
      }
    } else if (unwrapped != null) {
      throw const FormatException('Unsupported entitlement RPC response');
    }

    return AccountEntitlements(
      premium:
          effective[EntitlementKey.premium] ?? EffectiveEntitlement.premiumNone,
      studio:
          effective[EntitlementKey.studio] ?? EffectiveEntitlement.studioNone,
    );
  }
}

dynamic _unwrapRpcData(dynamic response) {
  if (response is! Map) return response;
  final json = response.cast<String, dynamic>();
  if (json.containsKey('data') &&
      !json.containsKey('premium') &&
      !json.containsKey('studio') &&
      !json.containsKey('entitlement_key')) {
    return json['data'];
  }
  return json;
}

void _addNestedEntitlements(
  Map<String, dynamic> json,
  void Function(Map<String, dynamic>, {EntitlementKey? impliedKey}) addRow,
) {
  for (final key in EntitlementKey.values) {
    final value = json[key.dbValue];
    if (value is Map) {
      addRow(value.cast<String, dynamic>(), impliedKey: key);
    } else if (value is bool) {
      addRow({'is_active': value}, impliedKey: key);
    }
  }
}

void _addFlatEntitlements(
  Map<String, dynamic> json,
  void Function(Map<String, dynamic>, {EntitlementKey? impliedKey}) addRow,
) {
  for (final key in EntitlementKey.values) {
    final prefix = key.dbValue;
    final active = json['${prefix}_active'] ?? json['${prefix}_is_active'];
    if (active == null) continue;
    addRow({
      'is_active': active,
      'expires_at': json['${prefix}_expires_at'],
      'is_permanent': json['${prefix}_is_permanent'],
      'grant_origins':
          json['${prefix}_grant_origins'] ?? json['${prefix}_sources'],
      'source': json['${prefix}_source'],
      'premium_type': json['premium_type'],
    }, impliedKey: key);
  }
}

DateTime? _later(DateTime? first, DateTime? second) {
  if (first == null) return second;
  if (second == null) return first;
  return first.isAfter(second) ? first : second;
}

/// Timestamped cache envelope. A cached snapshot is usable for at most 72
/// hours and each entitlement is independently expired at its own end date.
class CachedAccountEntitlements {
  const CachedAccountEntitlements({
    required this.verifiedAt,
    required this.entitlements,
  });

  static const maxOfflineAge = Duration(hours: 72);

  final DateTime verifiedAt;
  final AccountEntitlements entitlements;

  AccountEntitlements? readAt(DateTime now) {
    if (now.isBefore(verifiedAt)) return null;
    if (now.difference(verifiedAt) > maxOfflineAge) return null;
    return entitlements.evaluatedAt(now);
  }

  Map<String, dynamic> toJson() => {
        // Persist an absolute instant. Local ISO strings carry no offset in
        // Dart and could otherwise shift after a timezone/DST change.
        'verified_at': verifiedAt.toUtc().toIso8601String(),
        'entitlements': entitlements.toJson(),
      };

  factory CachedAccountEntitlements.fromJson(Map<String, dynamic> json) {
    final verifiedAt = _dateTime(json['verified_at']);
    final entitlements = json['entitlements'];
    if (verifiedAt == null || entitlements is! Map) {
      throw const FormatException('Invalid entitlement cache');
    }
    return CachedAccountEntitlements(
      verifiedAt: verifiedAt,
      entitlements: AccountEntitlements.fromJson(
        entitlements.cast<String, dynamic>(),
      ),
    );
  }
}

enum RolloutAudience {
  off,
  internal,
  cohort,
  public;

  static RolloutAudience fromDb(
    String? value, {
    required RolloutAudience fallback,
  }) =>
      switch (value) {
        'off' => RolloutAudience.off,
        'internal' => RolloutAudience.internal,
        'cohort' => RolloutAudience.cohort,
        'public' => RolloutAudience.public,
        _ => fallback,
      };
}

/// Paid-surface rollout state. Sales and feature access are intentionally
/// separate: turning sales off must never revoke an already valid grant.
class PaidRollout {
  const PaidRollout({
    required this.key,
    this.salesAudience = RolloutAudience.off,
    this.featureAudience = RolloutAudience.public,
    this.incidentDisabled = false,
    this.salesConfigured = false,
    this.featureConfigured = false,
  });

  final EntitlementKey key;
  final RolloutAudience salesAudience;
  final RolloutAudience featureAudience;
  final bool incidentDisabled;
  final bool salesConfigured;
  final bool featureConfigured;

  bool canStartSale({
    bool isInternal = false,
    bool isCohortMember = false,
  }) =>
      _audienceAllows(
        salesAudience,
        isInternal: isInternal,
        isCohortMember: isCohortMember,
      );

  bool hasFeatureAccess({
    required EffectiveEntitlement entitlement,
    required DateTime now,
    bool isInternal = false,
    bool isCohortMember = false,
  }) {
    if (entitlement.key != key || !entitlement.isActiveAt(now)) return false;
    if (incidentDisabled) return false;
    return _audienceAllows(
      featureAudience,
      isInternal: isInternal,
      isCohortMember: isCohortMember,
    );
  }

  factory PaidRollout.fromJson(
    EntitlementKey key,
    Map<String, dynamic> json,
  ) {
    final salesConfigured = _bool(json['sales_configured']);
    final featureConfigured = _bool(json['feature_configured']);
    final salesValue =
        salesConfigured ? json['sales_rollout']?.toString() : null;
    final featureValue =
        featureConfigured ? json['feature_rollout']?.toString() : null;
    return PaidRollout(
      key: key,
      salesAudience: RolloutAudience.fromDb(
        salesValue,
        fallback: RolloutAudience.off,
      ),
      featureAudience: RolloutAudience.fromDb(
        featureValue,
        fallback: RolloutAudience.public,
      ),
      incidentDisabled: featureValue == 'incident_disabled' ||
          (featureConfigured && _bool(json['incident_disabled'])),
      salesConfigured: salesConfigured,
      featureConfigured: featureConfigured,
    );
  }
}

bool _audienceAllows(
  RolloutAudience audience, {
  required bool isInternal,
  required bool isCohortMember,
}) =>
    switch (audience) {
      RolloutAudience.off => false,
      RolloutAudience.internal => isInternal,
      RolloutAudience.cohort => isInternal || isCohortMember,
      RolloutAudience.public => true,
    };

class PaidRollouts {
  const PaidRollouts({
    required this.premium,
    required this.studio,
  });

  /// Fail-closed for new sales, while valid entitlements keep feature access.
  static const safeDefault = PaidRollouts(
    premium: PaidRollout(key: EntitlementKey.premium),
    studio: PaidRollout(key: EntitlementKey.studio),
  );

  final PaidRollout premium;
  final PaidRollout studio;

  PaidRollout forKey(EntitlementKey key) => switch (key) {
        EntitlementKey.premium => premium,
        EntitlementKey.studio => studio,
      };

  factory PaidRollouts.fromRpc(dynamic response) {
    final unwrapped = _unwrapRpcData(response);
    final values = <EntitlementKey, PaidRollout>{};

    void add(Map<String, dynamic> row, {EntitlementKey? impliedKey}) {
      final key = impliedKey ??
          EntitlementKey.fromDb(
            (row['entitlement_key'] ?? row['key'])?.toString(),
          );
      if (key != null) values[key] = PaidRollout.fromJson(key, row);
    }

    if (unwrapped is Iterable) {
      for (final value in unwrapped) {
        if (value is Map) add(value.cast<String, dynamic>());
      }
    } else if (unwrapped is Map) {
      final json = unwrapped.cast<String, dynamic>();
      final nested = json['rollouts'];
      if (nested is Iterable) {
        for (final value in nested) {
          if (value is Map) add(value.cast<String, dynamic>());
        }
      } else {
        for (final key in EntitlementKey.values) {
          final value = json[key.dbValue];
          if (value is Map) {
            add(value.cast<String, dynamic>(), impliedKey: key);
          }
        }
        if (json.containsKey('entitlement_key') || json.containsKey('key')) {
          add(json);
        }
      }
    } else if (unwrapped != null) {
      throw const FormatException('Unsupported rollout RPC response');
    }

    return PaidRollouts(
      premium: values[EntitlementKey.premium] ?? safeDefault.premium,
      studio: values[EntitlementKey.studio] ?? safeDefault.studio,
    );
  }
}

/// Premium-Status eines Kontos, gelesen aus `profiles` (server-verwaltet —
/// Clients können die Felder wegen `trg_prevent_direct_premium_change`
/// nicht selbst setzen).
class Entitlement {
  const Entitlement({
    required this.isPremium,
    this.type,
    this.validUntil,
    this.grantOrigins = const <GrantOrigin>[],
  });

  static const none = Entitlement(isPremium: false);

  final bool isPremium;
  final PremiumType? type;
  final DateTime? validUntil;
  final List<GrantOrigin> grantOrigins;

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
      grantOrigins: _grantOrigins(row),
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
        'premium_valid_until': validUntil?.toUtc().toIso8601String(),
        'grant_origins': grantOrigins.map((origin) => origin.dbValue).toList(),
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
