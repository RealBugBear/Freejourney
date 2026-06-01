import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/providers.dart';
import 'logger_service.dart';

/// Provider for the logger service
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return LoggerService(config: ref.watch(appConfigProvider));
});

/// Provider for scoped loggers
/// Usage: ref.watch(scopedLoggerProvider('FeatureName'))
final scopedLoggerProvider = Provider.family<ScopedLogger, String>((ref, tag) {
  final logger = ref.watch(loggerServiceProvider);
  return logger.scope(tag);
});
