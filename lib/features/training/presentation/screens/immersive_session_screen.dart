import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/adaptive_tempo_settings.dart';
import '../../../../core/training/training_announcement_manifest.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../core/training/training_session_checkpoint_store.dart';
import '../../../../core/training/transition_duration_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';
import '../../domain/services/audio_announcement_service.dart';
import '../../domain/services/rhythm_cue_player.dart';
import '../../domain/session/session_orchestrator.dart';
import '../services/in_app_music_service.dart';
import '../widgets/exercise_transition_widget.dart';
import 'immersive_exercise_screen.dart';

class ImmersiveSessionScreen extends StatefulWidget {
  const ImmersiveSessionScreen({
    super.key,
    required this.exercises,
    required this.mode,
    required this.packageId,
    required this.contentVersion,
    required this.sessionId,
    required this.profileId,
    required this.completedSessions,
    this.restoredState,
    this.companionSubjectProfileIds = const [],
    this.rhythmCuePlayerFactory,
    required this.persistCompletion,
    required this.onCompleted,
    required this.onCancelled,
  });

  final List<Exercise> exercises;
  final TrainingSessionMode mode;
  final String packageId;
  final String contentVersion;
  final String sessionId;
  final String profileId;
  final int completedSessions;
  final TrainingSessionState? restoredState;
  final List<String> companionSubjectProfileIds;

  /// Optional seam for deterministic widget tests without platform audio.
  final RhythmCuePlayer Function()? rhythmCuePlayerFactory;

  /// Must atomically persist session, progress and sync intent.
  final Future<void> Function(TrainingSessionState state) persistCompletion;

  /// Presentation callback after persistence and checkpoint cleanup succeed.
  final ValueChanged<TrainingSessionState> onCompleted;

  /// Returns to the caller only after a deliberate discard is durably cleared.
  final VoidCallback onCancelled;

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen>
    with WidgetsBindingObserver {
  final Stopwatch _monotonicClock = Stopwatch();

  SessionOrchestrator? _orchestrator;
  TrainingSessionState? _state;
  TrainingSessionCheckpointStore? _checkpointStore;
  TrainingSessionCheckpointWriteQueue? _checkpointWriter;
  RhythmCuePlayer? _rhythmCuePlayer;
  SharedPreferences? _prefs;
  TrainingAnnouncementManifest? _announcementManifest;
  StreamSubscription<TrainingSessionState>? _stateSubscription;
  StreamSubscription<TrainingSessionSignal>? _signalSubscription;
  StreamSubscription<void>? _audioInterruptionSubscription;
  Timer? _ticker;
  Duration _lastClockReading = Duration.zero;
  String? _lastCheckpointSignature;
  String? _initializationError;
  String? _completionError;
  String _locale = 'en';
  bool _initializationStarted = false;
  bool _voiceGuidanceAvailable = false;
  bool _completionInFlight = false;
  bool _completionDelivered = false;
  bool _endRequestInFlight = false;
  bool _announcementInFlight = false;
  int _announcementAttempt = 0;
  int _audioGeneration = 0;
  int? _lastPreparationCue;
  TrainingFeedbackMode _feedbackMode = TrainingFeedbackMode.voiceAndCues;

  bool get _isRoutineMode => widget.mode == TrainingSessionMode.routine;
  bool get _isDuo => widget.companionSubjectProfileIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).toLanguageTag();
    if (!_initializationStarted) {
      _initializationStarted = true;
      unawaited(_initialize());
    }
  }

  Future<void> _initialize() async {
    try {
      if (widget.exercises.isEmpty) {
        throw StateError('The training snapshot contains no exercises.');
      }

      final prefs = await SharedPreferences.getInstance();
      final feedbackMode =
          await TrainingFeedbackSettings.migrateFeedbackMode(prefs);
      final transitionSeconds =
          TransitionDurationSettings.durationSeconds(prefs);
      final tempoByExercise = <String, double>{};
      for (final exercise in widget.exercises) {
        final tempo = AdaptiveTempoSettings.tempoForExercise(
          prefs: prefs,
          profileId: widget.profileId,
          packageId: widget.packageId,
          contentVersion: widget.contentVersion,
          exerciseId: exercise.id,
          legacyExerciseNumber: exercise.sequenceNumber,
        );
        if (tempo != null) tempoByExercise[exercise.id] = tempo;
      }

      TrainingAnnouncementManifest? manifest;
      var voiceReady = false;
      try {
        manifest = await TrainingAnnouncementManifest.loadBundled();
        final report = await manifest.preflight(
          requestedLocale: _locale,
          assetExists: (bundleAssetKey) =>
              TrainingAnnouncementManifest.assetExistsInBundle(
            rootBundle,
            bundleAssetKey,
          ),
          requiredEntryIds: _requiredAnnouncementIds(
            widget.exercises,
            isDuo: _isDuo,
          ),
        );
        voiceReady = report.isReady;
      } on Object {
        voiceReady = false;
      }

      final orchestrator = SessionOrchestrator(
        exercises: widget.exercises,
        sessionId: widget.sessionId,
        packageId: widget.packageId,
        contentVersion: widget.contentVersion,
        mode: widget.mode,
        routinePreparationDuration: Duration(seconds: transitionSeconds),
        tempoSecondsByExerciseId: tempoByExercise,
        restoredState: widget.restoredState,
      );
      final checkpointStore = TrainingSessionCheckpointStore(prefs);
      final rhythmCuePlayer = widget.rhythmCuePlayerFactory?.call() ??
          RhythmCuePlayer(
            onInterruption: () {
              _pause(reason: TrainingPauseReason.audioInterruption);
            },
          );
      await rhythmCuePlayer.initialize();
      final audioGeneration =
          AudioAnnouncementService.instance.startGeneration();

      if (!mounted) {
        await rhythmCuePlayer.dispose();
        await orchestrator.dispose();
        return;
      }

      _prefs = prefs;
      _checkpointStore = checkpointStore;
      _checkpointWriter = TrainingSessionCheckpointWriteQueue(
        save: (state) => checkpointStore.save(
          profileId: widget.profileId,
          state: state,
        ),
      );
      _feedbackMode = feedbackMode;
      _rhythmCuePlayer = rhythmCuePlayer;
      _announcementManifest = manifest;
      _voiceGuidanceAvailable = voiceReady;
      _audioGeneration = audioGeneration;
      _orchestrator = orchestrator;
      _state = orchestrator.state;
      _stateSubscription = orchestrator.states.listen(_handleState);
      _signalSubscription = orchestrator.signals.listen(_handleSignal);
      _audioInterruptionSubscription =
          AudioAnnouncementService.instance.interruptions.listen((_) {
        _pause(reason: TrainingPauseReason.audioInterruption);
      });
      _monotonicClock.start();
      _lastClockReading = _monotonicClock.elapsed;
      _ticker = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _advanceFromMonotonicClock(),
      );
      setState(() {});

      if (orchestrator.state.stage == TrainingSessionStage.completed) {
        unawaited(_persistCompletedState(orchestrator.state));
      } else if (orchestrator.state.stage == TrainingSessionStage.preflight) {
        orchestrator.start();
      } else {
        _queueCheckpoint(orchestrator.state, force: true);
      }
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _initializationError = error.toString());
    }
  }

  void _advanceFromMonotonicClock() {
    final orchestrator = _orchestrator;
    if (orchestrator == null) return;
    final now = _monotonicClock.elapsed;
    final elapsed = now - _lastClockReading;
    _lastClockReading = now;
    orchestrator.advance(elapsed);
  }

  void _handleState(TrainingSessionState state) {
    _state = state;
    if (state.stage != TrainingSessionStage.cancelled &&
        state.stage != TrainingSessionStage.failure) {
      _queueCheckpoint(state);
    }
    _maybePlayPreparationCue(state);
    if (mounted) setState(() {});
  }

  void _handleSignal(TrainingSessionSignal signal) {
    final orchestrator = _orchestrator;
    if (orchestrator == null) return;
    unawaited(
      _rhythmCuePlayer?.handleSignal(
            signal,
            tonesEnabled: _feedbackMode.policy.allowsTones,
          ) ??
          Future.value(),
    );
    switch (signal.type) {
      case TrainingSessionSignalType.exerciseAnnouncement:
        unawaited(_handleAnnouncement(signal));
        return;
      case TrainingSessionSignalType.phaseStarted:
        _playManifestEntries(
          [
            'exercise.${orchestrator.currentExercise.id}.phase.${signal.phaseIndex + 1}'
          ],
        );
        return;
      case TrainingSessionSignalType.beat:
        if (_feedbackMode.policy.allowsHaptics) {
          unawaited(HapticFeedback.lightImpact());
        }
        return;
      case TrainingSessionSignalType.repetitionCompleted:
        if (_feedbackMode.policy.allowsHaptics) {
          unawaited(HapticFeedback.mediumImpact());
        }
        _playManifestEntries(['exercise.repetition.complete']);
        return;
      case TrainingSessionSignalType.sideSwitch:
        if (_feedbackMode.policy.allowsHaptics) {
          unawaited(HapticFeedback.heavyImpact());
        }
        _playManifestEntries(
          ['exercise.switch_side'],
          priority: AnnouncementPriority.high,
        );
        return;
      case TrainingSessionSignalType.recoveryStarted:
        _playManifestEntries(['exercise.rest']);
        return;
      case TrainingSessionSignalType.exerciseCompleted:
        return;
      case TrainingSessionSignalType.paused:
        _stopAnnouncements();
        unawaited(InAppMusicService.instance.stop());
        return;
      case TrainingSessionSignalType.resumed:
        if (orchestrator.state.stage ==
            TrainingSessionStage.exerciseAnnouncement) {
          unawaited(
            _handleAnnouncement(
              TrainingSessionSignal(
                type: TrainingSessionSignalType.exerciseAnnouncement,
                exerciseIndex: orchestrator.state.exerciseIndex,
                repetitionIndex: orchestrator.state.repetitionIndex,
                phaseIndex: orchestrator.state.phaseIndex,
              ),
            ),
          );
        } else {
          _playManifestEntries(
            [
              'session.resume',
              if (orchestrator.state.stage == TrainingSessionStage.recovery)
                'exercise.rest',
            ],
            priority: AnnouncementPriority.high,
          );
        }
        return;
      case TrainingSessionSignalType.sessionCompleted:
        if (_feedbackMode.policy.allowsHaptics) {
          unawaited(HapticFeedback.heavyImpact());
        }
        _playManifestEntries(
          ['session.complete'],
          priority: AnnouncementPriority.critical,
        );
        unawaited(_persistCompletedState(orchestrator.state));
        return;
      case TrainingSessionSignalType.cancelled:
        return;
      case TrainingSessionSignalType.preparationStarted:
        _lastPreparationCue = null;
        return;
    }
  }

  Future<void> _handleAnnouncement(TrainingSessionSignal signal) async {
    if (_announcementInFlight) return;
    final orchestrator = _orchestrator;
    if (orchestrator == null) return;
    final attempt = ++_announcementAttempt;
    _announcementInFlight = true;
    try {
      final exercise = orchestrator.exercises[signal.exerciseIndex];
      await _playManifestEntries(
        [
          if (signal.exerciseIndex == 0) 'session.safety',
          'exercise.${exercise.id}.name',
          'exercise.${exercise.id}.position.${_isDuo ? 'duo' : 'solo'}',
        ],
        priority: AnnouncementPriority.high,
        waitForCompletion: true,
      );
      if (attempt == _announcementAttempt &&
          !signal.isReplay &&
          _isRoutineMode &&
          orchestrator.state.stage ==
              TrainingSessionStage.exerciseAnnouncement) {
        orchestrator.announcementFinished();
      }
    } finally {
      if (attempt == _announcementAttempt) {
        _announcementInFlight = false;
      }
    }
  }

  Future<void> _playManifestEntries(
    List<String> entryIds, {
    AnnouncementPriority priority = AnnouncementPriority.normal,
    bool waitForCompletion = false,
  }) async {
    if (!_voiceGuidanceAvailable ||
        !_feedbackMode.policy.allowsVoice ||
        entryIds.isEmpty) {
      return;
    }
    final manifest = _announcementManifest;
    if (manifest == null) return;
    final assets = <String>[];
    for (final id in entryIds) {
      final asset = manifest.assetKeyFor(_locale, id);
      if (asset != null) assets.add(asset);
    }
    if (assets.isEmpty) return;
    final future = AudioAnnouncementService.instance.queue(
      assets,
      priority: priority,
      generation: _audioGeneration,
    );
    if (waitForCompletion) {
      await future;
    } else {
      unawaited(future);
    }
  }

  void _maybePlayPreparationCue(TrainingSessionState state) {
    if (state.stage != TrainingSessionStage.preparation ||
        !_voiceGuidanceAvailable) {
      return;
    }
    final seconds = (state.remaining.inMilliseconds / 1000).ceil();
    if (seconds < 1 || seconds > 3 || seconds == _lastPreparationCue) return;
    _lastPreparationCue = seconds;
    _playManifestEntries(
      ['session.countdown.$seconds'],
      priority: AnnouncementPriority.high,
    );
  }

  void _queueCheckpoint(
    TrainingSessionState state, {
    bool force = false,
  }) {
    final writer = _checkpointWriter;
    if (writer == null) return;
    final signature = [
      state.stage.name,
      state.exerciseIndex,
      state.repetitionIndex,
      state.phaseIndex,
      state.remaining.inSeconds,
      state.completedExerciseIds.length,
      state.pauseReason?.name,
    ].join(':');
    if (!force && signature == _lastCheckpointSignature) return;
    _lastCheckpointSignature = signature;
    writer.enqueue(state);
  }

  Future<void> _persistCompletedState(TrainingSessionState state) async {
    if (_completionInFlight || _completionDelivered) return;
    _completionInFlight = true;
    if (mounted) {
      setState(() => _completionError = null);
    }
    try {
      final writer = _checkpointWriter;
      final checkpointStore = _checkpointStore;
      if (writer == null || checkpointStore == null) {
        throw StateError('Session checkpoint persistence is unavailable.');
      }
      await writer.saveRequired(state);
      await widget.persistCompletion(state);
      await checkpointStore.clear(
        profileId: widget.profileId,
        packageId: widget.packageId,
        contentVersion: widget.contentVersion,
      );
      _completionDelivered = true;
      if (mounted) widget.onCompleted(state);
    } on Object {
      if (mounted) {
        setState(() {
          _completionError =
              AppLocalizations.of(context).trainingCompletionSaveFailed;
        });
      }
    } finally {
      _completionInFlight = false;
      if (mounted) setState(() {});
    }
  }

  void _pause({TrainingPauseReason reason = TrainingPauseReason.user}) {
    final orchestrator = _orchestrator;
    if (orchestrator == null || orchestrator.state.isPaused) return;
    orchestrator.pause(reason: reason);
    if (reason == TrainingPauseReason.user) {
      _playManifestEntries(
        ['session.pause'],
        priority: AnnouncementPriority.critical,
      );
    }
  }

  void _resume() {
    _lastClockReading = _monotonicClock.elapsed;
    _orchestrator?.resume();
  }

  Future<void> _repeatCurrentGuidance() async {
    final orchestrator = _orchestrator;
    if (orchestrator == null) return;
    if (!_voiceGuidanceAvailable || !_feedbackMode.policy.allowsVoice) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.trainingAudioContentUnavailableTitle),
          content: Text(l10n.trainingAudioContentUnavailableBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
      return;
    }

    if (!orchestrator.state.isPaused) {
      _pause();
    }
    _stopAnnouncements();
    orchestrator.repeatCurrentInstruction();
  }

  Future<void> _requestEndSession() async {
    final orchestrator = _orchestrator;
    final writer = _checkpointWriter;
    if (_endRequestInFlight ||
        orchestrator?.state.stage == TrainingSessionStage.completed) {
      return;
    }

    final wasPaused = orchestrator?.state.isPaused ?? true;
    if (orchestrator != null && !orchestrator.state.isTerminal && !wasPaused) {
      _pause();
    }
    final pausedForDialog =
        !wasPaused && (orchestrator?.state.isPaused ?? false);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.trainingAbortTitle),
        content: Text(l10n.trainingAbortBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.trainingAbortStay),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trainingAbortConfirm),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true) {
      if (pausedForDialog) _resume();
      return;
    }

    setState(() => _endRequestInFlight = true);
    try {
      await writer?.flush();
      final checkpointStore = _checkpointStore ??
          TrainingSessionCheckpointStore(
            await SharedPreferences.getInstance(),
          );
      await checkpointStore.clear(
        profileId: widget.profileId,
        packageId: widget.packageId,
        contentVersion: widget.contentVersion,
      );
      if (orchestrator != null && !orchestrator.state.isTerminal) {
        orchestrator.cancel();
      }
      widget.onCancelled();
    } on Object {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.trainingContentUnavailableBody)),
        );
      }
    } finally {
      if (mounted) setState(() => _endRequestInFlight = false);
    }
  }

  Future<void> _changeTempo(double delta) async {
    final orchestrator = _orchestrator;
    final prefs = _prefs;
    if (orchestrator == null || prefs == null) return;
    final exercise = orchestrator.currentExercise;
    final next = (orchestrator.tempoSecondsFor(exercise.id) + delta).clamp(
      orchestrator.minTempoSecondsFor(exercise.id),
      orchestrator.maxTempoSecondsFor(exercise.id),
    );
    orchestrator.setTempoSeconds(exercise.id, next);
    await AdaptiveTempoSettings.saveScopedTempo(
      prefs: prefs,
      profileId: widget.profileId,
      packageId: widget.packageId,
      contentVersion: widget.contentVersion,
      exerciseId: exercise.id,
      exerciseNumber: exercise.sequenceNumber,
      tempoSeconds: next,
    );
    if (_feedbackMode.policy.allowsHaptics) {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> _cycleFeedbackMode() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final next = switch (_feedbackMode) {
      TrainingFeedbackMode.voiceAndCues => TrainingFeedbackMode.hapticOnly,
      TrainingFeedbackMode.hapticOnly => TrainingFeedbackMode.silent,
      TrainingFeedbackMode.silent => TrainingFeedbackMode.voiceAndCues,
    };
    await TrainingFeedbackSettings.setFeedbackMode(prefs, next);
    if (!next.policy.allowsVoice) {
      _stopAnnouncements();
    }
    if (!next.policy.allowsTones) {
      await _rhythmCuePlayer?.stop();
    }
    if (!next.policy.allowsMusic) {
      await InAppMusicService.instance.stop();
    }
    _feedbackMode = next;
    if (mounted) setState(() {});
    if (next.policy.allowsHaptics) {
      await HapticFeedback.selectionClick();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _pause(reason: TrainingPauseReason.lifecycle);
        unawaited(InAppMusicService.instance.stop());
        return;
      case AppLifecycleState.resumed:
        _lastClockReading = _monotonicClock.elapsed;
        return;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _monotonicClock.stop();
    _stateSubscription?.cancel();
    _signalSubscription?.cancel();
    _audioInterruptionSubscription?.cancel();
    _stopAnnouncements();
    unawaited(_rhythmCuePlayer?.dispose() ?? Future.value());
    unawaited(_orchestrator?.dispose() ?? Future.value());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestEndSession());
      },
      child: _buildSessionContent(context),
    );
  }

  Widget _buildSessionContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_initializationError != null) {
      return _messageScreen(
        icon: Icons.error_outline,
        title: l10n.trainingContentUnavailableTitle,
        body: l10n.trainingContentUnavailableBody,
        action: TextButton.icon(
          onPressed: () => unawaited(_requestEndSession()),
          icon: const Icon(Icons.close_rounded),
          label: Text(l10n.trainingExitTooltip),
        ),
      );
    }
    final state = _state;
    final orchestrator = _orchestrator;
    if (state == null || orchestrator == null) {
      return const ColoredBox(
        color: AppColors.backgroundDark,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.stage == TrainingSessionStage.completed) {
      return _completionScreen(state);
    }
    if (state.stage == TrainingSessionStage.cancelled ||
        state.stage == TrainingSessionStage.failure) {
      return _messageScreen(
        icon: Icons.error_outline,
        title: l10n.trainingContentUnavailableTitle,
        body: state.failureMessage ?? l10n.trainingContentUnavailableBody,
        action: TextButton.icon(
          onPressed: () => unawaited(_requestEndSession()),
          icon: const Icon(Icons.close_rounded),
          label: Text(l10n.trainingExitTooltip),
        ),
      );
    }

    final effectiveStage = state.isPaused ? state.resumeStage : state.stage;
    Widget child;
    if (effectiveStage == TrainingSessionStage.exerciseAnnouncement ||
        effectiveStage == TrainingSessionStage.preparation) {
      child = ExerciseTransitionWidget(
        exercise: orchestrator.currentExercise,
        exerciseIndex: state.exerciseIndex,
        totalExercises: orchestrator.exercises.length,
        isRoutineMode: _isRoutineMode,
        locale: Localizations.localeOf(context).languageCode,
        isDuo: _isDuo,
        stage: effectiveStage!,
        remainingSeconds:
            (state.remaining.inMilliseconds / 1000).ceil().clamp(0, 999),
        voiceGuidanceAvailable: _voiceGuidanceAvailable,
        compactGuidance: !_isRoutineMode && widget.completedSessions == 1,
        onConfirmReady: orchestrator.confirmReady,
        onStartNow: orchestrator.startNow,
        onRepeatInstruction: () => unawaited(_repeatCurrentGuidance()),
        onEndSession: () => unawaited(_requestEndSession()),
      );
    } else if (effectiveStage == TrainingSessionStage.exerciseTransition) {
      child = _betweenExercises(state, orchestrator);
    } else {
      child = ImmersiveExerciseScreen(
        exercise: orchestrator.currentExercise,
        exerciseIndex: state.exerciseIndex,
        totalExercises: orchestrator.exercises.length,
        isRoutineMode: _isRoutineMode,
        state: state,
        sessionProgress: orchestrator.sessionProgress,
        currentBeat: orchestrator.currentBeat,
        beatsInCurrentStep: orchestrator.beatsInCurrentStep,
        tempoSeconds:
            orchestrator.tempoSecondsFor(orchestrator.currentExercise.id),
        feedbackMode: _feedbackMode,
        reducedMotion: MediaQuery.disableAnimationsOf(context),
        onPause: _pause,
        onResume: _resume,
        onSlower: () => unawaited(_changeTempo(0.5)),
        onFaster: () => unawaited(_changeTempo(-0.5)),
        onCycleFeedback: () => unawaited(_cycleFeedbackMode()),
        onRepeatInstruction: () => unawaited(_repeatCurrentGuidance()),
        onEndSession: () => unawaited(_requestEndSession()),
      );
    }

    if (state.isPaused &&
        effectiveStage != TrainingSessionStage.activeMovement &&
        effectiveStage != TrainingSessionStage.recovery) {
      return Stack(
        children: [
          child,
          Positioned.fill(child: _interruptionOverlay()),
        ],
      );
    }
    return child;
  }

  Widget _betweenExercises(
    TrainingSessionState state,
    SessionOrchestrator orchestrator,
  ) {
    final l10n = AppLocalizations.of(context);
    final nextIndex =
        (state.exerciseIndex + 1).clamp(0, orchestrator.exercises.length - 1);
    final seconds =
        (state.remaining.inMilliseconds / 1000).ceil().clamp(0, 999);
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.success,
                    size: 72,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.trainingShortBreak,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${l10n.trainingNextExercise} '
                    '${orchestrator.exercises[nextIndex].title(Localizations.localeOf(context).languageCode)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.trainingTimeRemaining(seconds),
                    style: const TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton.icon(
                    onPressed: () => unawaited(_requestEndSession()),
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.trainingExitTooltip),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.error,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _interruptionOverlay() {
    final l10n = AppLocalizations.of(context);
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.pause_circle_outline_rounded,
                    color: AppColors.warning,
                    size: 72,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    l10n.trainingInterruptedTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.trainingInterruptedBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 17,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _resume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(l10n.trainingResume),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _completionScreen(TrainingSessionState state) {
    final l10n = AppLocalizations.of(context);
    return _messageScreen(
      icon: _completionError == null
          ? Icons.cloud_upload_outlined
          : Icons.cloud_off_outlined,
      title: _completionError == null
          ? l10n.trainingCompletionSaving
          : l10n.trainingCompletionSaveFailed,
      body: _completionError ??
          l10n.trainingCompletedExerciseCount(
            state.completedExerciseIds.length,
          ),
      action: _completionError == null
          ? null
          : FilledButton.icon(
              onPressed: _completionInFlight
                  ? null
                  : () => unawaited(_persistCompletedState(state)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.retry),
            ),
    );
  }

  Widget _messageScreen({
    required IconData icon,
    required String title,
    required String body,
    Widget? action,
  }) {
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: AppColors.primaryLight, size: 72),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        height: 1.45,
                      ),
                    ),
                    if (action != null) ...[
                      const SizedBox(height: 22),
                      action,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _stopAnnouncements() {
    _announcementAttempt++;
    _announcementInFlight = false;
    _audioGeneration = AudioAnnouncementService.instance.startGeneration();
  }
}

Set<String> _requiredAnnouncementIds(
  List<Exercise> exercises, {
  required bool isDuo,
}) {
  final ids = <String>{
    'session.pause',
    'session.resume',
    'session.complete',
    'session.safety',
    'session.countdown.3',
    'session.countdown.2',
    'session.countdown.1',
    'exercise.repetition.complete',
    'exercise.switch_side',
    'exercise.rest',
  };
  for (final exercise in exercises) {
    ids
      ..add('exercise.${exercise.id}.name')
      ..add(
        'exercise.${exercise.id}.position.${isDuo ? 'duo' : 'solo'}',
      );
    for (var index = 0; index < exercise.phases.length; index++) {
      ids.add('exercise.${exercise.id}.phase.${index + 1}');
    }
    if (exercise.rhythmType == RhythmType.holdRest) {
      ids.add('exercise.${exercise.id}.phase.1');
    }
  }
  return ids;
}
