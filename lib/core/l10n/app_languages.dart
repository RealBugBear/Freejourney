import 'dart:ui' show Locale;

/// One supported app language.
///
/// [code] is the ISO-639-1 code and MUST match three things at once:
/// the ARB file name (`lib/l10n/app_<code>.arb`), the `profiles.locale`
/// value synced to Supabase, and the `SupportedLocale` union in
/// `supabase/functions/_shared/notification_copy.ts`.
class AppLanguage {
  final String code;

  /// The language's own name, shown untranslated in every picker
  /// ("Deutsch", "English") — autonyms are never localized.
  final String autonym;
  final String flagEmoji;

  const AppLanguage({
    required this.code,
    required this.autonym,
    required this.flagEmoji,
  });

  Locale get locale => Locale(code);
}

/// Single source of truth for which languages the app supports.
///
/// Adding a language = add ONE entry here + follow
/// docs/I18N_ADD_LANGUAGE.md. Nothing else in lib/ may hardcode a
/// language list or a `Locale('de')`-style literal.
class AppLanguages {
  AppLanguages._();

  static const AppLanguage german =
      AppLanguage(code: 'de', autonym: 'Deutsch', flagEmoji: '🇩🇪');
  static const AppLanguage english =
      AppLanguage(code: 'en', autonym: 'English', flagEmoji: '🇬🇧');

  /// Order = display order in pickers. German (source language) first.
  static const List<AppLanguage> all = [german, english];

  /// The content source language (DE is the template ARB and the
  /// fallback of last resort for content fields).
  static const String sourceCode = 'de';

  /// What a fresh install gets when the device language is unsupported.
  static const String internationalDefault = 'en';

  static List<Locale> get locales =>
      all.map((language) => language.locale).toList(growable: false);

  static bool isSupported(String? code) =>
      code != null && all.any((language) => language.code == code);

  /// First-launch detection: keep the device language if we support it,
  /// otherwise fall back to [internationalDefault].
  static String resolveInitial(String deviceLanguageCode) =>
      isSupported(deviceLanguageCode) ? deviceLanguageCode : internationalDefault;

  /// Storage/service normalization: unknown or missing codes resolve to
  /// the source language (mirrors the server-side fallback).
  static String normalize(String? code) => isSupported(code) ? code! : sourceCode;

  static AppLanguage byCode(String code) =>
      all.firstWhere((language) => language.code == code, orElse: () => german);
}
