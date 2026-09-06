import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'package:corejourney/core/monitoring/sentry_service.dart';

void main() {
  group('SentryService privacy filters', () {
    test('drops events that carry HTTP request context', () {
      final event = SentryEvent(
        throwable: StateError('test'),
        request: SentryRequest(url: 'https://example.com/secret'),
      );

      expect(SentryService.filterEventForSend(event), isNull);
    });

    test('clears extras on events without request context', () {
      final event = SentryEvent(
        throwable: StateError('test'),
        extra: {'journal': 'should not leak'},
      );

      final filtered = SentryService.filterEventForSend(event);
      expect(filtered, isNotNull);
      expect(filtered!.extra, isEmpty);
    });

    test('drops http and navigation breadcrumbs', () {
      expect(
        SentryService.filterBreadcrumb(Breadcrumb(type: 'http')),
        isNull,
      );
      expect(
        SentryService.filterBreadcrumb(Breadcrumb(type: 'navigation')),
        isNull,
      );
      expect(
        SentryService.filterBreadcrumb(Breadcrumb(type: 'debug')),
        isNotNull,
      );
    });
  });
}
