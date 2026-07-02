import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';

void main() {
  runZonedGuarded(_main, (error, stack) {
    // Swallow zone errors silently in production — no stack traces exposed.
    debugPrint('Zone error: $error');
  });
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  try {
    final bootstrap = await Bootstrap.initialize(
      envFile: '.env.prod',
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
    // Generic error screen — no internal details exposed.
    runApp(const _StartupErrorApp());
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Reflex Journey could not start. Please restart the app or reinstall.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
