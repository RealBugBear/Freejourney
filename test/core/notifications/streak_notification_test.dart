// test/core/notifications/streak_notification_test.dart
import 'package:corejourney/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plans one notice per day for the coming week', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 9),
      endMinutes: 20 * 60,
      trainedToday: false,
    );
    expect(fireTimes, hasLength(7));
    expect(fireTimes.first, DateTime(2026, 8, 20, 20));
    expect(fireTimes.last, DateTime(2026, 8, 26, 20));
  });

  test('skips today once the day is done', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 9),
      endMinutes: 20 * 60,
      trainedToday: true,
    );
    expect(fireTimes, hasLength(6));
    expect(fireTimes.first, DateTime(2026, 8, 21, 20));
  });

  test('skips today when the slot has already passed', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 21),
      endMinutes: 20 * 60,
      trainedToday: false,
    );
    expect(fireTimes.first, DateTime(2026, 8, 21, 20));
  });
}
