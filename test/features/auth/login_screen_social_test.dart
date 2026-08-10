import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/features/auth/domain/repositories/auth_repository.dart';
import 'package:corejourney/features/auth/presentation/providers/auth_provider.dart';
import 'package:corejourney/features/auth/presentation/screens/login_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _StubAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  User? get currentUser => null;

  @override
  Future<void> sendPasswordReset({required String email, String? redirectTo}) {
    return Future.value();
  }

  @override
  Future<void> signInWithApple() => Future.value();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return Future.value();
  }

  @override
  Future<void> signInWithGoogle() => Future.value();

  @override
  Future<void> signOut() => Future.value();

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    String? emailRedirectTo,
  }) async {
    return false;
  }

  @override
  Future<void> updatePassword({required String newPassword}) {
    return Future.value();
  }
}

Widget _buildApp() {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
      settingsProvider.overrideWith(
        (ref) => SettingsNotifier(_prefs, null),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginScreen(),
    ),
  );
}

late SharedPreferences _prefs;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    _prefs = await SharedPreferences.getInstance();
  });

  testWidgets('shows Apple and Google sign-in buttons on sign-in mode',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    expect(find.byType(SignInWithAppleButton), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('hides social buttons on sign-up mode', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    final signUp = find.text('Sign Up');
    await tester.ensureVisible(signUp);
    await tester.tap(signUp);
    await tester.pumpAndSettle();

    expect(find.byType(SignInWithAppleButton), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
  });
}
