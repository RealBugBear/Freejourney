import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../settings/settings_provider.dart' show languagePreferenceKey;
import 'app_languages.dart';

/// Resolves the ARB catalog for the active app language in headless
/// contexts (push handlers, background services) where no localized
/// BuildContext exists.
///
/// Reads the persisted language choice; on a fresh install it mirrors
/// SettingsNotifier's first-launch detection from the device language.
Future<AppLocalizations> lookupActiveAppLocalizations() async {
  String? saved;
  try {
    final prefs = await SharedPreferences.getInstance();
    saved = prefs.getString(languagePreferenceKey);
  } catch (_) {
    saved = null;
  }
  final code = saved != null
      ? AppLanguages.normalize(saved)
      : AppLanguages.resolveInitial(
          PlatformDispatcher.instance.locale.languageCode,
        );
  return lookupAppLocalizations(Locale(code));
}
