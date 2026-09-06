import 'dart:convert';
import 'dart:io';
import 'package:corejourney/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
      'Apple challenge and Supabase verification share a fresh nonce per attempt',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final requests = <Map<String, dynamic>>[];
    final challenges = <String>[];
    final subscription = server.listen((request) async {
      requests.add(jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>);
      request.response.statusCode = 400;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
          jsonEncode({'error': 'invalid_token', 'msg': 'Synthetic rejection'}));
      await request.response.close();
    });
    final client =
        SupabaseClient('http://127.0.0.1:${server.port}', 'local-test-key');
    final repository =
        SupabaseAuthRepository(client, appleIdentityToken: (nonce) async {
      challenges.add(nonce);
      return 'synthetic-identity-token';
    });
    try {
      await expectLater(
          repository.signInWithApple(), throwsA(isA<AuthException>()));
      await expectLater(
          repository.signInWithApple(), throwsA(isA<AuthException>()));
      expect(requests, hasLength(2));
      expect(challenges[0], isNot(challenges[1]));
      for (var i = 0; i < 2; i++) {
        final raw = requests[i]['nonce'] as String;
        expect(raw.length, greaterThanOrEqualTo(20));
        expect(challenges[i], sha256.convert(utf8.encode(raw)).toString());
        expect(requests[i]['provider'], 'apple');
      }
    } finally {
      await client.dispose();
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
