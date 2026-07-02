import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/logging/app_logger.dart';

class TimeSlot {
  final DateTime start;
  final DateTime end;

  const TimeSlot({required this.start, required this.end});

  String get formattedRange {
    final s =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return '$s – $e';
  }
}

/// Creates an RFC5545 iCalendar file and hands it off through the native
/// share sheet. This avoids direct EventKit integration in the app binary,
/// which is more resilient against iOS calendar permission changes.
class CalendarService {
  CalendarService._();
  static final CalendarService instance = CalendarService._();
  static const _channel = MethodChannel('corejourney/calendar');

  Future<void> createCalendarEvent({
    required String title,
    required DateTime start,
    required Duration duration,
    String? location,
    String? description,
    Rect? sharePositionOrigin,
  }) async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        await _createNativeCalendarEvent(
          title: title,
          start: start,
          duration: duration,
          location: location,
          description: description,
        );
        appLogger.d('CalendarService: created native calendar event');
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'reflexjourney_${start.millisecondsSinceEpoch}_${_sanitizeFileSegment(title)}.ics';
      final calendarFile = File('${tempDir.path}/$fileName');
      final end = start.add(duration);

      await calendarFile.writeAsString(
        _buildIcs(
          title: title,
          start: start,
          end: end,
          location: location,
          description: description,
        ),
        flush: true,
      );

      await Share.shareXFiles(
        [XFile(calendarFile.path, mimeType: 'text/calendar')],
        subject: title,
        text: 'Kalendereintrag für $title importieren',
        sharePositionOrigin:
            sharePositionOrigin ?? const Rect.fromLTWH(1, 1, 1, 1),
        fileNameOverrides: [fileName],
      );
      appLogger.d('CalendarService: shared calendar import file');
    } catch (e, st) {
      appLogger.e(
        'CalendarService: failed to share calendar import file',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<void> _createNativeCalendarEvent({
    required String title,
    required DateTime start,
    required Duration duration,
    String? location,
    String? description,
  }) async {
    await _channel.invokeMethod<String>('createEvent', {
      'title': title,
      'startMs': start.millisecondsSinceEpoch.toDouble(),
      'durationMinutes': duration.inMinutes.toDouble(),
      if ((location ?? '').trim().isNotEmpty) 'location': location!.trim(),
      if ((description ?? '').trim().isNotEmpty)
        'description': description!.trim(),
    });
  }

  String _buildIcs({
    required String title,
    required DateTime start,
    required DateTime end,
    String? location,
    String? description,
  }) {
    final nowUtc = DateTime.now().toUtc();
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();
    final uid =
        'reflexjourney-${startUtc.millisecondsSinceEpoch}-${title.hashCode.abs()}@reflexjourney.app';

    final fields = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Reflex Journey//Appointments//DE',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_formatUtc(nowUtc)}',
      'DTSTART:${_formatUtc(startUtc)}',
      'DTEND:${_formatUtc(endUtc)}',
      'SUMMARY:${_escapeIcsText(title)}',
    ];

    if ((location ?? '').trim().isNotEmpty) {
      fields.add('LOCATION:${_escapeIcsText(location!.trim())}');
    }
    if ((description ?? '').trim().isNotEmpty) {
      fields.add('DESCRIPTION:${_escapeIcsText(description!.trim())}');
    }

    fields.addAll([
      'END:VEVENT',
      'END:VCALENDAR',
      '',
    ]);

    return fields.join('\r\n');
  }

  String _formatUtc(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    final h = value.hour.toString().padLeft(2, '0');
    final min = value.minute.toString().padLeft(2, '0');
    final s = value.second.toString().padLeft(2, '0');
    return '$y$m${d}T$h$min${s}Z';
  }

  String _escapeIcsText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll(';', r'\;')
        .replaceAll(',', r'\,')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n');
  }

  String _sanitizeFileSegment(String value) {
    final sanitized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return sanitized.isEmpty ? 'appointment' : sanitized;
  }
}
