import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/app_languages.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(settingsProvider).languageCode;
  }

  Future<void> _continue() async {
    await ref.read(settingsProvider.notifier).setLanguage(_selectedCode);
    if (!mounted) return;
    final user = Supabase.instance.client.auth.currentUser;
    context.go(user == null ? Routes.login : Routes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Preview the highlighted language immediately without persisting it until
    // Continue is tapped (persisting earlier would make the router leave this
    // first-launch screen before the user confirms their choice).
    final l10n = lookupAppLocalizations(Locale(_selectedCode));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Image.asset(
                  'assets/images/brand/free.png',
                  width: 92,
                  height: 92,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                l10n.languageSelectionTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                l10n.languageSelectionSubtitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              // One button per registry entry — adding a language here needs
              // no code change, only an AppLanguages entry.
              for (final language in AppLanguages.all) ...[
                _LanguageButton(
                  label: language.autonym,
                  selected: _selectedCode == language.code,
                  onPressed: () =>
                      setState(() => _selectedCode = language.code),
                ),
                if (language != AppLanguages.all.last)
                  const SizedBox(height: 12),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.languageContinue,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
      ),
      label: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        backgroundColor: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : colors.surfaceContainerHighest,
        foregroundColor: selected ? AppColors.primary : colors.onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
