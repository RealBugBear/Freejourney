import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/auth/data/repositories/supabase_auth_repository.dart';

void main() {
  group('resolveGoogleClientIds', () {
    test('uses iOS client id on iOS and web id as server id', () {
      final ids = resolveGoogleClientIds(
        isIOS: true,
        googleIosClientId: 'ios-client-id.apps.googleusercontent.com',
        googleWebClientId: 'web-client-id.apps.googleusercontent.com',
      );

      expect(ids.clientId, 'ios-client-id.apps.googleusercontent.com');
      expect(ids.serverClientId, 'web-client-id.apps.googleusercontent.com');
    });

    test('on iOS with missing iOS client id returns missingConfig=true', () {
      final ids = resolveGoogleClientIds(
        isIOS: true,
        googleIosClientId: '',
        googleWebClientId: 'web-client-id.apps.googleusercontent.com',
      );

      expect(ids.missingConfig, isTrue);
    });

    test('on non-iOS only server client id is set', () {
      final ids = resolveGoogleClientIds(
        isIOS: false,
        googleIosClientId: '',
        googleWebClientId: 'web-client-id.apps.googleusercontent.com',
      );

      expect(ids.clientId, isNull);
      expect(ids.serverClientId, 'web-client-id.apps.googleusercontent.com');
      expect(ids.missingConfig, isFalse);
    });
  });
}
