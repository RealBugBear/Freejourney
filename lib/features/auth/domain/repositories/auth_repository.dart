import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  Future<void> signInWithEmail(
      {required String email, required String password});
  /// Registers a new account. Returns true when email confirmation is still
  /// pending — i.e. sign-up succeeded but no active session was created yet, so
  /// the user must click the confirmation link before they can sign in.
  Future<bool> signUpWithEmail(
      {required String email, required String password});
  Future<void> sendPasswordReset({required String email, String? redirectTo});
  Future<void> updatePassword({required String newPassword});
  Future<void> signOut();
}
