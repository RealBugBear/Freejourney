import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final String _googleWebClientId;
  final String _googleIosClientId;
  final bool _isIOS;
  static bool _googleInitialized = false;

  SupabaseAuthRepository(
    this._client, {
    String googleWebClientId = '',
    String googleIosClientId = '',
    bool? isIOSOverride,
  })  : _googleSignIn = GoogleSignIn.instance,
        _googleWebClientId = googleWebClientId,
        _googleIosClientId = googleIosClientId,
        _isIOS = isIOSOverride ?? Platform.isIOS;

  @override
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo:
          emailRedirectTo ?? 'https://reflexjourney.app/auth/confirm',
    );
    // With email confirmation enabled, sign-up returns no session until the
    // user clicks the confirmation link. A null session means "confirm pending".
    return response.session == null;
  }

  @override
  Future<void> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Apple ID token missing',
          statusCode: 'id_token_missing',
        );
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Sign in canceled',
            statusCode: 'auth_canceled');
      }
      rethrow;
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    if (!_googleInitialized) {
      final googleIds = resolveGoogleClientIds(
        isIOS: _isIOS,
        googleIosClientId: _googleIosClientId,
        googleWebClientId: _googleWebClientId,
      );
      if (googleIds.missingConfig) {
        throw const AuthException(
          'Google sign-in is not configured for iOS',
          statusCode: 'google_config_missing',
        );
      }
      await _googleSignIn.initialize(
        clientId: googleIds.clientId,
        serverClientId: googleIds.serverClientId,
      );
      _googleInitialized = true;
    }
    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google ID token missing',
          statusCode: 'id_token_missing',
        );
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthException('Sign in canceled',
            statusCode: 'auth_canceled');
      }
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordReset(
      {required String email, String? redirectTo}) async {
    await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}

class GoogleClientIds {
  const GoogleClientIds({
    required this.clientId,
    required this.serverClientId,
    required this.missingConfig,
  });

  final String? clientId;
  final String? serverClientId;
  final bool missingConfig;
}

GoogleClientIds resolveGoogleClientIds({
  required bool isIOS,
  required String googleIosClientId,
  required String googleWebClientId,
}) {
  final iosClientId = googleIosClientId.trim();
  final webClientId = googleWebClientId.trim();
  if (isIOS) {
    if (iosClientId.isEmpty) {
      return const GoogleClientIds(
        clientId: null,
        serverClientId: null,
        missingConfig: true,
      );
    }
    return GoogleClientIds(
      clientId: iosClientId,
      serverClientId: webClientId.isEmpty ? null : webClientId,
      missingConfig: false,
    );
  }
  return GoogleClientIds(
    clientId: null,
    serverClientId: webClientId.isEmpty ? null : webClientId,
    missingConfig: false,
  );
}
