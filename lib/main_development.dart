import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';
import 'core/l10n/app_languages.dart';
import 'l10n/app_localizations.dart';

// Write to TMPDIR (sandbox temp dir) — readable via devicectl without path_provider
File? _dbgFile;
void _dbg(String msg) {
  dev.log(msg, name: 'cj');
  try {
    final f = _dbgFile ??= File('${Directory.systemTemp.path}/cj_launch.txt');
    f.writeAsStringSync('$msg\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}

void main() {
  _dbg('main() entered');
  runZonedGuarded(_main, (error, stack) {
    _dbg('Unhandled zone error: $error');
    debugPrint('Unhandled zone error: $error\n$stack');
  });
}

Future<void> _main() async {
  _dbg('_main() started');
  WidgetsFlutterBinding.ensureInitialized();

  // Make widget-tree build errors visible (text) instead of blank white screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Error: ${details.exceptionAsString()}',
          style: const TextStyle(color: Colors.red, fontSize: 13),
        ),
      ),
    );
  };

  // Forward Flutter framework errors to the console.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    dev.log('FlutterError: ${details.exceptionAsString()}', name: 'cj');
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Catch ALL unhandled Dart exceptions (including async, provider init, etc.)
  // that would otherwise silently kill the isolate and show a blank screen.
  PlatformDispatcher.instance.onError = (error, stack) {
    dev.log('Unhandled platform error: $error\n$stack', name: 'cj');
    debugPrint('Unhandled platform error: $error\n$stack');
    return true; // handled — prevents OS crash dialog
  };

  runApp(const _DevelopmentBootstrapApp());
}

class _DevelopmentBootstrapApp extends StatefulWidget {
  const _DevelopmentBootstrapApp();

  @override
  State<_DevelopmentBootstrapApp> createState() =>
      _DevelopmentBootstrapAppState();
}

class _DevelopmentBootstrapAppState extends State<_DevelopmentBootstrapApp> {
  Widget? _app;
  String _status = 'Starting DEV bootstrap...';
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      _dbg('[DevelopmentBootstrap] initialization started');
      _setStatus('Loading .env.dev');
      _dbg('[DevelopmentBootstrap] calling Bootstrap.initialize');
      final bootstrap = await Bootstrap.initialize(
        envFile: '.env.dev',
        environment: AppEnvironment.development,
      );
      _dbg('[DevelopmentBootstrap] Bootstrap.initialize completed');

      _setStatus('Starting sync service');
      bootstrap.syncService.start();
      _dbg('[DevelopmentBootstrap] SyncService started');

      if (!mounted) return;
      _dbg('[DevelopmentBootstrap] mounting CoreJourneyApp');
      setState(() {
        _app = ProviderScope(
          overrides: bootstrapOverrides(bootstrap),
          child: const CoreJourneyApp(),
        );
      });
      _dbg('[DevelopmentBootstrap] app is running');
    } catch (e, st) {
      _dbg('[DevelopmentBootstrap] initialization failed: $e');
      debugPrint('Bootstrap failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _setStatus(String status) {
    dev.log(status, name: 'cj');
    if (!mounted) return;
    setState(() {
      _status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_app != null) return _app!;

    // Boot-status copy stays deliberately English-technical (dev flavor);
    // only the visible failure heading is localized, resolved from the
    // device language because no localized context exists yet.
    final l10n = lookupAppLocalizations(
      Locale(
        AppLanguages.resolveInitial(
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
        ),
      ),
    );
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF1565C0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _error == null ? Icons.sync : Icons.error_outline,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  _error == null
                      ? 'Reflex Journey DEV booting'
                      : l10n.startupBootstrapFailedTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? _status,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
                if (_error == null) ...[
                  const SizedBox(height: 24),
                  const LinearProgressIndicator(color: Colors.white),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
