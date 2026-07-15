import 'package:corejourney/features/profile/domain/models/profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': 'abc',
        'display_name': 'Maria',
        'is_anonymous_default': true,
      };
      final p = Profile.fromJson(json);
      expect(p.userId, 'abc');
      expect(p.displayName, 'Maria');
      expect(p.isAnonymousDefault, true);
    });

    test('fromJson handles null display_name', () {
      final json = {
        'id': 'abc',
        'display_name': null,
        'is_anonymous_default': false
      };
      final p = Profile.fromJson(json);
      expect(p.displayName, isNull);
      expect(p.effectiveDisplayName('Anonymous'), 'Anonymous');
    });

    test('effectiveDisplayName returns name when set', () {
      const p = Profile(userId: 'x', displayName: 'Karl');
      expect(p.effectiveDisplayName('Anonymous'), 'Karl');
    });

    test('toJson round-trips', () {
      const p =
          Profile(userId: 'x', displayName: 'Tina', isAnonymousDefault: false);
      final json = p.toJson();
      final p2 = Profile.fromJson(json);
      expect(p2.displayName, 'Tina');
    });
  });
}
