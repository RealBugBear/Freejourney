import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/chat/presentation/widgets/direct_messages_action.dart';
import '../../../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final trainerName = ref.watch(clientTrainerProvider).valueOrNull;
    final role = ref.watch(userRoleProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        actions: [
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: OnboardingHintGate(
        hint: AppOnboardingHint.profile,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (user != null) ...[
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    (user.email ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  user.email ?? '',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              const SizedBox(height: 32),
            ],
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _UsernameSection(),
            ),
            const _SectionHeader(title: 'Trainingsprofile'),
            const _SubjectProfilesSection(),
            const SizedBox(height: 8),
            const _SectionHeader(title: 'Tagebuch'),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: const Text('Journal'),
              subtitle: const Text(
                'Deine Einträge und Reflexionen',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.journal),
            ),
            const _SectionHeader(title: 'Trainer'),
            ListTile(
              leading: Icon(
                trainerName != null ? Icons.link : Icons.link_off,
                color: trainerName != null ? AppColors.success : null,
              ),
              title: const Text('Begleitung verwalten'),
              subtitle: Text(
                trainerName != null
                    ? 'Aktuell verbunden mit $trainerName'
                    : 'Trainer finden, Anfragen und Termine verwalten',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.accompaniment),
            ),
            if (role == 'admin' || role == 'trainer') ...[
              const _SectionHeader(title: 'Arbeitsbereich'),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: const Text('Admin Panel'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.adminPanel),
                ),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('Nachrichten'),
                  subtitle: const Text(
                    'Trainer-Bewerbungen und Review-Kanäle',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.dm),
                ),
              if (role == 'trainer')
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: const Text('Trainerbereich'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.trainerDashboard),
                ),
            ],
            if (role != 'admin' && role != 'trainer') ...[
              const _SectionHeader(title: 'Beruflicher Zugang'),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Trainer werden'),
                subtitle: const Text(
                  'Bewerbung einreichen und prüfen lassen',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTrainerApplication(context),
              ),
            ],
            const _SectionHeader(title: 'Account'),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.profileChangePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.changePassword),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.signOut),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                l10n.profileDeleteAccount,
                style: const TextStyle(color: AppColors.error),
              ),
              onTap: () => _confirmDeleteAccount(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTrainerApplication(BuildContext context) async {
    context.push(Routes.trainerApplicationStatus);
  }

  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileDeleteAccountTitle),
        content: Text(l10n.profileDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.profileDeleteAccountConfirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await Supabase.instance.client.rpc('delete_user');
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileDeleteAccountSuccess)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileDeleteAccountError)),
        );
      }
    }
  }
}

class _SubjectProfilesSection extends ConsumerWidget {
  const _SubjectProfilesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allReflexSubjectProfilesProvider);
    final selected = ref.watch(selectedSubjectProfileProvider);

    return profilesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text('Profile konnten nicht geladen werden: $error'),
      ),
      data: (profiles) {
        if (profiles.isEmpty) {
          return ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: const Text('Erstes Profil anlegen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.onboardingForWhom),
          );
        }

        return Column(
          children: [
            for (final profile in profiles)
              ListTile(
                leading: Icon(
                  profile.profileType == 'adult_self'
                      ? Icons.person_outline
                      : Icons.child_care_outlined,
                  color: selected?.id == profile.id ? AppColors.primary : null,
                ),
                title: Text(profile.displayName),
                subtitle: Text(
                  _subjectProfileSubtitle(profile),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Profil bearbeiten',
                      onPressed: () => _showSubjectProfileEditor(
                        context,
                        ref,
                        profile,
                      ),
                    ),
                    if (selected?.id == profile.id)
                      const Icon(Icons.check_circle, color: AppColors.primary)
                    else
                      TextButton(
                        onPressed: () => ref
                            .read(selectedSubjectProfileIdProvider.notifier)
                            .select(profile.id),
                        child: const Text('Aktivieren'),
                      ),
                  ],
                ),
              ),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Profil hinzufügen'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.onboardingForWhom),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSubjectProfileEditor(
    BuildContext context,
    WidgetRef ref,
    ReflexSubjectProfile profile,
  ) async {
    final updated = await showDialog<_SubjectProfileEditResult>(
      context: context,
      builder: (ctx) => _SubjectProfileEditDialog(profile: profile),
    );
    if (updated == null || !context.mounted) return;

    try {
      await updateReflexSubjectProfile(
        ref,
        subjectProfileId: profile.id,
        displayName: updated.displayName,
        birthDate: profile.profileType == 'child' ? updated.birthDate : null,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil gespeichert.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Profil konnte nicht gespeichert werden: $error')),
        );
      }
    }
  }

  static String _subjectProfileSubtitle(ReflexSubjectProfile profile) {
    if (profile.profileType == 'adult_self') return 'Erwachsenenprofil';
    final parts = <String>['Kinderprofil'];
    if (profile.ageYears != null) parts.add('${profile.ageYears} Jahre');
    if (profile.ageGroup != null) parts.add(profile.ageGroup!);
    return parts.join(' · ');
  }
}

class _SubjectProfileEditResult {
  const _SubjectProfileEditResult({
    required this.displayName,
    this.birthDate,
  });

  final String displayName;
  final DateTime? birthDate;
}

class _SubjectProfileEditDialog extends StatefulWidget {
  const _SubjectProfileEditDialog({required this.profile});

  final ReflexSubjectProfile profile;

  @override
  State<_SubjectProfileEditDialog> createState() =>
      _SubjectProfileEditDialogState();
}

class _SubjectProfileEditDialogState extends State<_SubjectProfileEditDialog> {
  late final TextEditingController _nameController;
  DateTime? _birthDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _birthDate = widget.profile.birthDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 6, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: 'Geburtsdatum auswählen',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Bitte gib einen Namen an.');
      return;
    }
    if (widget.profile.profileType == 'child' && _birthDate == null) {
      setState(() => _error = 'Bitte gib ein Geburtsdatum an.');
      return;
    }
    Navigator.pop(
      context,
      _SubjectProfileEditResult(
        displayName: name,
        birthDate: _birthDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isChild = widget.profile.profileType == 'child';

    return AlertDialog(
      title: const Text('Profil bearbeiten'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText: isChild ? 'Name oder Spitzname' : 'Profilname',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          if (isChild) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickBirthDate,
              borderRadius: BorderRadius.circular(4),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Geburtsdatum',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Datum auswählen'
                      : '${_birthDate!.day.toString().padLeft(2, '0')}.'
                          '${_birthDate!.month.toString().padLeft(2, '0')}.'
                          '${_birthDate!.year}',
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _UsernameSection extends ConsumerStatefulWidget {
  const _UsernameSection();

  @override
  ConsumerState<_UsernameSection> createState() => _UsernameSectionState();
}

class _UsernameSectionState extends ConsumerState<_UsernameSection> {
  late TextEditingController _ctrl;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final displayName = profileAsync.valueOrNull?.displayName ?? '';

    if (!_editing && _ctrl.text != displayName) {
      _ctrl.text = displayName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anzeigename',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                enabled: _editing,
                onChanged: (_) => setState(() => _error = null),
                decoration: InputDecoration(
                  hintText: 'Anonym',
                  errorText: _error,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (!_editing)
              TextButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Bearbeiten'),
              )
            else
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Speichern'),
              ),
          ],
        ),
        Text(
          // Ohne Community-Feed (T04) beschreibt der Untertitel nur die
          // verbleibende Verwendung des Anzeigenamens: den Trainer-Chat.
          kCommunityEnabled
              ? 'Wird im Community-Feed angezeigt, wenn du Erfahrungen teilst.'
              : 'Sichtbar für deinen Trainer, zum Beispiel im Chat.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final trimmed = _ctrl.text.trim();
    if (trimmed.isNotEmpty && trimmed.length < 3) {
      setState(() => _error = 'Mindestens 3 Zeichen');
      return;
    }
    if (trimmed.contains('@')) {
      setState(() => _error = 'Kein @ erlaubt');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(
            displayName: trimmed.isEmpty ? null : trimmed,
          );
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      if (mounted) setState(() => _error = 'Speichern fehlgeschlagen');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
