import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';
import 'core/l10n/app_languages.dart';
import 'l10n/app_localizations.dart';

void main() {
  runZonedGuarded(_main, (error, stack) {
    debugPrint('Unhandled zone error: $error');
  });
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    final bootstrap = await Bootstrap.initialize(
      envFile: '.env.staging',
      environment: AppEnvironment.production,
    );

    bootstrap.syncService.start();

    runApp(
      ProviderScope(
        overrides: bootstrapOverrides(bootstrap),
        child: const CoreJourneyApp(),
      ),
    );
  } catch (e) {
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    // Settings are unavailable when startup failed; resolve the catalog
    // from the device language like a fresh install would.
    final l10n = lookupAppLocalizations(
      Locale(
        AppLanguages.resolveInitial(
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
        ),
      ),
    );
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              l10n.startupCouldNotStart,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
