import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/draft_persistence_service.dart';
import '../../domain/reflex_answer_json.dart';
import '../../domain/reflex_draft_meta.dart';
import '../../domain/reflex_profile_scoring.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';
import '../providers/reflex_profile_provider.dart';

class ReflexProfileScreen extends ConsumerStatefulWidget {
  const ReflexProfileScreen({super.key});

  @override
  ConsumerState<ReflexProfileScreen> createState() =>
      _ReflexProfileScreenState();
}

class _ReflexProfileScreenState extends ConsumerState<ReflexProfileScreen>
    with WidgetsBindingObserver {
  final _nameController = TextEditingController();
  final _textControllers = <String, TextEditingController>{};
  final _answers = <String, ReflexAnswerValue>{};
  final _warningConfirmations = <String, ReflexWarningConfirmation>{};
  final _scoringService = const ReflexProfileScoringService();
  final _questionnaireScrollController = ScrollController();
  final _questionKeys = <String, GlobalKey>{};
  final _draftService = DraftPersistenceService();
  final _debounceTimers = <String, Timer>{};
  Set<String> _highlightedQuestionIds = {};

  DateTime? _selectedBirthDate;

  ReflexSubjectProfile? _selectedProfile;
  bool _saving = false;
  bool _questionnaireStarted = false;
  String? _questionnaireFor; // 'child' or 'adult'
  int _currentModuleIndex = 0;
  bool _didReadRouteExtras = false;
  bool _fromOnboarding = false;
  String? _pendingSubjectProfileId;
  DateTime? _startedAt;
  final Map<String, dynamic> _moduleTimings = {};

  ReflexQuestionnaireDefinition get _definition => childParentQuestionnaireV1;

  Map<String, dynamic>? get _routeExtraMap {
    final extra = GoRouterState.of(context).extra;
    if (extra is Map<String, dynamic>) return extra;
    if (extra is Map) return Map<String, dynamic>.from(extra);
    return null;
  }

  String get _packageId {
    final extra = GoRouterState.of(context).extra;
    if (extra is String) return extra;
    return _routeExtraMap?['packageId'] as String? ?? 'moro';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didReadRouteExtras) return;
    _didReadRouteExtras = true;
    final map = _routeExtraMap;
    if (map == null || map['fromOnboarding'] != true) return;
    _fromOnboarding = true;
    _questionnaireFor = map['questionnaireFor'] as String?;
    _pendingSubjectProfileId = map['subjectProfileId'] as String?;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _nameController.dispose();
    _questionnaireScrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _questionnaireStarted) {
      _saveLocalDraft();
      _saveDraft();
    }
  }

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(
      questionId,
      TextEditingController.new,
    );
  }

  GlobalKey _keyFor(String questionId) =>
      _questionKeys.putIfAbsent(questionId, GlobalKey.new);

  Future<void> _createProfile() async {
    final name = _nameController.text.trim();
    final birthDate = _selectedBirthDate;
    final l10n = AppLocalizations.of(context);
    if (name.isEmpty || birthDate == null) {
      _showError(l10n.reflexProfileNameBirthRequired);
      return;
    }
    if (birthDate.isAfter(DateTime.now())) {
      _showError(l10n.reflexProfileBirthFuture);
      return;
    }

    setState(() => _saving = true);
    try {
      final profile = await createChildReflexSubjectProfile(
        ref,
        displayName: name,
        birthDate: birthDate,
      );
      if (mounted) {
        setState(() => _selectedProfile = profile);
        await _checkForDraft(profile.id);
      }
    } catch (e) {
      _showError(AppLocalizations.of(context).reflexProfileCreateChildFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _setYesNoAnswer(ReflexQuestion question, bool? value) async {
    if (value == true &&
        question.warningRule ==
            ReflexWarningRule.professionalClearanceRequired &&
        !_warningConfirmations.containsKey(question.id)) {
      final confirmed = await _showProfessionalClearanceDialog(question);
      if (!confirmed) return;
    }

    setState(() {
      _highlightedQuestionIds.remove(question.id);
      _answers[question.id] = ReflexAnswerValue(
        yesNoUnknown: value,
        isUnknown: value == null,
      );
    });
    _saveLocalDraft();
  }

  Future<bool> _showProfessionalClearanceDialog(
    ReflexQuestion question,
  ) async {
    const messageVersion = 'professional_clearance_v1';
    final locale = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l10n.reflexProfileClearanceTitle),
              content: Text(
                l10n.reflexProfileClearanceBody(question.text(locale)),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.reflexProfileClearanceConfirm),
                ),
              ],
            );
          },
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _warningConfirmations[question.id] = ReflexWarningConfirmation(
          questionId: question.id,
          confirmedAt: DateTime.now(),
          messageVersion: messageVersion,
        );
      });
      return true;
    }
    return false;
  }

  Future<void> _submit() async {
    final profile = _selectedProfile;
    if (profile == null || _saving) return;

    final visibleQuestions = _visibleQuestions;
    final missing = visibleQuestions.where((q) {
      if (q.answerType == ReflexAnswerType.freeText) return false;
      if (q.answerType == ReflexAnswerType.multiSelectWithText) return false;
      return !(_answers[q.id]?.isAnswered ?? false);
    }).toList();

    if (missing.isNotEmpty) {
      _showError(AppLocalizations.of(context).reflexProfileAnswerAllChoice);
      return;
    }

    setState(() => _saving = true);
    try {
      final score = _scoringService.score(
        definition: _definition,
        answers: _answers,
      );
      final scoresJson = {
        for (final entry in score.reflexScores.entries)
          entry.key.name: entry.value.toJson(),
      };

      await submitReflexProfileAssessment(
        ref,
        subjectProfileId: profile.id,
        packageId: _packageId,
        questionnaireType: 'child_parent_report',
        questionnaireVersion: _definition.version,
        answers: {
          for (final entry in _answers.entries)
            entry.key: _answerToJson(entry.value),
        },
        scores: scoresJson,
        warningConfirmations: _warningConfirmations.values
            .map(
              (confirmation) => {
                'question_id': confirmation.questionId,
                'confirmed_at': confirmation.confirmedAt.toIso8601String(),
                'message_version': confirmation.messageVersion,
              },
            )
            .toList(),
        safetyStatus: _warningConfirmations.isEmpty
            ? 'clear'
            : 'professional_clearance_confirmed',
      );

      deleteReflexProfileDraft(profile.id).ignore();
      _draftService.clearLocal(profile.id).ignore();
      if (mounted) {
        context.go(
          Routes.reflexProfileResult,
          extra: {
            'packageId': _packageId,
          },
        );
      }
    } catch (e) {
      _showError(AppLocalizations.of(context).reflexProfileCompleteFailed('$e'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _answerToJson(ReflexAnswerValue answer) =>
      reflexAnswerToJson(answer);

  ReflexAnswerValue _answerFromJson(Map<String, dynamic> raw) =>
      reflexAnswerFromJson(raw);

  ReflexDraftMeta _buildDraftMeta() {
    return ReflexDraftMeta(
      moduleIndex: _currentModuleIndex,
      questionnaireFor: _questionnaireFor ?? 'child',
      questionnaireVersion: _definition.version,
      filterAnswers: {
        for (final entry in _answers.entries)
          if (entry.key.startsWith('f_') && entry.value.choice != null)
            entry.key: switch (entry.value.choice!) {
              ReflexAnswerChoice.yes => 'yes',
              ReflexAnswerChoice.no => 'no',
              ReflexAnswerChoice.unknown => 'unknown',
              ReflexAnswerChoice.notApplicable => 'not_applicable',
            },
      },
      startedAt: _startedAt,
      moduleTimings: Map<String, dynamic>.from(_moduleTimings),
    );
  }

  void _saveDraft() {
    final profile = _selectedProfile;
    if (profile == null) return;
    final meta = _buildDraftMeta();
    saveReflexProfileDraft(
      subjectProfileId: profile.id,
      packageId: _packageId,
      questionnaireVersion: _definition.version,
      answersJson: {
        for (final e in _answers.entries) e.key: _answerToJson(e.value),
      },
      warningConfirmations: _warningConfirmations.values
          .map((c) => {
                'question_id': c.questionId,
                'confirmed_at': c.confirmedAt.toIso8601String(),
                'message_version': c.messageVersion,
              })
          .toList(),
      currentModuleIndex: _currentModuleIndex,
      questionnaireFor: _questionnaireFor ?? 'child',
      filterAnswers: meta.filterAnswers,
      startedAt: meta.startedAt,
      moduleTimings: meta.moduleTimings,
      supersededItemIds: meta.supersededItemIds,
    ).ignore();
  }

  void _saveLocalDraft() {
    final profile = _selectedProfile;
    if (profile == null || !_questionnaireStarted) return;
    _draftService.saveLocal(profile.id, {
      'saved_at': DateTime.now().toIso8601String(),
      'answers': {
        '__meta': _buildDraftMeta().toJson(),
        for (final e in _answers.entries) e.key: _answerToJson(e.value),
      },
      'warning_confirmations': _warningConfirmations.values
          .map((c) => {
                'question_id': c.questionId,
                'confirmed_at': c.confirmedAt.toIso8601String(),
                'message_version': c.messageVersion,
              })
          .toList(),
    });
  }

  Future<void> _showExitConfirmation() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.reflexProfileLeaveTitle),
          content: Text(l10n.reflexProfileLeaveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.leave),
            ),
          ],
        );
      },
    );
    if (leave == true && mounted) {
      _saveLocalDraft();
      context.pop();
    }
  }

  void _scheduleDraftSave(String questionId) {
    _debounceTimers[questionId]?.cancel();
    _debounceTimers[questionId] = Timer(
      const Duration(milliseconds: 300),
      _saveLocalDraft,
    );
  }

  Future<void> _checkForDraft(String profileId) async {
    final localRaw = await _draftService.loadLocal(profileId);
    final cloudRaw = await loadReflexProfileDraft(profileId);
    if (!mounted) return;

    Map<String, dynamic>? best;
    if (localRaw != null && cloudRaw != null) {
      final localSavedAt =
          DateTime.tryParse(localRaw['saved_at'] as String? ?? '');
      final cloudUpdatedAt =
          DateTime.tryParse(cloudRaw['updated_at'] as String? ?? '');
      if (localSavedAt != null && cloudUpdatedAt != null) {
        best = localSavedAt.isAfter(cloudUpdatedAt) ? localRaw : cloudRaw;
      } else if (localSavedAt != null) {
        best = localRaw;
      } else {
        best = cloudRaw;
      }
    } else {
      best = cloudRaw ?? localRaw;
    }

    if (best == null) {
      setState(() {
        _questionnaireStarted = true;
        _currentModuleIndex = 0;
        _startedAt = DateTime.now();
        _moduleTimings.clear();
      });
      return;
    }

    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.reflexProfileResumeTitle),
          content: Text(l10n.reflexProfileResumeBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.reflexProfileStartOver),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.resume),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (resume == true) {
      _restoreDraft(best);
    } else {
      deleteReflexProfileDraft(profileId).ignore();
      _draftService.clearLocal(profileId).ignore();
      setState(() {
        _questionnaireStarted = true;
        _currentModuleIndex = 0;
        _startedAt = DateTime.now();
        _moduleTimings.clear();
        _answers.clear();
        _warningConfirmations.clear();
      });
    }
  }

  void _restoreDraft(Map<String, dynamic> row) {
    final answersRaw =
        (row['answers'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final metaRaw =
        (answersRaw['__meta'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final meta = ReflexDraftMeta.fromJson(metaRaw);

    final restoredAnswers = <String, ReflexAnswerValue>{};
    for (final entry in answersRaw.entries) {
      if (entry.key == '__meta') continue;
      final raw = entry.value;
      if (raw is Map<String, dynamic>) {
        restoredAnswers[entry.key] = _answerFromJson(raw);
      } else if (raw is Map) {
        restoredAnswers[entry.key] =
            _answerFromJson(Map<String, dynamic>.from(raw));
      }
    }

    final confirmations = <String, ReflexWarningConfirmation>{};
    final rawConfs = row['warning_confirmations'] as List? ?? [];
    for (final c in rawConfs.cast<Map<String, dynamic>>()) {
      final qid = c['question_id'] as String? ?? '';
      if (qid.isEmpty) continue;
      confirmations[qid] = ReflexWarningConfirmation(
        questionId: qid,
        confirmedAt: DateTime.tryParse(c['confirmed_at'] as String? ?? '') ??
            DateTime.now(),
        messageVersion:
            c['message_version'] as String? ?? 'professional_clearance_v1',
      );
    }

    setState(() {
      _answers
        ..clear()
        ..addAll(restoredAnswers);
      _warningConfirmations
        ..clear()
        ..addAll(confirmations);
      _questionnaireFor = meta.questionnaireFor;
      _questionnaireStarted = true;
      _currentModuleIndex = meta.moduleIndex;
      _startedAt = meta.startedAt ?? DateTime.now();
      _moduleTimings
        ..clear()
        ..addAll(meta.moduleTimings);
    });

    // Restore text controllers for free-text answers
    for (final entry in restoredAnswers.entries) {
      final text = entry.value.text;
      if (text != null && text.isNotEmpty) {
        _controllerFor(entry.key).text = text;
      }
    }
  }

  List<ReflexQuestion> get _visibleQuestions {
    return _definition.questions.where((question) {
      if (question.followUpOf == 'q031') {
        return _answers['q031']?.yesNoUnknown == false;
      }
      return true;
    }).toList();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _resolvePendingSubjectProfile(List<ReflexSubjectProfile> profiles) {
    final pendingId = _pendingSubjectProfileId;
    if (pendingId == null || _selectedProfile != null) return;
    for (final profile in profiles) {
      if (profile.id == pendingId) {
        _selectedProfile = profile;
        _pendingSubjectProfileId = null;
        return;
      }
    }
  }

  void _handleAppBarBack() {
    if (_questionnaireStarted) {
      _showExitConfirmation();
      return;
    }
    if (_questionnaireFor != null) {
      if (_fromOnboarding) {
        context.go(Routes.onboardingForWhom);
        return;
      }
      setState(() {
        _questionnaireFor = null;
        _selectedProfile = null;
      });
      return;
    }
    if (_fromOnboarding) {
      context.go(Routes.onboardingForWhom);
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(reflexSubjectProfilesProvider);
    final locale = Localizations.localeOf(context).languageCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleAppBarBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_definition.screenTitle(locale)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleAppBarBack,
          ),
        ),
        body: SafeArea(
          child: profilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(AppLocalizations.of(context)
                    .reflexProfileLoadProfilesFailed('$error')),
              ),
            ),
            data: (profiles) {
              _resolvePendingSubjectProfile(profiles);
              if (_questionnaireFor == null) {
                return _buildForWhom();
              }
              if (_questionnaireFor == 'adult') {
                return _buildAdultComingSoon();
              }
              if (!_questionnaireStarted) {
                return _buildStart(profiles);
              }
              return _buildQuestionnaire();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildForWhom() {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      children: [
        const Icon(Icons.people_outline, size: 44, color: AppColors.primary),
        const SizedBox(height: 18),
        Text(
          l10n.reflexProfileForWhomTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.reflexProfileForWhomBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 28),
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.child_care_outlined,
                color: AppColors.primary, size: 28),
            title: Text(
              l10n.reflexProfileForMyChild,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(l10n.reflexProfileParentQuestionnaire),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _questionnaireFor = 'child'),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Icon(Icons.person_outline,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 28),
            title: Text(
              l10n.reflexProfileForMyself,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            subtitle: Text(l10n.reflexProfileForMyselfComingSoon),
            trailing: const Icon(Icons.lock_outline, size: 16),
            onTap: () => setState(() => _questionnaireFor = 'adult'),
          ),
        ),
      ],
    );
  }

  Widget _buildAdultComingSoon() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined,
                size: 48, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              l10n.reflexProfileAdultComingSoonTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              l10n.reflexProfileAdultComingSoonBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _handleAppBarBack,
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStart(List<ReflexSubjectProfile> profiles) {
    final l10n = AppLocalizations.of(context);
    final seededProfile =
        _fromOnboarding ? _selectedProfile : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        const Icon(
          Icons.insights_outlined,
          size: 44,
          color: AppColors.primary,
        ),
        const SizedBox(height: 18),
        Text(
          l10n.reflexProfileOrientationTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.reflexProfileOrientationBody,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        const SizedBox(height: 20),
        if (seededProfile != null) ...[
          Text(
            seededProfile.displayName.isEmpty
                ? l10n.profile
                : seededProfile.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () => _checkForDraft(seededProfile.id),
            icon: const Icon(Icons.assignment_outlined),
            label: Text(l10n.reflexProfileStartQuestionnaire),
          ),
        ] else ...[
          if (profiles.isNotEmpty) ...[
            Text(
              l10n.reflexProfileSelectChild,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            for (final profile in profiles)
              Card(
                child: ListTile(
                  leading: Icon(
                    _selectedProfile?.id == profile.id
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: _selectedProfile?.id == profile.id
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    profile.displayName.isEmpty
                        ? l10n.profile
                        : profile.displayName,
                  ),
                  subtitle: Text(
                    [
                      if (profile.ageYears != null)
                        l10n.yearsCount(profile.ageYears!),
                      if (profile.ageGroup != null) profile.ageGroup!,
                    ].join(' · '),
                  ),
                  onTap: () => setState(() => _selectedProfile = profile),
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _selectedProfile == null
                  ? null
                  : () => _checkForDraft(_selectedProfile!.id),
              icon: const Icon(Icons.assignment_outlined),
              label: Text(l10n.reflexProfileStartQuestionnaire),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            l10n.reflexProfileNewChild,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l10n.reflexProfileNameOrNickname,
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
                helpText: l10n.reflexProfilePickBirthDate,
              );
              if (picked != null) {
                setState(() => _selectedBirthDate = picked);
              }
            },
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: l10n.reflexProfileBirthDateRequired,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_month_outlined),
                helperText: _selectedBirthDate == null
                    ? l10n.reflexProfileBirthDateHelper
                    : null,
              ),
              child: Text(
                _selectedBirthDate == null
                    ? l10n.reflexProfileSelectDate
                    : '${_selectedBirthDate!.day.toString().padLeft(2, '0')}.'
                        '${_selectedBirthDate!.month.toString().padLeft(2, '0')}.'
                        '${_selectedBirthDate!.year}',
                style: _selectedBirthDate == null
                    ? TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving ? null : _createProfile,
            icon: const Icon(Icons.person_add_alt_1_outlined),
            label: Text(
              _saving ? l10n.saving : l10n.reflexProfileCreateAndStart,
            ),
          ),
        ],
      ],
    );
  }

  List<ReflexQuestionModule> get _activeModules {
    final seen = <ReflexQuestionModule>{};
    final result = <ReflexQuestionModule>[];
    for (final q in _visibleQuestions) {
      if (seen.add(q.module)) result.add(q.module);
    }
    return result;
  }

  void _nextModule() {
    final activeModules = _activeModules;
    final currentModule = activeModules[_currentModuleIndex];
    final questionsForModule =
        _visibleQuestions.where((q) => q.module == currentModule).toList();

    final missing = questionsForModule.where((q) {
      if (q.answerType == ReflexAnswerType.freeText) return false;
      if (q.answerType == ReflexAnswerType.multiSelectWithText) return false;
      return !(_answers[q.id]?.isAnswered ?? false);
    }).toList();

    if (missing.isNotEmpty) {
      setState(() {
        _highlightedQuestionIds = missing.map((q) => q.id).toSet();
      });
      _showError(AppLocalizations.of(context).reflexProfileAnswerRequiredSection);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _questionKeys[missing.first.id];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            alignment: 0.1,
          );
        }
      });
      return;
    }

    setState(() {
      _highlightedQuestionIds = {};
      _currentModuleIndex++;
    });
    _saveDraft();
    _questionnaireScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _prevModule() {
    setState(() => _currentModuleIndex--);
    _questionnaireScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Widget _buildQuestionnaire() {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final activeModules = _activeModules;
    final safeIndex = _currentModuleIndex.clamp(0, activeModules.length - 1);
    final currentModule = activeModules[safeIndex];
    final questionsForModule =
        _visibleQuestions.where((q) => q.module == currentModule).toList();
    final isFirst = safeIndex == 0;
    final isLast = safeIndex == activeModules.length - 1;
    final progress = (safeIndex + 1) / activeModules.length;

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          color: AppColors.primary,
          minHeight: 4,
        ),
        Expanded(
          child: ListView(
            controller: _questionnaireScrollController,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedProfile?.displayName.isNotEmpty == true
                              ? _selectedProfile!.displayName
                              : l10n.reflexProfileChildFallback,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () =>
                                setState(() => _questionnaireStarted = false),
                        child: Text(l10n.switchAction),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.reflexProfileSectionOf(
                  safeIndex + 1,
                  activeModules.length,
                ),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                currentModule.title(locale),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 16),
              for (final question in questionsForModule)
                _buildQuestion(question),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                if (!isFirst)
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _prevModule,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.back),
                  ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _saving ? null : (isLast ? _submit : _nextModule),
                  icon: Icon(isLast
                      ? Icons.check_circle_outline
                      : Icons.arrow_forward),
                  label: Text(_saving
                      ? l10n.saving
                      : (isLast ? l10n.finish : l10n.next)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion(ReflexQuestion question) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final helpText = question.helpText(locale);
    final highlighted = _highlightedQuestionIds.contains(question.id);
    return Padding(
      key: _keyFor(question.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: highlighted
            ? Theme.of(context)
                .colorScheme
                .errorContainer
                .withValues(alpha: 0.35)
            : null,
        shape: highlighted
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 1.5,
                ),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${question.number}. ${question.text(locale)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (helpText != null) ...[
                const SizedBox(height: 8),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(l10n.reflexProfileWhatIsMeant),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        helpText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              height: 1.4,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              switch (question.answerType) {
                ReflexAnswerType.yesNoUnknown => _buildYesNoUnknown(question),
                // Adult four-way answers land in Phase 5. Until then, keep the
                // existing three-button control so the enum addition compiles
                // without unlocking the adult questionnaire UI.
                ReflexAnswerType.yesNoUnknownNotApplicable =>
                  _buildYesNoUnknown(question),
                ReflexAnswerType.monthsNumber => _buildMonths(question),
                ReflexAnswerType.freeText => _buildFreeText(question),
                ReflexAnswerType.multiSelectWithText =>
                  _buildMultiSelectWithText(question),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYesNoUnknown(ReflexQuestion question) {
    final l10n = AppLocalizations.of(context);
    final value = _answers[question.id];
    return Row(
      children: [
        Expanded(
          child: _AnswerButton(
            label: l10n.yes,
            selected: value?.yesNoUnknown == true,
            onTap: () => _setYesNoAnswer(question, true),
            accentColor: const Color(0xFF00C882),
            icon: Icons.check,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _AnswerButton(
            label: l10n.no,
            selected: value?.yesNoUnknown == false,
            onTap: () => _setYesNoAnswer(question, false),
            accentColor: AppColors.error,
            icon: Icons.close,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _AnswerButton(
            label: l10n.answerUnknown,
            selected: value?.isUnknown == true,
            onTap: () => _setYesNoAnswer(question, null),
            accentColor: const Color(0xFF5B8AF0),
            icon: Icons.help_outline,
          ),
        ),
      ],
    );
  }

  Widget _buildMonths(ReflexQuestion question) {
    final l10n = AppLocalizations.of(context);
    final controller = _controllerFor(question.id);
    final isUnknown = _answers[question.id]?.isUnknown ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUnknown)
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.reflexProfileMonthsLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _answers[question.id] = ReflexAnswerValue(
                  months: int.tryParse(value.trim()),
                );
              });
              _scheduleDraftSave(question.id);
            },
          ),
        const SizedBox(height: 8),
        _AnswerButton(
          label: l10n.answerUnknown,
          selected: isUnknown,
          accentColor: const Color(0xFFE97356),
          icon: Icons.help_outline,
          onTap: () {
            setState(() {
              if (isUnknown) {
                controller.clear();
                _answers[question.id] = const ReflexAnswerValue();
              } else {
                controller.clear();
                _answers[question.id] =
                    const ReflexAnswerValue(isUnknown: true);
              }
            });
            _saveLocalDraft();
          },
        ),
      ],
    );
  }

  Widget _buildFreeText(ReflexQuestion question) {
    final l10n = AppLocalizations.of(context);
    final controller = _controllerFor(question.id);
    return TextField(
      controller: controller,
      minLines: 2,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: l10n.reflexProfileFreeTextLabel,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        setState(() {
          _answers[question.id] = ReflexAnswerValue(text: value);
        });
        _scheduleDraftSave(question.id);
      },
    );
  }

  Widget _buildMultiSelectWithText(ReflexQuestion question) {
    final l10n = AppLocalizations.of(context);
    final answer = _answers[question.id] ?? const ReflexAnswerValue();
    final controller = _controllerFor(question.id);
    return Column(
      children: [
        for (final option in question.options)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: answer.selectedOptionIds.contains(option.id),
            title: Text(option.label),
            onChanged: (checked) {
              final selected = [...answer.selectedOptionIds];
              if (checked == true && !selected.contains(option.id)) {
                selected.add(option.id);
              } else {
                selected.remove(option.id);
              }
              setState(() {
                _answers[question.id] = ReflexAnswerValue(
                  selectedOptionIds: selected,
                  text: controller.text,
                );
              });
              _saveLocalDraft();
            },
          ),
        TextField(
          controller: controller,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.reflexProfileOtherLabel,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) {
            setState(() {
              _answers[question.id] = ReflexAnswerValue(
                selectedOptionIds: answer.selectedOptionIds,
                text: value,
              );
            });
            _scheduleDraftSave(question.id);
          },
        ),
      ],
    );
  }
}

/// Answer button with per-answer-type colour + icon — accessible for colour-blind users.
/// Unselected: accent tint background + accent border + accent icon.
/// Selected:   full accent fill + white filled icon + glow shadow.
class _AnswerButton extends StatelessWidget {
  const _AnswerButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
    required this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;
  final IconData icon;

  IconData get _activeIcon => switch (icon) {
        Icons.check => Icons.check_circle,
        Icons.close => Icons.cancel,
        _ => Icons.help,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? accentColor : accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: accentColor.withValues(alpha: selected ? 1.0 : 0.55),
            width: selected ? 2.0 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: accentColor.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 3))
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? _activeIcon : icon,
              size: 16,
              color: selected ? Colors.white : accentColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white : accentColor,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
