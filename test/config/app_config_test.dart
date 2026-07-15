import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/config/app_config.dart';

void main() {
  test('googleWebClientId defaults to empty string', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      revenueCatApiKey: 'rc-key',
    );

    expect(config.googleWebClientId, isEmpty);
  });

  test('googleWebClientId is exposed when provided', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      revenueCatApiKey: 'rc-key',
      googleWebClientId: 'google-web-client-id.apps.googleusercontent.com',
    );

    expect(
      config.googleWebClientId,
      'google-web-client-id.apps.googleusercontent.com',
    );
  });

  test('googleIosClientId defaults to empty string', () {
    const config = AppConfig(
      environment: AppEnvironment.development,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      revenueCatApiKey: 'rc-key',
    );

    expect(config.googleIosClientId, isEmpty);
  });

  test('googleIosClientId is exposed when provided', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon-key',
      revenueCatApiKey: 'rc-key',
      googleIosClientId: 'ios-client-id.apps.googleusercontent.com',
    );

    expect(
      config.googleIosClientId,
      'ios-client-id.apps.googleusercontent.com',
    );
  });
}
