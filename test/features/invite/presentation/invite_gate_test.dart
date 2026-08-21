import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/launch_flags.dart';

void main() {
  test('kInviteEnabled is off until Phase-5 device checks pass', () {
    expect(kInviteEnabled, isFalse);
  });
}
