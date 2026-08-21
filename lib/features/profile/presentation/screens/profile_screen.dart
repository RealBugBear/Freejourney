import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/chat/presentation/widgets/direct_messages_action.dart';
import '../../../../features/premium/data/premium_repository.dart';
import '../../../../features/premium/domain/entitlement.dart';
import '../../../../features/premium/presentation/providers/premium_provider.dart';
import '../../../../features/trainer/presentation/providers/trainer_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/profile_provider.dart';
import '../widgets/subject_profile_reflex_action_tile.dart';

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
            tooltip: l10n.settings,
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
            _SectionHeader(title: l10n.profileTrainingProfilesSection),
            const _SubjectProfilesSection(),
            const SizedBox(height: 8),
            _SectionHeader(title: l10n.journal),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.profileJournalItemTitle),
              subtitle: Text(
                l10n.profileJournalSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.journal),
            ),
            _SectionHeader(title: l10n.profileTrainerSection),
            ListTile(
              leading: Icon(
                trainerName != null ? Icons.link : Icons.link_off,
                color: trainerName != null ? AppColors.success : null,
              ),
              title: Text(l10n.profileManageGuidance),
              subtitle: Text(
                trainerName != null
                    ? l10n.profileConnectedWith(trainerName)
                    : l10n.profileFindManageTrainer,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.accompaniment),
            ),
            if (role == 'admin' || role == 'trainer') ...[
              _SectionHeader(title: l10n.profileWorkspaceSection),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_outlined),
                  title: Text(l10n.profileAdminPanel),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.adminPanel),
                ),
              if (role == 'admin')
                ListTile(
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: Text(l10n.profileMessages),
                  subtitle: Text(
                    l10n.profileReviewChannels,
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.dm),
                ),
              if (role == 'trainer')
                ListTile(
                  leading: const Icon(Icons.group_outlined),
                  title: Text(l10n.profileTrainerArea),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.trainerDashboard),
                ),
            ],
            if (role != 'admin' && role != 'trainer') ...[
              _SectionHeader(title: l10n.profileProfessionalAccessSection),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined),
                title: Text(l10n.profileBecomeTrainer),
                subtitle: Text(
                  l10n.profileApplicationSubtitle,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openTrainerApplication(context),
              ),
            ],
            _SectionHeader(title: l10n.profileAccountSection),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.profileChangePassword),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.changePassword),
            ),
            ListTile(
              leading: const Icon(Icons.redeem_outlined),
              title: Text(l10n.redeemAccessCodeTitle),
              subtitle: Text(
                l10n.redeemAccessCodeSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showRedeemAccessCodeDialog(context, ref),
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

  Future<void> _showRedeemAccessCodeDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    try {
      final submittedCode = await showDialog<String>(
        context: context,
        builder: (ctx) => RedeemAccessCodeDialog(
          controller: controller,
        ),
      );

      if (submittedCode == null ||
          submittedCode.trim().isEmpty ||
          !context.mounted) {
        return;
      }

      final result = await ref
          .read(premiumRepositoryProvider)
          .redeemAccessCode(submittedCode);
      ref.invalidate(entitlementProvider);
      ref.invalidate(effectiveEntitlementsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              redeemAccessCodeSuccessMessage(
                l10n,
                result,
                Localizations.localeOf(context),
              ),
            ),
          ),
        );
      }
    } on RedeemAccessCodeException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(redeemAccessCodeErrorMessage(l10n, e.error))),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.redeemAccessCodeErrorUnknown)),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

/// Existing profile redemption dialog, extracted only to make its bilingual
/// and large-text behavior directly testable. It does not add a route or a
/// paid surface.
class RedeemAccessCodeDialog extends StatelessWidget {
  const RedeemAccessCodeDialog({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.redeemAccessCodeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.redeemAccessCodeDialogBody),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.redeemAccessCodeHint,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: Text(l10n.redeemAccessCodeAction),
        ),
      ],
    );
  }
}

String redeemAccessCodeSuccessMessage(
  AppLocalizations l10n,
  RedeemAccessCodeResult result,
  Locale locale,
) {
  if (result.benefitKind == BenefitKind.storeOffer) {
    return l10n.redeemAccessCodeStoreOfferPending;
  }
  if (!result.grantsAccess || result.entitlementKey == null) {
    return l10n.redeemAccessCodeUnknownBenefit;
  }

  final benefit = switch (result.entitlementKey!) {
    EntitlementKey.premium => l10n.redeemAccessCodeBenefitPremium,
    EntitlementKey.studio => l10n.redeemAccessCodeBenefitStudio,
  };
  final expiresAt = result.expiresAt;
  if (expiresAt != null) {
    final formatted =
        DateFormat.yMMMd(locale.toLanguageTag()).format(expiresAt);
    return l10n.redeemAccessCodeInternalGrantUntil(benefit, formatted);
  }
  return l10n.redeemAccessCodeInternalGrantSuccess(benefit);
}

String redeemAccessCodeErrorMessage(
  AppLocalizations l10n,
  RedeemAccessCodeError error,
) =>
    switch (error) {
      RedeemAccessCodeError.invalidCode => l10n.redeemAccessCodeErrorInvalid,
      RedeemAccessCodeError.alreadyRedeemed => l10n.redeemAccessCodeErrorUsed,
      RedeemAccessCodeError.expired => l10n.redeemAccessCodeErrorExpired,
      RedeemAccessCodeError.unsupported =>
        l10n.redeemAccessCodeErrorUnsupported,
      RedeemAccessCodeError.campaignInactive =>
        l10n.redeemAccessCodeErrorCampaignInactive,
      RedeemAccessCodeError.roleNotEligible =>
        l10n.redeemAccessCodeErrorRoleNotEligible,
      RedeemAccessCodeError.redemptionLimitReached =>
        l10n.redeemAccessCodeErrorLimitReached,
      RedeemAccessCodeError.offerUnavailable =>
        l10n.redeemAccessCodeErrorOfferUnavailable,
      RedeemAccessCodeError.invalidPlatform =>
        l10n.redeemAccessCodeErrorInvalidPlatform,
      RedeemAccessCodeError.benefitCodeSecretMissing =>
        l10n.redeemAccessCodeErrorServiceUnavailable,
      RedeemAccessCodeError.unauthorized =>
        l10n.redeemAccessCodeErrorUnauthorized,
      RedeemAccessCodeError.unknown => l10n.redeemAccessCodeErrorUnknown,
    };

class _SubjectProfilesSection extends ConsumerWidget {
  const _SubjectProfilesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summariesAsync = ref.watch(profilesWithAssessmentsProvider);
    final selected = ref.watch(selectedSubjectProfileProvider);

    return summariesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(l10n.profileSubjectProfilesLoadFailed('$error')),
      ),
      data: (summaries) {
        if (summaries.isEmpty) {
          return ListTile(
            leading: const Icon(Icons.person_add_alt_outlined),
            title: Text(l10n.profileCreateFirst),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.onboardingForWhom),
          );
        }

        return Column(
          children: [
            for (final summary in summaries) ...[
              ListTile(
                leading: Icon(
                  summary.profile.profileType == 'adult_self'
                      ? Icons.person_outline
                      : Icons.child_care_outlined,
                  color: selected?.id == summary.profile.id
                      ? AppColors.primary
                      : null,
                ),
                title: Text(summary.profile.displayName),
                subtitle: Text(
                  _subjectProfileSubtitle(summary.profile, l10n),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: l10n.profileEditTooltip,
                      onPressed: () => _showSubjectProfileEditor(
                        context,
                        ref,
                        summary.profile,
                      ),
                    ),
                    if (selected?.id == summary.profile.id)
                      const Icon(Icons.check_circle, color: AppColors.primary)
                    else
                      TextButton(
                        onPressed: () => ref
                            .read(selectedSubjectProfileIdProvider.notifier)
                            .select(summary.profile.id),
                        child: Text(l10n.profileActivate),
                      ),
                  ],
                ),
              ),
              SubjectProfileReflexActionTile(
                summary: summary,
                onPressed: () {
                  ref
                      .read(selectedSubjectProfileIdProvider.notifier)
                      .select(summary.profile.id);
                  final assessment = summary.latestAssessment;
                  if (assessment != null) {
                    context.push(
                      Routes.reflexProfileResult,
                      extra: {'assessment': assessment},
                    );
                  } else {
                    context.push(
                      Routes.reflexProfile,
                      extra: {'subjectProfileId': summary.profile.id},
                    );
                  }
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: Text(l10n.profileAdd),
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
    final l10n = AppLocalizations.of(context);
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
          SnackBar(content: Text(l10n.profileSaved)),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSaveFailed('$error'))),
        );
      }
    }
  }

  static String _subjectProfileSubtitle(
    ReflexSubjectProfile profile,
    AppLocalizations l10n,
  ) {
    if (profile.profileType == 'adult_self') return l10n.profileAdult;
    final parts = <String>[l10n.profileChild];
    if (profile.ageYears != null) {
      parts.add(l10n.profileAgeYears(profile.ageYears!));
    }
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
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 6, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      helpText: l10n.profileSelectBirthDateHelp,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _error = null;
      });
    }
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l10n.profileNameRequired);
      return;
    }
    if (widget.profile.profileType == 'child' && _birthDate == null) {
      setState(() => _error = l10n.profileBirthDateRequired);
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
    final l10n = AppLocalizations.of(context);
    final isChild = widget.profile.profileType == 'child';

    return AlertDialog(
      title: Text(l10n.profileEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _error = null),
            decoration: InputDecoration(
              labelText:
                  isChild ? l10n.profileChildNameLabel : l10n.profileNameLabel,
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
                decoration: InputDecoration(
                  labelText: l10n.profileBirthDateLabel,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_month_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? l10n.profileSelectDate
                      : formatProfileBirthDate(
                          _birthDate!,
                          Localizations.localeOf(context),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(profileProvider);
    final displayName = profileAsync.valueOrNull?.displayName ?? '';

    if (!_editing && _ctrl.text != displayName) {
      _ctrl.text = displayName;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileDisplayNameLabel,
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
                  hintText: l10n.anonymous,
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
                child: Text(l10n.edit),
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
                    : Text(l10n.save),
              ),
          ],
        ),
        Text(
          // Ohne Community-Feed (T04) beschreibt der Untertitel nur die
          // verbleibende Verwendung des Anzeigenamens: den Trainer-Chat.
          kCommunityEnabled
              ? l10n.profileCommunityDisplayNameHint
              : l10n.profileTrainerDisplayNameHint,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final trimmed = _ctrl.text.trim();
    if (trimmed.isNotEmpty && trimmed.length < 3) {
      setState(() => _error = l10n.profileMinimumCharacters(3));
      return;
    }
    if (trimmed.contains('@')) {
      setState(() => _error = l10n.profileAtNotAllowed);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(profileProvider.notifier).save(
            displayName: trimmed.isEmpty ? null : trimmed,
          );
      if (mounted) setState(() => _editing = false);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.profileSaveFailedShort);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String formatProfileBirthDate(DateTime value, Locale locale) {
  final localeName = locale.toLanguageTag();
  // DE keeps its fixed dd.MM.yyyy format; other locales inherit yMd.
  if (locale.languageCode == AppLanguages.sourceCode) {
    return DateFormat('dd.MM.yyyy', localeName).format(value);
  }
  return DateFormat.yMd(localeName).format(value);
}
