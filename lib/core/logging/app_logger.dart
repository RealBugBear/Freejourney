import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Console and crash-reporting boundary. Production logs never stringify caller
/// messages or exception bodies, which may contain child/journal/auth data.
class AppLogger extends Logger {
  AppLogger({bool? production, LogOutput? output})
      : _production = production ?? !kDebugMode,
        super(
          filter: ProductionFilter(),
          output: output,
          printer: SimplePrinter(colors: false, printTime: true),
        );

  final bool _production;
  void Function(Object error, StackTrace? stack)? reportError;

  @override
  void log(Level level, dynamic message,
      {DateTime? time, Object? error, StackTrace? stackTrace}) {
    if (_production && level.index < Level.warning.index) return;
    if (level.index >= Level.error.index && error != null) {
      reportError?.call(error, stackTrace);
    }
    super.log(level, _production ? 'Application ${level.name}' : message,
        time: time,
        error: _production ? error?.runtimeType : error,
        stackTrace: stackTrace);
  }
}

final appLogger = AppLogger();
