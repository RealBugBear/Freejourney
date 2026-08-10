# Auth Enterprise-Level Komplettlösung — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Alle vier Auth-Defizite beheben: Passwort-Reset via Universal Links vollständig in-App, In-App-Passwort-Änderung mit Re-Auth, delete_user RPC deployment, Passwort-Bestätigung Validierungs-Bugfix.

**Architecture:** Universal Links (corejourney.care) leiten Password-Reset-Mails direkt in die App — `app_links` fängt den Deep Link ab, setzt einen Riverpod-Provider auf `true`, übergibt die URL an das Supabase SDK, das dann einen `passwordRecovery`-Event emittiert und GoRouter zur neuen `ResetPasswordScreen` navigiert. Für die In-App-Passwort-Änderung wird eine separate `ChangePasswordScreen` via Push aus ProfileScreen erreichbar, mit Re-Auth via `signInWithPassword`. Beide Screens verwenden `authNotifier.updatePassword()` — eine neue Methode, die via Interface + Repository + Notifier durchgezogen wird.

**Tech Stack:** Flutter, Riverpod (StateNotifier, StateProvider, StreamProvider), GoRouter, Supabase Flutter SDK (`auth.updateUser`, `auth.getSessionFromUrl`), `app_links: ^6.x`

---

## File Map

| Datei | Aktion | Inhalt |
|---|---|---|
| `pubspec.yaml` | Modify | `app_links: ^6.x` hinzufügen |
| `lib/l10n/app_de.arb` | Modify | Neue l10n-Strings (DE) |
| `lib/l10n/app_en.arb` | Modify | Neue l10n-Strings (EN) |
| `lib/features/auth/domain/repositories/auth_repository.dart` | Modify | `updatePassword` Abstract-Methode |
| `lib/features/auth/data/repositories/supabase_auth_repository.dart` | Modify | `updatePassword` Implementierung |
| `lib/features/auth/presentation/providers/auth_provider.dart` | Modify | `passwordRecoveryActiveProvider` + `updatePassword` in Notifier |
| `lib/features/auth/presentation/screens/login_screen.dart` | Modify | Validierungsbugfix + `redirectTo` |
| `lib/core/navigation/app_router.dart` | Modify | Neue Route-Konstanten + 2 neue GoRoutes + Redirect-Logik |
| `lib/app.dart` | Modify | `app_links` Deep-Link-Handler (cold + warm start) |
| `lib/features/profile/presentation/screens/profile_screen.dart` | Modify | "Passwort ändern" → navigate zu `changePassword` |
| `android/app/src/main/AndroidManifest.xml` | Modify | `<intent-filter>` für Universal Links |
| `ios/Runner/Runner.entitlements` | **Create** | Associated-Domains Entitlement |
| `lib/features/auth/presentation/screens/reset_password_screen.dart` | **Create** | Neuer Screen: Passwort nach Deep Link setzen |
| `lib/features/auth/presentation/screens/change_password_screen.dart` | **Create** | Neuer Screen: Passwort ändern (eingeloggt, Re-Auth) |

---

## Task 1: Bugfix — Passwort-Bestätigung Validierung + redirectTo

**Files:**
- Modify: `lib/features/auth/presentation/screens/login_screen.dart:66-76` (Validierung), `:218-238` (Confirm-Feld), `:106-117` (`_sendPasswordReset`)

### Warum

iOS AutoCorrect kann unsichtbare Zeichen in Passwort-Felder einfügen. Der Vergleich trimmt nicht → falsch-positive "Passwörter stimmen nicht überein". Außerdem fehlt `redirectTo` beim Password-Reset-Call, weshalb der Link im Browser endet.

- [ ] **Step 1: Confirm-Feld — autocorrect + enableSuggestions deaktivieren**

In `login_screen.dart`, das `TextFormField` für `_passwordConfirmController` (momentan ca. Zeile 214) bekommt zwei neue Properties:

```dart
TextFormField(
  controller: _passwordConfirmController,
  focusNode: _passwordConfirmFocusNode,
  obscureText: _obscurePasswordConfirm,
  autocorrect: false,          // NEU
  enableSuggestions: false,    // NEU
  textInputAction: TextInputAction.done,
  decoration: InputDecoration(
    labelText: l10n.localeName == 'de'
        ? 'Passwort bestätigen'
        : 'Confirm password',
    border: const OutlineInputBorder(),
    suffixIcon: IconButton(
      icon: Icon(
        _obscurePasswordConfirm
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(
          () => _obscurePasswordConfirm = !_obscurePasswordConfirm),
    ),
  ),
  validator: _validatePasswordConfirm,
  onChanged: (_) => _clearErrorAndRebuild(),
  onFieldSubmitted: (_) => _submit(),
),
```

- [ ] **Step 2: `_validatePasswordConfirm` — trim vor Vergleich**

```dart
String? _validatePasswordConfirm(String? value) {
  final l10n = AppLocalizations.of(context);
  final isDE = l10n.localeName == 'de';
  final v = (value ?? '').trim();           // NEU: trim
  if (v.isEmpty) return l10n.validationRequired;
  if (v != _passwordController.text.trim()) { // NEU: trim auf beiden Seiten
    return isDE
        ? 'Passwörter stimmen nicht überein.'
        : 'Passwords do not match.';
  }
  return null;
}
```

- [ ] **Step 3: `_sendPasswordReset` — redirectTo hinzufügen**

```dart
Future<void> _sendPasswordReset() async {
  setState(() => _submitted = true);
  if (!(_formKey.currentState?.validate() ?? false)) return;

  final email = _emailController.text.trim();
  await ref
      .read(authNotifierProvider.notifier)
      .sendPasswordReset(
        email: email,
        redirectTo: 'https://corejourney.care/auth/reset-password', // NEU
      );

  if (mounted) {
    setState(() => _showPasswordReset = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).passwordResetSent)),
    );
  }
}
```

- [ ] **Step 4: Starte App auf einem Simulator und überprüfe manuell:**
  - Registrierung: Passwort und Bestätigung mit Copy-Paste → kein falscher Mismatch
  - Passwort vergessen → E-Mail eingeben → Button antippen (Snackbar erscheint)

- [ ] **Step 5: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add lib/features/auth/presentation/screens/login_screen.dart
git commit -m "fix: autocorrect off + trim in password confirm, add redirectTo to password reset"
```

---

## Task 2: l10n — Neue Strings

**Files:**
- Modify: `lib/l10n/app_de.arb`
- Modify: `lib/l10n/app_en.arb`

Die neuen Screens brauchen folgende Strings. Alle bestehenden Strings bleiben unangetastet.

- [ ] **Step 1: Strings in `app_de.arb` einfügen** (nach `profileChangePasswordSent` ca. Zeile 231):

```json
  "newPassword": "Neues Passwort",
  "passwordConfirm": "Passwort bestätigen",
  "currentPassword": "Aktuelles Passwort",
  "passwordChanged": "Passwort erfolgreich geändert.",
  "passwordSet": "Neues Passwort gesetzt. Bitte einloggen.",
  "authErrorSamePassword": "Das neue Passwort muss sich vom bisherigen unterscheiden.",
  "authErrorInvalidCurrentPassword": "Das aktuelle Passwort ist falsch.",
```

- [ ] **Step 2: Strings in `app_en.arb` einfügen** (nach `profileChangePasswordSent`):

```json
  "newPassword": "New password",
  "passwordConfirm": "Confirm password",
  "currentPassword": "Current password",
  "passwordChanged": "Password changed successfully.",
  "passwordSet": "Password set. Please log in.",
  "authErrorSamePassword": "New password must differ from the current one.",
  "authErrorInvalidCurrentPassword": "Current password is incorrect.",
```

- [ ] **Step 3: l10n generieren**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter gen-l10n
```

Expected: keine Fehler, `lib/l10n/app_localizations_de.dart` und `app_localizations_en.dart` enthalten die neuen Getter.

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_de.arb lib/l10n/app_en.arb
git commit -m "feat: add l10n strings for reset/change password screens"
```

---

## Task 3: Repo-Layer — `updatePassword`

**Files:**
- Modify: `lib/features/auth/domain/repositories/auth_repository.dart`
- Modify: `lib/features/auth/data/repositories/supabase_auth_repository.dart`

- [ ] **Step 1: Abstract-Methode ins Interface**

In `auth_repository.dart` nach `sendPasswordReset`:

```dart
abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
  Future<void> signInWithEmail(
      {required String email, required String password});
  Future<void> signUpWithEmail(
      {required String email, required String password});
  Future<void> sendPasswordReset({required String email, String? redirectTo}); // redirectTo NEU
  Future<void> updatePassword({required String newPassword});                   // NEU
  Future<void> signOut();
}
```

Achtung: `sendPasswordReset` bekommt den optionalen `redirectTo`-Parameter ebenfalls — der Call in `login_screen.dart` (Task 1) braucht das.

- [ ] **Step 2: Implementierung in `supabase_auth_repository.dart`**

```dart
@override
Future<void> sendPasswordReset({required String email, String? redirectTo}) async {
  await _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
}

@override
Future<void> updatePassword({required String newPassword}) async {
  await _client.auth.updateUser(UserAttributes(password: newPassword));
}
```

- [ ] **Step 3: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/auth/
```

Expected: keine Fehler.

- [ ] **Step 4: Commit**

```bash
git add lib/features/auth/domain/repositories/auth_repository.dart \
        lib/features/auth/data/repositories/supabase_auth_repository.dart
git commit -m "feat: add updatePassword to auth repository interface and implementation"
```

---

## Task 4: Auth Provider — `updatePassword` + `passwordRecoveryActiveProvider`

**Files:**
- Modify: `lib/features/auth/presentation/providers/auth_provider.dart`

- [ ] **Step 1: `passwordRecoveryActiveProvider` ergänzen**

Direkt nach den bestehenden Provider-Deklarationen (nach Zeile 18, vor `class AuthNotifier`):

```dart
/// True while the app is processing a password-recovery deep link.
/// Set to true in app.dart before calling getSessionFromUrl().
/// Set back to false in ResetPasswordScreen after successful update.
final passwordRecoveryActiveProvider = StateProvider<bool>((ref) => false);
```

- [ ] **Step 2: `sendPasswordReset` im Notifier — `redirectTo` Parameter ergänzen**

```dart
Future<void> sendPasswordReset({
  required String email,
  String? redirectTo,
}) async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(
    () => _repo.sendPasswordReset(email: email, redirectTo: redirectTo),
  );
}
```

- [ ] **Step 3: `updatePassword` zum Notifier hinzufügen**

Nach `sendPasswordReset` im `AuthNotifier`:

```dart
Future<void> updatePassword({required String newPassword}) async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(
    () => _repo.updatePassword(newPassword: newPassword),
  );
}
```

- [ ] **Step 4: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/auth/
```

Expected: keine Fehler.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/providers/auth_provider.dart
git commit -m "feat: add updatePassword to AuthNotifier and passwordRecoveryActiveProvider"
```

---

## Task 5: pubspec.yaml — `app_links` Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Package hinzufügen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter pub add app_links
```

Expected output enthält: `+ app_links 6.x.x` (oder neueste Stable-Version).

- [ ] **Step 2: Kompilierung prüfen**

```bash
flutter pub get
flutter analyze lib/
```

Expected: keine Fehler.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add app_links package for Universal Link handling"
```

---

## Task 6: Router — Neue Routen + Redirect-Logik

**Files:**
- Modify: `lib/core/navigation/app_router.dart`

Imports die hinzugefügt werden müssen:
```dart
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
```

- [ ] **Step 1: Route-Konstanten hinzufügen**

In der `Routes`-Klasse nach `login`:

```dart
class Routes {
  static const login = '/login';
  static const resetPassword = '/auth/reset-password';    // NEU
  static const changePassword = '/profile/change-password'; // NEU
  // ... rest bleibt gleich
```

- [ ] **Step 2: `routerProvider` — Redirect-Logik erweitern**

Den bestehenden `redirect`-Block ersetzen. Er bekommt Zugriff auf den `passwordRecoveryActiveProvider` via `ref`:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = _StreamRefreshListenable(
    Supabase.instance.client.auth.onAuthStateChange,
  );
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.login,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final user = Supabase.instance.client.auth.currentUser;
      final isPasswordRecovery = ref.read(passwordRecoveryActiveProvider);
      final loc = state.matchedLocation;

      // Password-Recovery Deep Link: Vorrang vor allem anderen
      if (isPasswordRecovery && loc != Routes.resetPassword) {
        return Routes.resetPassword;
      }
      // Nicht eingeloggt → Login (außer Reset-Password während Recovery)
      if (user == null && loc != Routes.login && loc != Routes.resetPassword) {
        return Routes.login;
      }
      // Eingeloggt und auf Login → Dashboard
      if (user != null && !isPasswordRecovery && loc == Routes.login) {
        return Routes.dashboard;
      }
      return null;
    },
    routes: [
      // ... bestehende Routen bleiben unverändert ...
```

- [ ] **Step 3: Neue GoRoutes einfügen**

Direkt nach dem `login`-GoRoute (nach Zeile 94 im Original), vor `consent`:

```dart
GoRoute(
  path: Routes.resetPassword,
  name: 'reset-password',
  builder: (context, state) => const ResetPasswordScreen(),
),
GoRoute(
  path: Routes.changePassword,
  name: 'change-password',
  builder: (context, state) => const ChangePasswordScreen(),
),
```

- [ ] **Step 4: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/core/navigation/
```

Expected: keine Fehler (ResetPasswordScreen und ChangePasswordScreen werden in Task 8/9 erstellt — Analyze kann erst nach diesen Tasks vollständig grün sein).

- [ ] **Step 5: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat: add resetPassword and changePassword routes with recovery redirect logic"
```

---

## Task 7: `app.dart` — Deep Link Handler

**Files:**
- Modify: `lib/app.dart`

Import hinzufügen:
```dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
```

(`dart:async` ist bereits vorhanden.)

- [ ] **Step 1: `_deepLinkSub` Feld und `_initDeepLinks` Methode hinzufügen**

In `_CoreJourneyAppState`, nach dem bestehenden `dispose`-Block und vor `didChangeAppLifecycleState`:

```dart
StreamSubscription<Uri>? _deepLinkSub;

Future<void> _initDeepLinks() async {
  final appLinks = AppLinks();

  // Cold start: App war geschlossen, Link öffnet sie neu
  final initialUri = await appLinks.getInitialLink();
  if (initialUri != null) {
    await _handleDeepLink(initialUri);
  }

  // Warm start: App läuft im Hintergrund
  _deepLinkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
}

Future<void> _handleDeepLink(Uri uri) async {
  if (uri.path.startsWith('/auth/')) {
    // Vor dem SDK-Call setzen, damit der Router beim nächsten Refresh
    // sofort zur ResetPasswordScreen navigiert.
    ref.read(passwordRecoveryActiveProvider.notifier).state = true;
    await Supabase.instance.client.auth.getSessionFromUrl(uri);
  }
}
```

- [ ] **Step 2: `_initDeepLinks` in `initState` aufrufen**

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initDeepLinks(); // NEU
}
```

- [ ] **Step 3: `_deepLinkSub` in `dispose` canceln**

```dart
@override
void dispose() {
  _deepLinkSub?.cancel(); // NEU
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}
```

- [ ] **Step 4: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/app.dart
```

Expected: keine Fehler.

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart
git commit -m "feat: register app_links deep link handler for Universal Link password recovery"
```

---

## Task 8: `ResetPasswordScreen` — Neuer Screen

**Files:**
- Create: `lib/features/auth/presentation/screens/reset_password_screen.dart`

Dieser Screen ist nur via Deep Link erreichbar (kein Back-Button). Er setzt das Passwort des angemeldeten (Recovery-)Users und navigiert danach zu Login.

- [ ] **Step 1: Datei erstellen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitted = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length < 8) return l10n.validationPasswordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return l10n.validationRequired;
    if (v != _passwordController.text.trim()) {
      return l10n.localeName == 'de'
          ? 'Passwörter stimmen nicht überein.'
          : 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newPassword = _passwordController.text;
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.updatePassword(newPassword: newPassword);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) return; // Fehler wird durch authState im Build angezeigt

    // Erfolg: Recovery-Flag zurücksetzen, zur Login navigieren
    ref.read(passwordRecoveryActiveProvider.notifier).state = false;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).passwordSet)),
      );
      context.go(Routes.login);
    }
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    if (error.contains('same_password')) return l10n.authErrorSamePassword;
    if (error.contains('weak') || error.contains('password')) {
      return l10n.authErrorWeakPassword;
    }
    return l10n.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      // Kein AppBar-Back-Button — Nutzer war vor dem Deep Link nicht eingeloggt
      appBar: AppBar(
        title: Text(l10n.resetPassword),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Neues Passwort
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                  onChanged: (_) =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                ),
                const SizedBox(height: 16),

                // Passwort bestätigen
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.passwordConfirm,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: _validateConfirm,
                  onChanged: (_) =>
                      ref.read(authNotifierProvider.notifier).clearError(),
                  onFieldSubmitted: (_) => _submit(),
                ),

                // Server-Fehler
                if (authState.hasError) ...[
                  const SizedBox(height: 12),
                  Text(
                    _localizeAuthError(authState.error.toString(), l10n),
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.resetPassword),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/auth/presentation/screens/reset_password_screen.dart
```

Expected: keine Fehler.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/reset_password_screen.dart
git commit -m "feat: add ResetPasswordScreen for Universal Link password recovery flow"
```

---

## Task 9: `ChangePasswordScreen` — Neuer Screen

**Files:**
- Create: `lib/features/auth/presentation/screens/change_password_screen.dart`

Erreichbar via Push aus ProfileScreen. Drei Felder: Aktuelles Passwort (Re-Auth), Neues Passwort, Bestätigung.

- [ ] **Step 1: Datei erstellen**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitted = false;
  String? _serverError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    final l10n = AppLocalizations.of(context);
    if ((value ?? '').isEmpty) return l10n.validationRequired;
    return null;
  }

  String? _validateNew(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (v.length < 8) return l10n.validationPasswordTooShort;
    return null;
  }

  String? _validateConfirm(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return l10n.validationRequired;
    if (v != _newPasswordController.text.trim()) {
      return l10n.localeName == 'de'
          ? 'Passwörter stimmen nicht überein.'
          : 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _serverError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = AppLocalizations.of(context);
    final email =
        Supabase.instance.client.auth.currentUser?.email ?? '';
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;

    // Re-Auth: aktuelles Passwort verifizieren
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _serverError = l10n.authErrorInvalidCurrentPassword);
      }
      return;
    }

    // Passwort aktualisieren
    final notifier = ref.read(authNotifierProvider.notifier);
    await notifier.updatePassword(newPassword: newPassword);

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      setState(() =>
          _serverError = _localizeAuthError(authState.error.toString(), l10n));
      return;
    }

    // Erfolg
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordChanged)),
      );
    }
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    if (error.contains('same_password')) return l10n.authErrorSamePassword;
    if (error.contains('invalid_credentials') ||
        error.contains('Invalid login')) {
      return l10n.authErrorInvalidCurrentPassword;
    }
    if (error.contains('weak') || error.contains('password')) {
      return l10n.authErrorWeakPassword;
    }
    return l10n.errorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileChangePassword)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            autovalidateMode: _submitted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Aktuelles Passwort
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.currentPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: _validateCurrent,
                  onChanged: (_) => setState(() => _serverError = null),
                ),
                const SizedBox(height: 16),

                // Neues Passwort
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: _validateNew,
                  onChanged: (_) => setState(() => _serverError = null),
                ),
                const SizedBox(height: 16),

                // Bestätigung
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l10n.passwordConfirm,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: _validateConfirm,
                  onChanged: (_) => setState(() => _serverError = null),
                  onFieldSubmitted: (_) => _submit(),
                ),

                // Server-Fehler
                if (_serverError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _serverError!,
                    style: TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                ],

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l10n.confirm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/auth/presentation/screens/change_password_screen.dart
```

Expected: keine Fehler.

- [ ] **Step 3: Commit**

```bash
git add lib/features/auth/presentation/screens/change_password_screen.dart
git commit -m "feat: add ChangePasswordScreen with re-auth before password update"
```

---

## Task 10: `ProfileScreen` — Navigation zu `ChangePasswordScreen`

**Files:**
- Modify: `lib/features/profile/presentation/screens/profile_screen.dart`

Aktuell ruft der "Passwort ändern"-Tile `_sendPasswordReset()` auf (sendet Reset-Mail). Das wird auf In-App-Navigation umgestellt. Die `_sendPasswordReset`-Methode kann entfernt werden.

- [ ] **Step 1: Import hinzufügen** (am Anfang der Datei, nach den anderen Imports):

Der `Routes`-Import ist bereits vorhanden (`../../../../core/navigation/app_router.dart`). Kein neuer Import nötig.

- [ ] **Step 2: ListTile onTap ändern** (ca. Zeile 108):

Vorher:
```dart
ListTile(
  leading: const Icon(Icons.lock_outline),
  title: Text(l10n.profileChangePassword),
  onTap: () => _sendPasswordReset(context, l10n, user?.email),
),
```

Nachher:
```dart
ListTile(
  leading: const Icon(Icons.lock_outline),
  title: Text(l10n.profileChangePassword),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push(Routes.changePassword),
),
```

- [ ] **Step 3: `_sendPasswordReset`-Methode entfernen**

Die gesamte Methode (ca. Zeilen 148–168) löschen:
```dart
Future<void> _sendPasswordReset(
  BuildContext context,
  AppLocalizations l10n,
  String? email,
) async { ... }
```

- [ ] **Step 4: Kompilierung + App starten**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/profile/
```

Expected: keine Fehler.

Starte App mit `make run-sim` und überprüfe: Profil → "Passwort ändern" → öffnet neuen Screen mit drei Feldern.

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation/screens/profile_screen.dart
git commit -m "feat: change password navigates to ChangePasswordScreen instead of sending reset email"
```

---

## Task 11: iOS Entitlements — Universal Links

**Files:**
- Create: `ios/Runner/Runner.entitlements`

**Wichtig:** Die Entitlements-Datei muss anschließend auch in Xcode im Target "Runner" unter Signing & Capabilities eingetragen werden. Das ist ein manueller Schritt.

- [ ] **Step 1: Datei erstellen**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.associated-domains</key>
    <array>
        <string>applinks:corejourney.care</string>
    </array>
</dict>
</plist>
```

Speichere als: `ios/Runner/Runner.entitlements`

- [ ] **Step 2: Xcode — Entitlements-Datei verknüpfen (manuell)**

1. `ios/Runner.xcworkspace` in Xcode öffnen
2. Project Navigator → Runner → Target "Runner" auswählen
3. Tab "Signing & Capabilities" öffnen
4. "+ Capability" → "Associated Domains" hinzufügen
5. Eintrag `applinks:corejourney.care` hinzufügen

Xcode erstellt ggf. automatisch eine `Runner.entitlements` oder verweist auf die bestehende. Falls Xcode eine zweite erstellt, Inhalt zusammenführen und die doppelte löschen.

- [ ] **Step 3: Commit**

```bash
git add ios/Runner/Runner.entitlements
git commit -m "feat: add iOS Universal Links entitlement for corejourney.care"
```

---

## Task 12: Android Manifest — Universal Links

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: `<intent-filter>` zur MainActivity hinzufügen**

Im `<activity android:name=".MainActivity">`-Block, direkt nach dem bestehenden LAUNCHER `<intent-filter>` (nach dem schließenden `</intent-filter>`-Tag ca. Zeile 33), vor dem `<!-- Don't delete ... -->`-Kommentar:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data
        android:scheme="https"
        android:host="corejourney.care"
        android:pathPrefix="/auth/"/>
</intent-filter>
```

- [ ] **Step 2: Kompilierung prüfen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze
```

Expected: keine Fehler.

- [ ] **Step 3: Commit**

```bash
git add android/app/src/main/AndroidManifest.xml
git commit -m "feat: add Android intent-filter for Universal Links on corejourney.care"
```

---

## Task 13: Manuelle Deployment-Schritte (Checkliste)

Diese Schritte können nicht automatisiert werden. Sie müssen vor den entsprechenden Tests durchgeführt werden.

### 13a — delete_user RPC deployen (VOR erstem Account-Lösch-Test)

- [ ] **DEV:** Supabase Dashboard öffnen → `sxvpiggednbftfqeokyd.supabase.co` → SQL Editor → Inhalt von `supabase/migrations/delete_user.sql` einfügen → Run
- [ ] **PROD:** Gleicher Schritt im PROD-Supabase-Projekt → SQL Editor → Run
- [ ] Verifizieren: `select routine_name from information_schema.routines where routine_name = 'delete_user';` liefert einen Eintrag

### 13b — Supabase Auth URLs konfigurieren (VOR erstem Password-Reset-Test)

Für **DEV** und **PROD** jeweils:
- [ ] Dashboard → Authentication → URL Configuration
- [ ] **Site URL:** `https://corejourney.care`
- [ ] **Redirect URLs (Whitelist):** `https://corejourney.care/auth/reset-password` eintragen
- [ ] Speichern

### 13c — AASA + assetlinks.json hosten (VOR iOS/Android Deep Link Test)

- [ ] **Apple App Site Association** unter `https://corejourney.care/.well-known/apple-app-site-association` bereitstellen:

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "5X6VFP7F58.com.alexandermessinger.corejourney",
        "paths": ["/auth/*"]
      }
    ]
  }
}
```

Muss mit `Content-Type: application/json` ausgeliefert werden (kein `.json`-Suffix in der URL).

- [ ] **Android Asset Links** unter `https://corejourney.care/.well-known/assetlinks.json` bereitstellen:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.alexandermessinger.corejourney",
    "sha256_cert_fingerprints": ["<RELEASE_CERT_SHA256>"]
  }
}]
```

`<RELEASE_CERT_SHA256>` durch den tatsächlichen SHA256-Fingerprint des Release-Signing-Zertifikats ersetzen. Abrufbar via: `keytool -list -v -keystore <pfad_zum_keystore>`.

- [ ] Verifizieren: `curl -I https://corejourney.care/.well-known/apple-app-site-association` → `Content-Type: application/json`

---

## Manuelle Test-Checkliste (nach allen Tasks)

Nach Abschluss aller Code-Tasks und manuellen Deployment-Schritte:

- [ ] Passwort-Reset E-Mail kommt an, Link öffnet App (nicht Browser)
- [ ] `ResetPasswordScreen` erscheint nach Deep Link — kein Back-Button sichtbar
- [ ] Passwort-Update schlägt fehl bei < 8 Zeichen (Validierung inline)
- [ ] Passwort-Update schlägt fehl wenn Felder nicht übereinstimmen
- [ ] Passwort erfolgreich gesetzt → Weiterleitung zu LoginScreen + Snackbar
- [ ] Eingeloggt: "Passwort ändern" öffnet `ChangePasswordScreen` (nicht Reset-Mail)
- [ ] Falsches aktuelles Passwort → Fehlermeldung, kein Crash
- [ ] Passwort erfolgreich geändert → Pop + Snackbar
- [ ] Konto löschen → lokale Daten weg → LoginScreen → Snackbar
- [ ] Registrierung: Passwort-Bestätigung mit Copy-Paste verursacht keinen falschen Mismatch
- [ ] Registrierung: Auge-Icon (Passwort sichtbar) verursacht keinen Mismatch
