import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../consent/presentation/providers/consent_provider.dart';
import '../providers/auth_provider.dart';

// RFC 5322-lite email pattern — catches obvious typos without being overly strict.
final _emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _passwordConfirmFocusNode = FocusNode();

  bool _isSignUp = false;
  bool _showPasswordReset = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  // Only show inline errors after the first submit attempt.
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (!_emailRegex.hasMatch(v)) return l10n.validationInvalidEmail;
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = value ?? '';
    if (v.isEmpty) return l10n.validationRequired;
    if (_isSignUp && v.length < 8) return l10n.validationPasswordTooShort;
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    final l10n = AppLocalizations.of(context);
    final v = (value ?? '').trim();
    if (v.isEmpty) return l10n.validationRequired;
    if (v != _passwordController.text.trim()) {
      return l10n.validationPasswordMismatch;
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final notifier = ref.read(authNotifierProvider.notifier);

    if (_isSignUp) {
      await notifier.signUp(email: email, password: password);
    } else {
      await notifier.signIn(email: email, password: password);
    }

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (!authState.hasError) {
        // Invalidate consent cache so the new user's consent state is checked fresh.
        ref.invalidate(hasConsentedProvider);
        context.go(Routes.dashboard);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = _emailController.text.trim();
    await ref.read(authNotifierProvider.notifier).sendPasswordReset(
          email: email,
          redirectTo: 'https://reflexjourney.app/auth/reset-password',
        );

    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) return;

    setState(() => _showPasswordReset = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).passwordResetSent)),
    );
  }

  void _clearErrorAndRebuild() {
    ref.read(authNotifierProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    final currentLang = ref.watch(settingsProvider).languageCode;

    return Scaffold(
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
                const SizedBox(height: 32),
                Text(
                  l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Email field
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: _showPasswordReset
                      ? TextInputAction.done
                      : TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    border: const OutlineInputBorder(),
                  ),
                  validator: _validateEmail,
                  onChanged: (_) => _clearErrorAndRebuild(),
                  onFieldSubmitted: (_) {
                    if (_showPasswordReset) {
                      _sendPasswordReset();
                    } else {
                      _passwordFocusNode.requestFocus();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Password field (hidden in password reset mode)
                if (!_showPasswordReset) ...[
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction:
                        _isSignUp ? TextInputAction.next : TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: _validatePassword,
                    onChanged: (_) => _clearErrorAndRebuild(),
                    onFieldSubmitted: (_) {
                      if (_isSignUp) {
                        _passwordConfirmFocusNode.requestFocus();
                      } else {
                        _submit();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password confirm — only during sign-up
                  if (_isSignUp) ...[
                    TextFormField(
                      controller: _passwordConfirmController,
                      focusNode: _passwordConfirmFocusNode,
                      obscureText: _obscurePasswordConfirm,
                      textInputAction: TextInputAction.done,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: l10n.passwordConfirm,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePasswordConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(() =>
                              _obscurePasswordConfirm =
                                  !_obscurePasswordConfirm),
                        ),
                      ),
                      validator: _validatePasswordConfirm,
                      onChanged: (_) => _clearErrorAndRebuild(),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],

                // Server-side auth error (shown below fields, above button)
                if (authState.hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    _localizeAuthError(authState.error.toString(), l10n),
                    style:
                        const TextStyle(color: AppColors.error, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                ],

                const SizedBox(height: 24),

                // Primary button
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (_showPasswordReset ? _sendPasswordReset : _submit),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_showPasswordReset
                          ? l10n.resetPassword
                          : (_isSignUp ? l10n.signUp : l10n.signIn)),
                ),
                const SizedBox(height: 16),

                // Toggle sign in / sign up
                if (!_showPasswordReset)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isSignUp = !_isSignUp;
                        _submitted = false;
                        _obscurePassword = true;
                        _obscurePasswordConfirm = true;
                      });
                      _passwordConfirmController.clear();
                      _formKey.currentState?.reset();
                      ref.read(authNotifierProvider.notifier).clearError();
                    },
                    child: Text(_isSignUp ? l10n.signIn : l10n.signUp),
                  ),

                if (!_showPasswordReset)
                  OutlinedButton.icon(
                    onPressed: () => context.go(Routes.reflexProfileDemo),
                    icon: const Icon(Icons.radar_outlined),
                    label: const Text('Kurztest ohne Konto'),
                  ),

                // Forgot password toggle
                if (!_isSignUp)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPasswordReset = !_showPasswordReset;
                        _submitted = false;
                      });
                      _formKey.currentState?.reset();
                      ref.read(authNotifierProvider.notifier).clearError();
                    },
                    child: Text(
                      _showPasswordReset ? l10n.cancel : l10n.forgotPassword,
                    ),
                  ),

                // Language toggle — always visible so non-German speakers can switch
                const SizedBox(height: 32),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'de', label: Text('🇩🇪 Deutsch')),
                    ButtonSegment(value: 'en', label: Text('🇬🇧 English')),
                  ],
                  selected: {currentLang},
                  onSelectionChanged: (s) =>
                      ref.read(settingsProvider.notifier).setLanguage(s.first),
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.white,
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _localizeAuthError(String error, AppLocalizations l10n) {
    final normalized = error.toLowerCase();
    if (error.contains('TimeoutException') || error.contains('timed out')) {
      return l10n.errorGeneric;
    }
    if (normalized.contains('invalid_credentials') ||
        normalized.contains('invalid login') ||
        normalized.contains('invalid login credentials') ||
        normalized.contains('email or password') ||
        normalized.contains('invalid email or password')) {
      return l10n.authErrorInvalidCredentials;
    }
    if (normalized.contains('already registered') ||
        normalized.contains('already been registered')) {
      return l10n.authErrorEmailInUse;
    }
    if (_isSignUp &&
        (normalized.contains('weak') ||
            normalized.contains('password') ||
            normalized.contains('at least'))) {
      return l10n.authErrorWeakPassword;
    }
    return l10n.errorGeneric;
  }
}
