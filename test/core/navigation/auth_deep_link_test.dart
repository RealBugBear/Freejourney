import 'package:corejourney/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('classifyAuthDeepLink', () {
    test('matches universal reset-password link (with token_hash)', () {
      final uri = Uri.parse(
          'https://reflexjourney.app/auth/reset-password?token_hash=abc&type=recovery');
      expect(classifyAuthDeepLink(uri), AuthDeepLink.resetPassword);
    });

    test('matches custom-scheme reset-password link', () {
      final uri = Uri.parse('reflexjourney://auth/reset-password');
      expect(classifyAuthDeepLink(uri), AuthDeepLink.resetPassword);
    });

    test('matches universal confirm link (with token_hash)', () {
      final uri = Uri.parse(
          'https://reflexjourney.app/auth/confirm?token_hash=abc&type=signup');
      expect(classifyAuthDeepLink(uri), AuthDeepLink.confirmSignup);
    });

    test('matches custom-scheme confirm link', () {
      final uri = Uri.parse('reflexjourney://auth/confirm');
      expect(classifyAuthDeepLink(uri), AuthDeepLink.confirmSignup);
    });

    test('ignores unrelated paths on the app domain', () {
      expect(
        classifyAuthDeepLink(Uri.parse('https://reflexjourney.app/')),
        AuthDeepLink.none,
      );
      expect(
        classifyAuthDeepLink(Uri.parse('https://reflexjourney.app/auth/other')),
        AuthDeepLink.none,
      );
    });

    test('does not treat an https host named auth as custom-scheme shape', () {
      expect(
        classifyAuthDeepLink(Uri.parse('https://auth/reset-password')),
        AuthDeepLink.none,
      );
    });
  });
}
