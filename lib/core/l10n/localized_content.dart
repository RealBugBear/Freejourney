import 'app_languages.dart';

/// Resolves bilingual content-field pairs (the `*De`/`*En` model pattern
/// backed by the `_de`/`_en` DB columns).
///
/// THE one place that knows the content-fallback policy:
/// requested language if it is German, otherwise the English variant
/// (English doubles as the international fallback until more content
/// languages exist). When a third content language is added, extend THIS
/// function and the model fields together — see docs/I18N_ADD_LANGUAGE.md.
T pickLocalized<T>(String locale, {required T de, required T en}) =>
    locale == AppLanguages.sourceCode ? de : en;
