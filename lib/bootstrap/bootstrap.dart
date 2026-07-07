import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/logging/app_logger.dart';
import '../core/notifications/notification_service.dart';
import '../core/push/push_notification_service.dart';
import '../core/storage/file_local_storage.dart';
import '../core/sync/sync_service.dart';

class Bootstrap {
  final AppConfig config;
  final AppDatabase database;
  final SyncService syncService;
  final SharedPreferences prefs;

  Bootstrap._({
    required this.config,
    required this.database,
    required this.syncService,
    required this.prefs,
  });

  // Debug file logger — writes to app Documents so devicectl can read it back.
  static File? _debugFile;
  static void _dbg(String msg) {
    dev.log('[bootstrap] $msg', name: 'cj');
    try {
      _debugFile?.writeAsStringSync('$msg\n',
          mode: FileMode.append, flush: true);
    } catch (_) {}
  }

  static Future<Bootstrap> initialize({
    required String envFile,
    required AppEnvironment environment,
  }) async {
    dev.log('[bootstrap] ensureInitialized', name: 'cj');
    WidgetsFlutterBinding.ensureInitialized();

    // Set up debug file for offline crash diagnosis
    try {
      final dir = await getApplicationDocumentsDirectory();
      _debugFile = File('${dir.path}/bootstrap_debug.txt');
      await _debugFile!.writeAsString(
        '=== BOOTSTRAP START ${DateTime.now()} ===\n',
      );
    } catch (_) {}
    _dbg('ensureInitialized OK');

    // Load environment variables
    _dbg('loading $envFile');
    await dotenv.load(fileName: envFile);
    _dbg('dotenv loaded');

    final config = AppConfig(
      environment: environment,
      supabaseUrl: dotenv.env['SUPABASE_URL']!,
      supabaseAnonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      revenueCatApiKey: dotenv.env['REVENUECAT_API_KEY'] ?? '',
      agoraAppId: dotenv.env['AGORA_APP_ID'] ?? '',
    );
    _dbg('AppConfig created, url=${config.supabaseUrl}');

    // Initialize Supabase with file-based session storage.
    //
    // FileLocalStorage writes the auth token to a JSON file in
    // getApplicationSupportDirectory() — fully persistent across launches on
    // all platforms, with zero dependency on SharedPreferences or
    // platform-specific UserDefaults channels.
    _dbg('Supabase.initialize start');
    final disableDeeplinkSessionDetection =
        Platform.isIOS && environment == AppEnvironment.development;
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        detectSessionInUri: !disableDeeplinkSessionDetection,
        localStorage: FileLocalStorage(),
      ),
    );
    _dbg('Supabase.initialize done');

    // Initialize local database.
    //
    // AppDatabase.open() uses getApplicationSupportDirectory() — the correct
    // location for app data on all platforms. Falls back to in-memory only if
    // the directory truly cannot be obtained (should never happen in production).
    _dbg('AppDatabase.open() start');
    final database = await AppDatabase.open();
    _dbg('AppDatabase.open() done');

    // Initialize sync service
    _dbg('SyncService()');
    final syncService = SyncService(database);
    _dbg('SyncService() done');

    // Initialize SharedPreferences.
    //
    // SharedPreferences is used only for lightweight settings (theme, language,
    // reminder prefs, consent flags). Session persistence has been moved to
    // FileLocalStorage above, so a SharedPreferences failure no longer causes
    // sign-out on restart.
    //
    // On iOS, if the UserDefaults channel is still unavailable, fall back to an
    // in-memory stub — settings will reset per launch but no data is lost and
    // the user stays logged in.
    _dbg('SharedPreferences.getInstance');
    SharedPreferences prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      _dbg('SharedPreferences: real instance obtained');
    } catch (e) {
      _dbg(
          'SharedPreferences: channel error ($e) — falling back to in-memory stub');
      appLogger.w('SharedPreferences: using in-memory stub ($e)');
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    }
    _dbg('SharedPreferences done');

    // Initialize local notifications
    _dbg('NotificationService.initialize start');
    final enableIosProfileNotifications =
        dotenv.env['ENABLE_IOS_PROFILE_NOTIFICATIONS'] == 'true';
    final skipNotificationInit =
        Platform.isIOS && kProfileMode && !enableIosProfileNotifications;
    if (skipNotificationInit) {
      NotificationService.instance.disable(
        'safe mode on iOS profile build '
        '(set ENABLE_IOS_PROFILE_NOTIFICATIONS=true to override)',
      );
      _dbg('NotificationService.initialize skipped for iOS/profile safe mode');
    } else {
      try {
        await NotificationService.instance.initialize();
        _dbg('NotificationService.initialize done');
      } catch (e) {
        _dbg('NotificationService.initialize FAILED: $e');
        appLogger.w('NotificationService init skipped: $e');
      }
    }

    // Initialize remote push notifications. Token registration is retried after
    // sign-in from app.dart, because auth may not be ready during cold start.
    _dbg('PushNotificationService.initialize start');
    try {
      await PushNotificationService.instance.initialize(
        environment: environment,
      );
      _dbg('PushNotificationService.initialize done');
    } catch (e) {
      _dbg('PushNotificationService.initialize FAILED: $e');
      appLogger.w('Push notification init skipped: $e');
    }

    appLogger.i('Bootstrap complete [${config.envLabel}]');
    _dbg('BOOTSTRAP COMPLETE');

    return Bootstrap._(
      config: config,
      database: database,
      syncService: syncService,
      prefs: prefs,
    );
  }
}
