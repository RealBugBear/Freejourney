export const DEFAULT_TRAINING_MINUTE = 10 * 60;

export function minuteOfDayInTimezone(utcIso: string, timezone: string): number {
  const parts = zonedParts(utcIso, timezone);
  return parts.hour * 60 + parts.minute;
}

export function localDateInTimezone(utcIso: string, timezone: string): string {
  const parts = zonedParts(utcIso, timezone);
  return [
    parts.year.toString().padStart(4, '0'),
    parts.month.toString().padStart(2, '0'),
    parts.day.toString().padStart(2, '0'),
  ].join('-');
}

export function isInQuietHours(
  minuteOfDay: number,
  quietStartMinutes: number,
  quietEndMinutes: number,
): boolean {
  const minute = normalizeMinute(minuteOfDay);
  const start = normalizeMinute(quietStartMinutes);
  const end = normalizeMinute(quietEndMinutes);

  if (start === end) return false;
  if (start < end) return minute >= start && minute < end;
  return minute >= start || minute < end;
}

export function calculateMedianTrainingMinute(minutes: number[]): number {
  const normalized = minutes
    .filter((minute) => Number.isFinite(minute))
    .map((minute) => normalizeMinute(Math.round(minute)))
    .sort((a, b) => a - b);

  if (normalized.length < 3) return DEFAULT_TRAINING_MINUTE;

  const middle = Math.floor(normalized.length / 2);
  if (normalized.length % 2 === 1) return normalized[middle];
  return Math.round((normalized[middle - 1] + normalized[middle]) / 2);
}

export function applyQuietHours(
  minute: number,
  quietStartMinutes: number,
  quietEndMinutes: number,
): number {
  const normalized = normalizeMinute(minute);
  if (!isInQuietHours(normalized, quietStartMinutes, quietEndMinutes)) {
    return normalized;
  }
  return normalizeMinute(quietEndMinutes);
}

export function softReminderMinute(
  trainingMinutes: number[],
  quietStartMinutes: number,
  quietEndMinutes: number,
): number {
  return applyQuietHours(
    calculateMedianTrainingMinute(trainingMinutes) - 20,
    quietStartMinutes,
    quietEndMinutes,
  );
}

export function hasFourHourSpacing(
  earlierMinute: number,
  laterMinute: number,
): boolean {
  return normalizeMinute(laterMinute) - normalizeMinute(earlierMinute) >= 4 * 60;
}

export function minuteToTime(minute: number): string {
  const normalized = normalizeMinute(minute);
  const hour = Math.floor(normalized / 60);
  const min = normalized % 60;
  return `${hour.toString().padStart(2, '0')}:${min.toString().padStart(2, '0')}:00`;
}

export function addDaysToLocalDate(localDate: string, days: number): string {
  const [year, month, day] = localDate.split('-').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day + days));
  return date.toISOString().slice(0, 10);
}

function normalizeMinute(minute: number): number {
  const day = 24 * 60;
  return ((minute % day) + day) % day;
}

function zonedParts(utcIso: string, timezone: string): {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
} {
  const date = new Date(utcIso);
  if (Number.isNaN(date.getTime())) {
    throw new Error(`Invalid ISO timestamp: ${utcIso}`);
  }

  const formatter = new Intl.DateTimeFormat('en-CA', {
    timeZone: timezone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });

  const values = new Map(
    formatter.formatToParts(date).map((part) => [part.type, part.value]),
  );

  return {
    year: Number(values.get('year')),
    month: Number(values.get('month')),
    day: Number(values.get('day')),
    hour: Number(values.get('hour')),
    minute: Number(values.get('minute')),
  };
}
