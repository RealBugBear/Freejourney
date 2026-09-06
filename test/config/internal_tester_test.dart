import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/internal_tester.dart';

void main() {
  group('isInternalTesterEmail', () {
    test('allows @reflexjourney.de team accounts', () {
      expect(isInternalTesterEmail('founder@reflexjourney.de'), isTrue);
      expect(isInternalTesterEmail('Founder@ReflexJourney.DE'), isTrue);
    });

    test('allows closed-beta allowlist emails', () {
      expect(isInternalTesterEmail('vowef83133@neowd.com'), isTrue);
    });

    test('rejects regular beta tester emails', () {
      expect(isInternalTesterEmail('tester@gmail.com'), isFalse);
      expect(isInternalTesterEmail(''), isFalse);
    });
  });
}
