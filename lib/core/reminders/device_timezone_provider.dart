import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLastSyncedTimezone = 'reminders.lastSyncedTimezone';

class DeviceTimezoneProvider {
  DeviceTimezoneProvider({
    required SharedPreferences prefs,
    MethodChannel channel = const MethodChannel('corejourney/timezone'),
    Future<String> Function()? resolver,
  })  : _prefs = prefs,
        _channel = channel,
        _resolver = resolver;

  final SharedPreferences _prefs;
  final MethodChannel _channel;
  final Future<String> Function()? _resolver;

  Future<String> currentTimezone() async {
    final timezone = _resolver != null
        ? await _resolver()
        : await _channel.invokeMethod<String>('getIanaTimezone');
    final normalized = timezone?.trim();
    final looksLikeIana =
        normalized != null && (normalized == 'UTC' || normalized.contains('/'));
    if (normalized == null || normalized.isEmpty || !looksLikeIana) {
      throw StateError('Device timezone is not a valid IANA timezone.');
    }
    return normalized;
  }

  String? get lastSyncedTimezone => _prefs.getString(_kLastSyncedTimezone);

  Future<bool> markSyncedIfChanged(String timezone) async {
    if (lastSyncedTimezone == timezone) return false;
    await _prefs.setString(_kLastSyncedTimezone, timezone);
    return true;
  }
}
