import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../experience/domain/models/experience_share.dart';
import '../../../experience/presentation/providers/experience_providers.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/mood_provider.dart';
import '../../../training/domain/services/experience_prompt_service.dart';

/// Shows the post-training experience bottom sheet and marks the prompt as seen.
Future<void> showTrainingExperienceSheet(
  BuildContext context, {
  required String enrollmentId,
  required String packageId,
}) async {
  await ExperiencePromptService.markShown();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ProviderScope(
      child: TrainingExperienceSheet(
        enrollmentId: enrollmentId,
        packageId: packageId,
      ),
    ),
  );
}

class TrainingExperienceSheet extends ConsumerStatefulWidget {
  final String enrollmentId;
  final String packageId;

  const TrainingExperienceSheet({
    super.key,
    required this.enrollmentId,
    required this.packageId,
  });

  @override
  ConsumerState<TrainingExperienceSheet> createState() =>
      _TrainingExperienceSheetState();
}

class _TrainingExperienceSheetState
    extends ConsumerState<TrainingExperienceSheet> {
  int? _mood;
  int? _energy;
  int? _stress;
  final _noteController = TextEditingController();
  final Set<_UnitImpression> _unitImpressions = {};
  final Set<_SinceLastObservation> _sinceLastUnit = {};
  bool _shareWithCommunity = false;
  bool _anonymous = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Sharing should be anonymous by default. A profile preference can still
    // opt users into anonymous mode, but never silently opts them out here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isAnonDefault =
          ref.read(profileProvider).valueOrNull?.isAnonymousDefault ?? false;
      if (mounted && isAnonDefault) setState(() => _anonymous = true);
    });
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);

    try {
      final repo = ref.read(moodRepositoryProvider);
      final note = _composedNote(l10n);

      // 1. Save mood checkin.
      await repo.createCheckin(
        enrollmentId: widget.enrollmentId,
        mood: _mood,
        energy: _energy,
        stress: _stress,
        note: note,
        source: 'training',
      );

      // 2. Optionally share to community feed.
      if (kCommunityEnabled && _shareWithCommunity) {
        final profile = ref.read(profileProvider).valueOrNull;
        final displayName = _anonymous
            ? l10n.anonymous
            : profile?.effectiveDisplayName(l10n.anonymous) ?? l10n.anonymous;

        await ref.read(experienceRepositoryProvider).createShare(
              ExperienceShareInsert(
                packageId: widget.packageId,
                // Don't link checkinId: the checkin is stored in the local DB and
                // synced to Supabase asynchronously, so the FK would fail if the
                // row isn't replicated yet. Mood values are duplicated on the share.
                userId: Supabase.instance.client.auth.currentUser!.id,
                displayName: displayName,
                isAnonymous: _anonymous,
                content: note,
                mood: _mood,
                energy: _energy,
                stress: _stress,
              ),
            );
      }

      ref.invalidate(moodDailyAggregatesProvider);
      ref.invalidate(moodNotesProvider);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showErrorSnackBar(context, l10n.moodExperienceSaveFailed('$e'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _composedNote(AppLocalizations l10n) {
    final parts = <String>[];
    if (_unitImpressions.isNotEmpty) {
      parts.add(
        l10n.moodExperienceSessionNote(
          _unitImpressions
              .map((value) => _unitImpressionLabel(l10n, value))
              .join(', '),
        ),
      );
    }
    if (_sinceLastUnit.isNotEmpty) {
      parts.add(
        l10n.moodExperienceSinceLastSessionNote(
          _sinceLastUnit
              .map((value) => _sinceLastObservationLabel(l10n, value))
              .join(', '),
        ),
      );
    }
    final own = _noteController.text.trim();
    if (own.isNotEmpty) parts.add(own);
    if (parts.isEmpty) return null;
    return parts.join('\n\n');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.moodExperienceTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.moodExperienceDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 20),
          _ChipQuestion(
            options: _UnitImpression.values,
            selected: _unitImpressions,
            labelFor: (value) => _unitImpressionLabel(l10n, value),
            onToggle: (value) => setState(() {
              _unitImpressions.contains(value)
                  ? _unitImpressions.remove(value)
                  : _unitImpressions.add(value);
            }),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.moodExperienceSinceLastTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _ChipQuestion(
            options: _SinceLastObservation.values,
            selected: _sinceLastUnit,
            labelFor: (value) => _sinceLastObservationLabel(l10n, value),
            onToggle: (value) => setState(() {
              _sinceLastUnit.contains(value)
                  ? _sinceLastUnit.remove(value)
                  : _sinceLastUnit.add(value);
            }),
          ),
          const SizedBox(height: 18),
          _MetricRow(
            label: l10n.moodLabel,
            color: AppColors.moodRose,
            value: _mood,
            onChanged: (v) => setState(() => _mood = v),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.energyLabel,
            color: AppColors.moodTeal,
            value: _energy,
            onChanged: (v) => setState(() => _energy = v),
          ),
          const SizedBox(height: 10),
          _MetricRow(
            label: l10n.stressLabel,
            color: AppColors.moodGold,
            value: _stress,
            onChanged: (v) => setState(() => _stress = v),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.moodMetricSelectionHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _noteController,
            minLines: 3,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: l10n.moodExperienceOwnObservationHint,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          if (kCommunityEnabled) ...[
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.moodExperienceShare),
              value: _shareWithCommunity,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() {
                _shareWithCommunity = v ?? false;
                if (_shareWithCommunity) _anonymous = true;
              }),
            ),
            if (_shareWithCommunity)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.moodExperienceShareAnonymously),
                  value: _anonymous,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _anonymous = v ?? false),
                ),
              ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final Color color;
  final int? value;
  final ValueChanged<int?> onChanged;

  const _MetricRow({
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            emptySelectionAllowed: true,
            style: ButtonStyle(
              foregroundColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            segments: const [
              ButtonSegment(value: 1, label: Text('1')),
              ButtonSegment(value: 2, label: Text('2')),
              ButtonSegment(value: 3, label: Text('3')),
              ButtonSegment(value: 4, label: Text('4')),
              ButtonSegment(value: 5, label: Text('5')),
            ],
            selected: value != null ? {value!} : {},
            onSelectionChanged: (sel) =>
                onChanged(sel.isEmpty ? null : sel.first),
          ),
        ),
      ],
    );
  }
}

class _ChipQuestion<T> extends StatelessWidget {
  const _ChipQuestion({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.labelFor,
  });

  final List<T> options;
  final Set<T> selected;
  final ValueChanged<T> onToggle;
  final String Function(T) labelFor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelFor(option)),
            selected: selected.contains(option),
            selectedColor: AppColors.primary.withValues(alpha: 0.14),
            checkmarkColor: AppColors.primary,
            onSelected: (_) => onToggle(option),
          ),
      ],
    );
  }
}

enum _UnitImpression {
  calm,
  pleasant,
  tired,
  restless,
  emotional,
  physicallyUncomfortable,
  unsure,
}

enum _SinceLastObservation {
  moreCalm,
  moreEnergy,
  lessEnergy,
  moodChanged,
  moreEmotional,
  moreSensitive,
  betterSleep,
  restlessSleep,
  bodyTension,
  nothingNotable,
}

String _unitImpressionLabel(
  AppLocalizations l10n,
  _UnitImpression value,
) =>
    switch (value) {
      _UnitImpression.calm => l10n.moodExperienceImpressionCalm,
      _UnitImpression.pleasant => l10n.moodExperienceImpressionPleasant,
      _UnitImpression.tired => l10n.moodExperienceImpressionTired,
      _UnitImpression.restless => l10n.moodExperienceImpressionRestless,
      _UnitImpression.emotional => l10n.moodExperienceImpressionEmotional,
      _UnitImpression.physicallyUncomfortable =>
        l10n.moodExperienceImpressionPhysicallyUncomfortable,
      _UnitImpression.unsure => l10n.moodExperienceImpressionUnsure,
    };

String _sinceLastObservationLabel(
  AppLocalizations l10n,
  _SinceLastObservation value,
) =>
    switch (value) {
      _SinceLastObservation.moreCalm => l10n.moodExperienceSinceMoreCalm,
      _SinceLastObservation.moreEnergy => l10n.moodExperienceSinceMoreEnergy,
      _SinceLastObservation.lessEnergy => l10n.moodExperienceSinceLessEnergy,
      _SinceLastObservation.moodChanged => l10n.moodExperienceSinceMoodChanged,
      _SinceLastObservation.moreEmotional =>
        l10n.moodExperienceSinceMoreEmotional,
      _SinceLastObservation.moreSensitive =>
        l10n.moodExperienceSinceMoreSensitive,
      _SinceLastObservation.betterSleep => l10n.moodExperienceSinceBetterSleep,
      _SinceLastObservation.restlessSleep =>
        l10n.moodExperienceSinceRestlessSleep,
      _SinceLastObservation.bodyTension => l10n.moodExperienceSinceBodyTension,
      _SinceLastObservation.nothingNotable =>
        l10n.moodExperienceSinceNothingNotable,
    };
