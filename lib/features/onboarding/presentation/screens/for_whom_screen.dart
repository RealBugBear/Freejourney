import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';

class ForWhomScreen extends ConsumerStatefulWidget {
  const ForWhomScreen({super.key});

  @override
  ConsumerState<ForWhomScreen> createState() => _ForWhomScreenState();
}

class _ForWhomScreenState extends ConsumerState<ForWhomScreen> {
  bool _showChildForm = false;
  final _nameController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onProfileCreated(String profileName) async {
    if (!mounted) return;
    final goToReflex = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(ctx)
                  .forWhomReflexProfileSheetTitle(profileName),
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(ctx).forWhomReflexProfileSheetBody,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppLocalizations.of(ctx).forWhomStartReflexProfile),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(AppLocalizations.of(ctx).forWhomLaterToTraining),
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (goToReflex == true) {
      context.go(Routes.reflexProfile, extra: 'moro');
    } else {
      context.go(Routes.dashboard);
    }
  }

  Future<void> _createSelfProfile() async {
    setState(() => _saving = true);
    try {
      final profile = await createAdultSelfProfile(ref);
      await _onProfileCreated(profile.displayName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).forWhomCreateError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createChildProfile() async {
    final name = _nameController.text.trim();
    final birthDate = _selectedBirthDate;
    if (name.isEmpty || birthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context).forWhomMissingFields)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await createChildReflexSubjectProfile(
        ref,
        displayName: name,
        birthDate: birthDate,
      );
      await _onProfileCreated(name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).forWhomCreateError('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.dashboard),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.forWhomTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.forWhomSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),
              _OptionCard(
                icon: Icons.person_outline,
                title: l10n.forWhomSelfTitle,
                subtitle: l10n.forWhomSelfSubtitle,
                expanded: false,
                enabled: !_saving,
                onTap: _createSelfProfile,
                trailing: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const SizedBox(height: 12),
              _OptionCard(
                icon: Icons.child_care_outlined,
                title: l10n.forWhomChildTitle,
                subtitle: l10n.forWhomChildSubtitle,
                expanded: _showChildForm,
                enabled: !_saving,
                onTap: () => setState(() => _showChildForm = !_showChildForm),
                trailing: Icon(
                  _showChildForm
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (_showChildForm) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: l10n.forWhomChildNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedBirthDate ??
                          DateTime(now.year - 6, now.month, now.day),
                      firstDate: DateTime(now.year - 100),
                      lastDate: now,
                      helpText: l10n.forWhomBirthDatePickerHelp,
                    );
                    if (picked != null) {
                      setState(() => _selectedBirthDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.forWhomBirthDateLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: const Icon(Icons.calendar_month_outlined),
                      helperText: _selectedBirthDate == null
                          ? l10n.forWhomBirthDateHelper
                          : null,
                    ),
                    child: Text(
                      _selectedBirthDate == null
                          ? l10n.forWhomSelectDate
                          : DateFormat.yMd(
                                  Localizations.localeOf(context).toString())
                              .format(_selectedBirthDate!),
                      style: _selectedBirthDate == null
                          ? TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _createChildProfile,
                    child: Text(
                        _saving ? l10n.saving : l10n.forWhomCreateChildProfile),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.expanded,
    required this.enabled,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool expanded;
  final bool enabled;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: expanded ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: expanded
              ? AppColors.primary
              : Theme.of(context).colorScheme.outlineVariant,
          width: expanded ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: expanded
                    ? AppColors.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: expanded ? AppColors.primary : null,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
