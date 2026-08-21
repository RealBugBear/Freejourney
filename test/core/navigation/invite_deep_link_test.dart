import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/core/navigation/invite_deep_link.dart';

void main() {
  group('parseInviteDeepLink', () {
    test('matches DE and EN https paths with code on reflexjourney.app', () {
      final de = parseInviteDeepLink(
        Uri.parse('https://reflexjourney.app/einladung?c=ABCDEFGH'),
      );
      expect(de, isNotNull);
      expect(de!.code, 'ABCDEFGH');

      final en = parseInviteDeepLink(
        Uri.parse('https://reflexjourney.app/en/einladung?c=XYZ23456'),
      );
      expect(en, isNotNull);
      expect(en!.code, 'XYZ23456');
    });

    test('matches path without code', () {
      final link = parseInviteDeepLink(
        Uri.parse('https://reflexjourney.app/einladung'),
      );
      expect(link, isNotNull);
      expect(link!.code, isNull);
    });

    test('matches custom scheme', () {
      final link = parseInviteDeepLink(
        Uri.parse('reflexjourney://einladung?c=ABCDEFGH'),
      );
      expect(link, isNotNull);
      expect(link!.code, 'ABCDEFGH');
    });

    test('ignores unrelated paths', () {
      expect(
        parseInviteDeepLink(Uri.parse('https://reflexjourney.app/')),
        isNull,
      );
      expect(
        parseInviteDeepLink(
          Uri.parse('https://reflexjourney.app/auth/reset-password'),
        ),
        isNull,
      );
    });

    test('ignores invite path on other https hosts', () {
      expect(
        parseInviteDeepLink(
          Uri.parse('https://evil.example/einladung?c=ABCDEFGH'),
        ),
        isNull,
      );
      expect(
        parseInviteDeepLink(
          Uri.parse('http://reflexjourney.app/einladung?c=ABCDEFGH'),
        ),
        isNull,
      );
    });
  });
}
