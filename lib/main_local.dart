// Local simulator smoke target. This target can never use production services.
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'bootstrap/bootstrap.dart';
import 'bootstrap/providers.dart';
import 'config/app_config.dart';

Future<void> main() async {
  const url = String.fromEnvironment('LOCAL_SUPABASE_URL');
  const key = String.fromEnvironment('LOCAL_SUPABASE_ANON_KEY');
  final uri = Uri.tryParse(url);
  if (kReleaseMode ||
      uri?.scheme != 'http' ||
      !['127.0.0.1', 'localhost'].contains(uri?.host) ||
      key.isEmpty) {
    throw StateError(
        'Local smoke target requires loopback configuration and debug mode');
  }
  final bootstrap = await Bootstrap.initialize(
    envFile: '.env.dev',
    environment: AppEnvironment.development,
    enableRemoteServices: false,
    configOverride: AppConfig(
        environment: AppEnvironment.development,
        supabaseUrl: url,
        supabaseAnonKey: key,
        revenueCatApiKey: ''),
  );
  bootstrap.syncService.start();
  runApp(ProviderScope(
      overrides: bootstrapOverrides(bootstrap), child: const CoreJourneyApp()));
}
