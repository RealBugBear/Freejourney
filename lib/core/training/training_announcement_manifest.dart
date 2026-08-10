import 'dart:convert';

import 'package:flutter/services.dart';

typedef AnnouncementAssetProbe = Future<bool> Function(String bundleAssetKey);

class TrainingAnnouncementEntryIds {
  TrainingAnnouncementEntryIds._();

  static const String sessionPause = 'session.pause';
  static const String sessionResume = 'session.resume';
  static const String sessionComplete = 'session.complete';
  static const String sessionSafety = 'session.safety';
  static const String sessionCountdown3 = 'session.countdown.3';
  static const String sessionCountdown2 = 'session.countdown.2';
  static const String sessionCountdown1 = 'session.countdown.1';
  static const String exerciseRepetitionComplete =
      'exercise.repetition.complete';
  static const String exerciseSwitchSide = 'exercise.switch_side';
  static const String exerciseRest = 'exercise.rest';
}

/// Versioned, locale-aware metadata for professionally recorded announcements.
///
/// An entry with a null [TrainingAnnouncementEntry.assetKey] is a recording
/// requirement, not a playable asset. This lets the app ship the specified
/// recording contract without implying editorial approval or an existing MP3.
class TrainingAnnouncementManifest {
  static const String bundledAssetPath =
      'assets/sounds/announcements/manifest.v1.json';

  final int schemaVersion;
  final String contentVersion;
  final String defaultLocale;
  final Map<String, TrainingAnnouncementLocale> locales;

  const TrainingAnnouncementManifest({
    required this.schemaVersion,
    required this.contentVersion,
    required this.defaultLocale,
    required this.locales,
  });

  factory TrainingAnnouncementManifest.fromJsonString(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid announcement manifest JSON: $error');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Announcement manifest root must be a JSON object.',
      );
    }
    return TrainingAnnouncementManifest.fromJson(decoded);
  }

  factory TrainingAnnouncementManifest.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion != 1) {
      throw FormatException(
        'Unsupported announcement manifest schemaVersion: $schemaVersion.',
      );
    }

    final contentVersion = json['contentVersion'];
    if (contentVersion is! String || contentVersion.trim().isEmpty) {
      throw const FormatException(
        'Announcement manifest contentVersion must be non-empty.',
      );
    }

    final rawLocales = json['locales'];
    if (rawLocales is! Map<String, dynamic> || rawLocales.isEmpty) {
      throw const FormatException(
        'Announcement manifest locales must be a non-empty object.',
      );
    }

    final locales = <String, TrainingAnnouncementLocale>{};
    for (final MapEntry(key: rawLocale, value: rawCatalog)
        in rawLocales.entries) {
      final locale = _normalizeLocaleTag(rawLocale);
      if (locale.isEmpty || rawCatalog is! Map<String, dynamic>) {
        throw FormatException(
          'Invalid announcement locale catalog: $rawLocale.',
        );
      }
      if (locales.containsKey(locale)) {
        throw FormatException('Duplicate announcement locale: $locale.');
      }
      locales[locale] = TrainingAnnouncementLocale.fromJson(
        locale: locale,
        json: rawCatalog,
      );
    }

    final rawDefaultLocale = json['defaultLocale'];
    if (rawDefaultLocale is! String) {
      throw const FormatException(
        'Announcement manifest defaultLocale must be a string.',
      );
    }
    final defaultLocale = _normalizeLocaleTag(rawDefaultLocale);
    if (!locales.containsKey(defaultLocale)) {
      throw FormatException(
        'Announcement defaultLocale "$defaultLocale" has no catalog.',
      );
    }

    return TrainingAnnouncementManifest(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      defaultLocale: defaultLocale,
      locales: Map.unmodifiable(locales),
    );
  }

  static Future<TrainingAnnouncementManifest> loadBundled({
    AssetBundle? bundle,
  }) async {
    final source = await (bundle ?? rootBundle)
        .loadString(TrainingAnnouncementManifest.bundledAssetPath);
    return TrainingAnnouncementManifest.fromJsonString(source);
  }

  /// Resolves exact tags first, then the base language, then [defaultLocale].
  String resolveLocale(String? requestedLocale) {
    final normalized = _normalizeLocaleTag(requestedLocale ?? '');
    if (locales.containsKey(normalized)) return normalized;

    final separator = normalized.indexOf('-');
    final base =
        separator == -1 ? normalized : normalized.substring(0, separator);
    if (locales.containsKey(base)) return base;

    return defaultLocale;
  }

  TrainingAnnouncementLocale catalogFor(String? requestedLocale) {
    return locales[resolveLocale(requestedLocale)]!;
  }

  TrainingAnnouncementEntry? entryFor(
    String? requestedLocale,
    String entryId,
  ) {
    return catalogFor(requestedLocale).entries[entryId];
  }

  String? assetKeyFor(String? requestedLocale, String entryId) {
    return entryFor(requestedLocale, entryId)?.assetKey;
  }

  /// Checks every required entry against the actual Flutter asset bundle.
  ///
  /// Null asset keys are reported as [AnnouncementAssetPreflightReport.unassignedEntryIds];
  /// referenced but absent files are reported separately as [AnnouncementAssetPreflightReport.missingAssetKeys].
  Future<AnnouncementAssetPreflightReport> preflight({
    required String? requestedLocale,
    required AnnouncementAssetProbe assetExists,
    Iterable<String>? requiredEntryIds,
  }) async {
    final locale = resolveLocale(requestedLocale);
    final catalog = locales[locale]!;
    final ids = (requiredEntryIds ?? catalog.entries.keys).toSet().toList()
      ..sort();
    final availableAssetKeys = <String>[];
    final invalidAssetKeys = <String>[];
    final missingAssetKeys = <String>[];
    final missingEntryIds = <String>[];
    final unassignedEntryIds = <String>[];

    for (final id in ids) {
      final entry = catalog.entries[id];
      if (entry == null) {
        missingEntryIds.add(id);
        continue;
      }

      final assetKey = entry.assetKey;
      if (assetKey == null) {
        unassignedEntryIds.add(id);
        continue;
      }
      if (!_isValidAssetKey(assetKey, locale)) {
        invalidAssetKeys.add(assetKey);
        continue;
      }

      final exists = await assetExists('assets/$assetKey');
      if (exists) {
        availableAssetKeys.add(assetKey);
      } else {
        missingAssetKeys.add(assetKey);
      }
    }

    return AnnouncementAssetPreflightReport(
      locale: locale,
      availableAssetKeys: List.unmodifiable(availableAssetKeys),
      invalidAssetKeys: List.unmodifiable(invalidAssetKeys),
      missingAssetKeys: List.unmodifiable(missingAssetKeys),
      missingEntryIds: List.unmodifiable(missingEntryIds),
      unassignedEntryIds: List.unmodifiable(unassignedEntryIds),
    );
  }

  static Future<bool> assetExistsInBundle(
    AssetBundle bundle,
    String bundleAssetKey,
  ) async {
    try {
      await bundle.load(bundleAssetKey);
      return true;
    } on Object {
      return false;
    }
  }

  static bool _isValidAssetKey(String assetKey, String locale) {
    return assetKey.startsWith('sounds/announcements/$locale/') &&
        assetKey.endsWith('.mp3') &&
        !assetKey.startsWith('/') &&
        !assetKey.contains('..') &&
        !assetKey.contains(r'\');
  }
}

class TrainingAnnouncementLocale {
  final String locale;
  final Map<String, TrainingAnnouncementEntry> entries;

  const TrainingAnnouncementLocale({
    required this.locale,
    required this.entries,
  });

  factory TrainingAnnouncementLocale.fromJson({
    required String locale,
    required Map<String, dynamic> json,
  }) {
    final rawEntries = json['entries'];
    if (rawEntries is! Map<String, dynamic> || rawEntries.isEmpty) {
      throw FormatException(
        'Announcement locale "$locale" must contain entries.',
      );
    }

    final entries = <String, TrainingAnnouncementEntry>{};
    for (final MapEntry(key: id, value: rawEntry) in rawEntries.entries) {
      if (id.trim().isEmpty || rawEntry is! Map<String, dynamic>) {
        throw FormatException(
          'Invalid announcement entry "$id" in locale "$locale".',
        );
      }
      entries[id] = TrainingAnnouncementEntry.fromJson(
        id: id,
        locale: locale,
        json: rawEntry,
      );
    }

    return TrainingAnnouncementLocale(
      locale: locale,
      entries: Map.unmodifiable(entries),
    );
  }
}

class TrainingAnnouncementEntry {
  final String id;
  final String spokenText;
  final String? assetKey;

  const TrainingAnnouncementEntry({
    required this.id,
    required this.spokenText,
    required this.assetKey,
  });

  factory TrainingAnnouncementEntry.fromJson({
    required String id,
    required String locale,
    required Map<String, dynamic> json,
  }) {
    final spokenText = json['spokenText'];
    if (spokenText is! String || spokenText.trim().isEmpty) {
      throw FormatException(
        'Announcement "$id" in "$locale" needs spokenText.',
      );
    }

    final rawAssetKey = json['assetKey'];
    if (rawAssetKey != null &&
        (rawAssetKey is! String || rawAssetKey.trim().isEmpty)) {
      throw FormatException(
        'Announcement "$id" in "$locale" has an invalid assetKey.',
      );
    }

    return TrainingAnnouncementEntry(
      id: id,
      spokenText: spokenText,
      assetKey: rawAssetKey as String?,
    );
  }
}

class AnnouncementAssetPreflightReport {
  final String locale;
  final List<String> availableAssetKeys;
  final List<String> invalidAssetKeys;
  final List<String> missingAssetKeys;
  final List<String> missingEntryIds;
  final List<String> unassignedEntryIds;

  const AnnouncementAssetPreflightReport({
    required this.locale,
    required this.availableAssetKeys,
    required this.invalidAssetKeys,
    required this.missingAssetKeys,
    required this.missingEntryIds,
    required this.unassignedEntryIds,
  });

  bool get isReady =>
      invalidAssetKeys.isEmpty &&
      missingAssetKeys.isEmpty &&
      missingEntryIds.isEmpty &&
      unassignedEntryIds.isEmpty;
}

String _normalizeLocaleTag(String locale) {
  return locale.trim().replaceAll('_', '-').toLowerCase();
}
