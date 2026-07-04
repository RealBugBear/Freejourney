import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  return Supabase.instance.client.auth.currentUser;
});

/// True while the app is processing a password-recovery deep link.
/// Set to true in app.dart before calling getSessionFromUrl().
/// Set back to false in ResetPasswordScreen after successful update.
final passwordRecoveryActiveProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repo;
  final Ref _ref;

  AuthNotifier(this._repo, this._ref) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.signInWithEmail(email: email, password: password),
    );
  }

  /// Returns true when email confirmation is still pending (no session yet).
  /// Check `state.hasError` first — on failure the return value is meaningless.
  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    var needsEmailConfirmation = false;
    state = await AsyncValue.guard(() async {
      needsEmailConfirmation =
          await _repo.signUpWithEmail(email: email, password: password);
    });
    return needsEmailConfirmation;
  }

  Future<void> sendPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo
          .sendPasswordReset(email: email, redirectTo: redirectTo)
          .timeout(const Duration(seconds: 15)),
    );
  }

  Future<void> updatePassword({required String newPassword}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.updatePassword(newPassword: newPassword),
    );
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    // Clear local DB before signing out to prevent data leaking to next session.
    await _ref.read(databaseProvider).clearUserData();
    // userRoleProvider watches authStateProvider and will re-run automatically
    // after sign-out — no manual invalidate needed.
    state = await AsyncValue.guard(() => _repo.signOut());
  }

  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
