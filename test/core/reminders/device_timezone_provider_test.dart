import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:corejourney/core/reminders/device_timezone_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('returns IANA timezone from resolver', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = DeviceTimezoneProvider(
      prefs: prefs,
      resolver: () async => 'Europe/Berlin',
    );

    expect(await provider.currentTimezone(), 'Europe/Berlin');
  });

  test('rejects non-IANA timezone abbreviation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = DeviceTimezoneProvider(
      prefs: prefs,
      resolver: () async => 'CEST',
    );

    expect(provider.currentTimezone(), throwsStateError);
  });

  test('markSyncedIfChanged writes only when changed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final provider = DeviceTimezoneProvider(
      prefs: prefs,
      resolver: () async => 'Europe/Berlin',
    );

    expect(await provider.markSyncedIfChanged('Europe/Berlin'), true);
    expect(await provider.markSyncedIfChanged('Europe/Berlin'), false);
    expect(provider.lastSyncedTimezone, 'Europe/Berlin');
  });
}
