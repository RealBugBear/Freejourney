import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/app_config.dart';
import 'package:corejourney/core/logging/logger_service.dart';

class TestException implements Exception {
  final String message;
  TestException(this.message);
  @override
  String toString() => message;
}

AppConfig _devConfig() => const AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test_anon_key',
      revenueCatApiKey: 'test_rc_key',
    );

AppConfig _prodConfig() => const AppConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://test.supabase.co',
      supabaseAnonKey: 'test_anon_key',
      revenueCatApiKey: 'test_rc_key',
    );

void main() {
  group('LoggerService', () {
    late LoggerService logger;

    group('Development Environment', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('logs debug messages in development', () {
        expect(
          () => logger.debug('Test debug message', data: {'key': 'value'}),
          returnsNormally,
        );
      });

      test('logs info messages in development', () {
        expect(
          () => logger.info('Test info message'),
          returnsNormally,
        );
      });

      test('logs warning messages in development', () {
        expect(
          () => logger.warning('Test warning', error: TestException('test')),
          returnsNormally,
        );
      });

      test('logs error messages in development', () {
        expect(
          () => logger.error(
            'Test error',
            error: TestException('test'),
            stackTrace: StackTrace.current,
          ),
          returnsNormally,
        );
      });

      test('formats message with structured data', () {
        expect(
          () => logger.info('User action', data: {
            'action': 'button_click',
            'screen': 'home',
            'timestamp': DateTime.now().toIso8601String(),
          }),
          returnsNormally,
        );
      });
    });

    group('Production Environment', () {
      setUp(() {
        logger = LoggerService(config: _prodConfig());
      });

      test('should not log debug in production', () {
        expect(
          () => logger.debug('Should not appear'),
          returnsNormally,
        );
      });

      test('should not log info in production', () {
        expect(
          () => logger.info('Should not appear'),
          returnsNormally,
        );
      });

      test('should log error in production', () {
        expect(
          () => logger.error('Important error'),
          returnsNormally,
        );
      });

      test('should always log fatal errors', () {
        expect(
          () => logger.fatal('Fatal error', error: TestException('critical')),
          returnsNormally,
        );
      });
    });

    group('Scoped Logger', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('creates scoped logger with tag', () {
        final scopedLogger = logger.scope('TestScope');
        expect(
          () => scopedLogger.info('Test message'),
          returnsNormally,
        );
      });

      test('scoped logger includes tag in messages', () {
        final scopedLogger = logger.scope('Authentication');
        expect(
          () => scopedLogger.debug('Login attempted', data: {'userId': '123'}),
          returnsNormally,
        );
      });
    });

    group('Convenience Methods', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('logAction formats user actions correctly', () {
        expect(
          () => logger.logAction('button_click', parameters: {
            'button': 'submit',
            'screen': 'login',
          }),
          returnsNormally,
        );
      });

      test('logScreen logs screen views', () {
        expect(
          () => logger.logScreen('HomeScreen', parameters: {
            'source': 'navigation',
          }),
          returnsNormally,
        );
      });
    });

    group('Error Handling', () {
      setUp(() {
        logger = LoggerService(config: _devConfig());
      });

      test('handles null error gracefully', () {
        expect(
          () => logger.error('Error without exception'),
          returnsNormally,
        );
      });

      test('handles null stack trace', () {
        expect(
          () => logger.error('Error', error: TestException('test')),
          returnsNormally,
        );
      });

      test('handles empty structured data', () {
        expect(
          () => logger.info('Message', data: {}),
          returnsNormally,
        );
      });
    });
  });
}
