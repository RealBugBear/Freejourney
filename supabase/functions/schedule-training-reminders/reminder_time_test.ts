import {
  assertEquals,
} from 'https://deno.land/std@0.168.0/testing/asserts.ts';

import {
  applyQuietHours,
  calculateMedianTrainingMinute,
  hasFourHourSpacing,
  isInQuietHours,
  localDateInTimezone,
  minuteOfDayInTimezone,
  softReminderMinute,
} from '../_shared/reminder_time.ts';

Deno.test('uses default adaptive time with fewer than 3 sessions', () => {
  assertEquals(calculateMedianTrainingMinute([]), 600);
  assertEquals(calculateMedianTrainingMinute([480, 540]), 600);
});

Deno.test('calculates median for odd and even session counts', () => {
  assertEquals(calculateMedianTrainingMinute([700, 600, 800]), 700);
  assertEquals(calculateMedianTrainingMinute([600, 800, 900, 1000]), 850);
});

Deno.test('detects overnight quiet hours', () => {
  assertEquals(isInQuietHours(21 * 60, 20 * 60, 8 * 60), true);
  assertEquals(isInQuietHours(7 * 60, 20 * 60, 8 * 60), true);
  assertEquals(isInQuietHours(12 * 60, 20 * 60, 8 * 60), false);
});

Deno.test('moves reminders inside quiet hours to quiet end', () => {
  assertEquals(applyQuietHours(7 * 60 + 40, 20 * 60, 8 * 60), 8 * 60);
  assertEquals(softReminderMinute([8 * 60 + 5, 8 * 60 + 10, 8 * 60 + 15], 20 * 60, 8 * 60), 8 * 60);
});

Deno.test('detects impossible four hour gap before streak warning', () => {
  assertEquals(hasFourHourSpacing(15 * 60, 19 * 60), true);
  assertEquals(hasFourHourSpacing(15 * 60 + 1, 19 * 60), false);
});

Deno.test('derives local date and minute in IANA timezone', () => {
  assertEquals(localDateInTimezone('2026-05-26T22:30:00Z', 'Europe/Berlin'), '2026-05-27');
  assertEquals(minuteOfDayInTimezone('2026-05-26T22:30:00Z', 'Europe/Berlin'), 30);
});
