// lib/config/app_config.dart

enum AppEnvironment { development, production }

class AppConfig {
  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatApiKey;
  final String agoraAppId;
  final String googleWebClientId;
  final String googleIosClientId;

  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatApiKey,
    this.agoraAppId = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
  });

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isProduction => environment == AppEnvironment.production;

  String get envLabel => isDevelopment ? 'DEV' : 'PROD';
}
