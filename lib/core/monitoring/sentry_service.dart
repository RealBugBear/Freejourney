import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../config/app_config.dart';
import '../logging/app_logger.dart';

/// DSGVO-schonendes Crash-Reporting (T15, Founder-Entscheidung 8.6: Sentry
/// mit EU-Datenhaltung).
///
/// Datenschutz-Vertrag:
/// - Nur aktiv, wenn `SENTRY_DSN` in der gebündelten Env-Datei gesetzt ist.
///   Dev-Builds haben den Key bewusst nicht (kein Rauschen); der Founder
///   trägt den EU-DSN lokal in `.env.prod` ein — nie ins Repo.
/// - `sendDefaultPii=false`, kein Performance-Tracing, kein Session-Replay,
///   keine Screenshots/View-Hierarchien.
/// - `beforeSend` strippt Request-, User- und Extra-Daten; HTTP- und
///   Navigations-Breadcrumbs werden verworfen (keine URLs, keine
///   Journal-/Chat-Inhalte). Gesendet werden Fehlertyp, Stacktrace,
///   Geräte-/OS-Kontext, App-Release und Flavor.
class SentryService {
  SentryService._();

  static bool _active = false;

  /// Ob Sentry initialisiert wurde (DSN vorhanden und Init erfolgreich).
  static bool get isActive => _active;

  static Future<void> init({required AppEnvironment environment}) async {
    final dsn = dotenv.env['SENTRY_DSN'] ?? '';
    if (dsn.isEmpty) return;

    String release = 'reflexjourney@unknown';
    try {
      final info = await PackageInfo.fromPlatform();
      release = 'reflexjourney@${info.version}+${info.buildNumber}';
    } catch (_) {}

    try {
      await SentryFlutter.init((options) {
        options
          ..dsn = dsn
          ..environment = environment == AppEnvironment.production
              ? 'production'
              : 'development'
          ..release = release
          ..sendDefaultPii = false
          ..tracesSampleRate = 0
          ..attachScreenshot = false
          ..attachViewHierarchy = false
          ..beforeSend = _beforeSend
          ..beforeBreadcrumb = _beforeBreadcrumb;
      });
      _active = true;
    } catch (e) {
      // Crash-Reporting darf den App-Start nie gefährden.
      appLogger.w('Sentry initialization failed: $e');
    }
  }

  /// Defense in depth zu `sendDefaultPii=false`: alles außer Fehler,
  /// Stacktrace und Geräte-Kontext entfernen. `request`/`user` sind in
  /// sentry 8.x final und bleiben ungesetzt, weil kein PII-Autocapture und
  /// keine HTTP-Integration registriert ist — hängt doch je ein Request an,
  /// wird das Event lieber verworfen als geleakt.
  static SentryEvent? _beforeSend(SentryEvent event, Hint hint) {
    if (event.request != null) return null;
    event.extra?.clear();
    return event;
  }

  static Breadcrumb? _beforeBreadcrumb(Breadcrumb? crumb, Hint hint) {
    final type = crumb?.type;
    if (type == 'http' || type == 'navigation') return null;
    return crumb;
  }

  /// Fehler an Sentry melden — bewusst nur Fehlerobjekt + Stacktrace,
  /// keine Message-Strings oder strukturierte Nutzdaten (könnten
  /// Gesundheitsdaten enthalten). No-op, solange Sentry inaktiv ist.
  static Future<void> captureException(
    Object error, [
    StackTrace? stackTrace,
  ]) async {
    if (!_active) return;
    try {
      await Sentry.captureException(error, stackTrace: stackTrace);
    } catch (_) {}
  }
}
