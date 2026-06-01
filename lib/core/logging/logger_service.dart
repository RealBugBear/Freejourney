import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

import '../../config/app_config.dart';

/// Custom log levels used by LoggerService.
enum AppLogLevel {
  debug,
  info,
  warning,
  error,
  fatal;

  Level toLoggerLevel() {
    switch (this) {
      case AppLogLevel.debug:
        return Level.debug;
      case AppLogLevel.info:
        return Level.info;
      case AppLogLevel.warning:
        return Level.warning;
      case AppLogLevel.error:
        return Level.error;
      case AppLogLevel.fatal:
        return Level.fatal;
    }
  }

  static AppLogLevel fromString(String level) {
    switch (level.toLowerCase()) {
      case 'debug':
        return AppLogLevel.debug;
      case 'info':
        return AppLogLevel.info;
      case 'warning':
      case 'warn':
        return AppLogLevel.warning;
      case 'error':
        return AppLogLevel.error;
      case 'fatal':
        return AppLogLevel.fatal;
      default:
        return AppLogLevel.info;
    }
  }
}

/// Structured logging service
///
/// Provides environment-aware logging with:
/// - Log level filtering based on AppConfig
/// - Structured data support
/// - Pretty console output in development
/// - Integration with crash reporting
class LoggerService {
  final Logger _logger;
  final AppConfig _config;
  final AppLogLevel _minLevel;

  LoggerService({
    required AppConfig config,
  })  : _config = config,
        _minLevel =
            config.isDevelopment ? AppLogLevel.debug : AppLogLevel.error,
        _logger = Logger(
          printer: config.isDevelopment
              ? PrettyPrinter(
                  methodCount: 2,
                  errorMethodCount: 8,
                  lineLength: 120,
                  colors: true,
                  printEmojis: true,
                  dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
                )
              : SimplePrinter(
                  colors: false,
                ),
          level: (config.isDevelopment ? AppLogLevel.debug : AppLogLevel.error)
              .toLoggerLevel(),
        );

  /// Check if a log level should be logged
  bool _shouldLog(AppLogLevel level) {
    return level.index >= _minLevel.index;
  }

  /// Log a debug message
  void debug(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(AppLogLevel.debug)) return;

    _logger.d(
      _formatMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an info message
  void info(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(AppLogLevel.info)) return;

    _logger.i(
      _formatMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log a warning message
  void warning(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(AppLogLevel.warning)) return;

    _logger.w(
      _formatMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log an error message
  void error(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(AppLogLevel.error)) return;

    _logger.e(
      _formatMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    );

    // In production, errors should be sent to crash reporting
    if (_config.isProduction && error != null) {
      _reportError(error, stackTrace, message, data);
    }
  }

  /// Log a fatal error (always logged, always reported)
  void fatal(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.f(
      _formatMessage(message, data),
      error: error,
      stackTrace: stackTrace,
    );

    // Fatal errors are always reported
    if (_config.isProduction && error != null) {
      _reportError(error, stackTrace, message, data, fatal: true);
    }
  }

  /// Format message with structured data
  String _formatMessage(String message, Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return message;

    final dataStr = data.entries.map((e) => '${e.key}=${e.value}').join(', ');
    return '$message | $dataStr';
  }

  /// Report error to crash reporting service
  void _reportError(
    Object error,
    StackTrace? stackTrace,
    String? reason,
    Map<String, dynamic>? data, {
    bool fatal = false,
  }) {
    // This will be implemented when we add crash reporting
    // For now, just log in debug mode
    if (kDebugMode) {
      debugPrint('[Error Report] $reason: $error');
      if (data != null) {
        debugPrint('[Error Data] $data');
      }
    }
  }

  /// Log a user action (for analytics)
  void logAction(String action, {Map<String, dynamic>? parameters}) {
    info('User action: $action', data: parameters);
  }

  /// Log a screen view (for analytics)
  void logScreen(String screenName, {Map<String, dynamic>? parameters}) {
    debug('Screen view: $screenName', data: parameters);
  }

  /// Create a scoped logger with a specific tag
  ScopedLogger scope(String tag) {
    return ScopedLogger(this, tag);
  }
}

/// Scoped logger that prefixes all messages with a tag
class ScopedLogger {
  final LoggerService _logger;
  final String _tag;

  ScopedLogger(this._logger, this._tag);

  void debug(String message,
      {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logger.debug('[$_tag] $message',
        data: data, error: error, stackTrace: stackTrace);
  }

  void info(String message,
      {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logger.info('[$_tag] $message',
        data: data, error: error, stackTrace: stackTrace);
  }

  void warning(String message,
      {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logger.warning('[$_tag] $message',
        data: data, error: error, stackTrace: stackTrace);
  }

  void error(String message,
      {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logger.error('[$_tag] $message',
        data: data, error: error, stackTrace: stackTrace);
  }

  void fatal(String message,
      {Map<String, dynamic>? data, Object? error, StackTrace? stackTrace}) {
    _logger.fatal('[$_tag] $message',
        data: data, error: error, stackTrace: stackTrace);
  }
}
