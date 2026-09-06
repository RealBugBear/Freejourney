import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final appConfig = ref.watch(appConfigProvider);
  return SupabaseAuthRepository(
    Supabase.instance.client,
    googleWebClientId: appConfig.googleWebClientId,
    googleIosClientId: appConfig.googleIosClientId,
  );
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// True while the app is processing a password-recovery deep link.
/// Set to true in app.dart before calling getSessionFromUrl().
/// Set back to false in ResetPasswordScreen after successful update.
final passwordRecoveryActiveProvider = StateProvider<bool>((ref) => false);

enum SignOutResult { signedOut, pendingChanges, failed, inProgress }

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

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repo.signInWithApple();
      } on AuthException catch (e) {
        if (e.statusCode == 'auth_canceled') return;
        rethrow;
      }
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      try {
        await _repo.signInWithGoogle();
      } on AuthException catch (e) {
        if (e.statusCode == 'auth_canceled') return;
        rethrow;
      }
    });
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

  /// Ordinary logout must preserve unsent work. Only an explicit discard
  /// decision (or a completed server account deletion) may erase pending jobs.
  Future<SignOutResult> signOut({bool discardPendingChanges = false}) async {
    if (state.isLoading) return SignOutResult.inProgress;
    state = const AsyncValue.loading();
    try {
      final sync = _ref.read(syncServiceProvider);
      if (!discardPendingChanges) {
        try {
          await sync.drain().timeout(const Duration(seconds: 15));
        } catch (_) {
          // The atomic cleanup guard below remains authoritative on network
          // failure/timeout; it refuses erasure while any local intent remains.
        }
      }
      final cleared = await sync.clearUserDataForSignOut(
        discardPendingChanges: discardPendingChanges,
      );
      if (!cleared) {
        state = const AsyncValue.data(null);
        return SignOutResult.pendingChanges;
      }
      await _repo.signOut();
      state = const AsyncValue.data(null);
      return SignOutResult.signedOut;
    } catch (error, stack) {
      state = AsyncValue.error(error, stack);
      return SignOutResult.failed;
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncValue.data(null);
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider), ref);
});
