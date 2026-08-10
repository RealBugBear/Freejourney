import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';
import '../../domain/services/training_content_resolver.dart';

// Which screen to show in the training flow
enum TrainingFlowStep {
  disclaimer, // first-ever session only
  intro, // session title + day + mode
  video, // tutorial only
  position, // tutorial only
  preparation, // tutorial only
  movement, // all modes — the actual exercise timer
  rest, // brief rest between exercises
  outro, // completion screen
}

class TrainingFlowState {
  final String packageId;
  final String? contentVersion;
  final TrainingContentSource contentSource;
  final TrainingContentIssue? contentIssue;
  final List<TrainingContentValidationIssue> contentValidationIssues;
  final bool isCachePending;
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final TrainingFlowStep step;
  final TrainingSessionMode mode;
  final bool showDisclaimer;
  final List<String> completedExerciseIds;
  final bool isComplete;

  const TrainingFlowState({
    required this.packageId,
    required this.contentVersion,
    required this.contentSource,
    required this.exercises,
    this.contentIssue,
    this.contentValidationIssues = const [],
    this.isCachePending = false,
    this.currentExerciseIndex = 0,
    this.step = TrainingFlowStep.intro,
    this.mode = TrainingSessionMode.tutorial,
    this.showDisclaimer = false,
    this.completedExerciseIds = const [],
    this.isComplete = false,
  });

  bool get hasContent => exercises.isNotEmpty;
  Exercise? get currentExerciseOrNull {
    if (!hasContent ||
        currentExerciseIndex < 0 ||
        currentExerciseIndex >= exercises.length) {
      return null;
    }
    return exercises[currentExerciseIndex];
  }

  Exercise get currentExercise =>
      currentExerciseOrNull ??
      (throw StateError(
        contentIssue?.message ?? 'No current training exercise is available.',
      ));
  bool get isLastExercise =>
      hasContent && currentExerciseIndex >= exercises.length - 1;
  int get totalExercises => exercises.length;
  double get progressFraction =>
      exercises.isEmpty ? 0 : currentExerciseIndex / exercises.length;

  TrainingFlowState copyWith({
    String? packageId,
    String? contentVersion,
    TrainingContentSource? contentSource,
    TrainingContentIssue? contentIssue,
    bool clearContentIssue = false,
    List<TrainingContentValidationIssue>? contentValidationIssues,
    bool? isCachePending,
    List<Exercise>? exercises,
    int? currentExerciseIndex,
    TrainingFlowStep? step,
    TrainingSessionMode? mode,
    bool? showDisclaimer,
    List<String>? completedExerciseIds,
    bool? isComplete,
  }) {
    return TrainingFlowState(
      packageId: packageId ?? this.packageId,
      contentVersion: contentVersion ?? this.contentVersion,
      contentSource: contentSource ?? this.contentSource,
      contentIssue:
          clearContentIssue ? null : contentIssue ?? this.contentIssue,
      contentValidationIssues:
          contentValidationIssues ?? this.contentValidationIssues,
      isCachePending: isCachePending ?? this.isCachePending,
      exercises: exercises ?? this.exercises,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      step: step ?? this.step,
      mode: mode ?? this.mode,
      showDisclaimer: showDisclaimer ?? this.showDisclaimer,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

class TrainingFlowNotifier extends StateNotifier<TrainingFlowState> {
  TrainingFlowNotifier({
    required List<Exercise> exercises,
    required TrainingSessionMode mode,
    required bool requiresDisclaimer,
    String? packageId,
    String? contentVersion,
    TrainingContentSource contentSource = TrainingContentSource.bundledSnapshot,
    TrainingContentIssue? contentIssue,
    List<TrainingContentValidationIssue> contentValidationIssues = const [],
    bool isCachePending = false,
  }) : super(TrainingFlowState(
          packageId:
              packageId ?? (exercises.isEmpty ? '' : exercises.first.packageId),
          contentVersion: contentVersion,
          contentSource: contentSource,
          contentIssue: contentIssue,
          contentValidationIssues: contentValidationIssues,
          isCachePending: isCachePending,
          exercises: exercises,
          mode: mode,
          showDisclaimer: requiresDisclaimer,
          step: requiresDisclaimer
              ? TrainingFlowStep.disclaimer
              : TrainingFlowStep.intro,
        ));

  factory TrainingFlowNotifier.fromResolution({
    required TrainingContentResolution resolution,
    required TrainingSessionMode mode,
    required bool requiresDisclaimer,
  }) {
    return TrainingFlowNotifier(
      packageId: resolution.packageId,
      contentVersion: resolution.version,
      contentSource: resolution.source,
      contentIssue: resolution.issue,
      contentValidationIssues: resolution.validationIssues,
      isCachePending: resolution.isCachePending,
      exercises: resolution.exercises,
      mode: mode,
      requiresDisclaimer: requiresDisclaimer,
    );
  }

  /// Applies cache content only before the user starts the flow.
  ///
  /// Once a session has entered video or movement guidance, its exercise list
  /// is immutable. A later cache read must not reset or reorder active work.
  void applyContentResolution(TrainingContentResolution resolution) {
    final isAtSafeBoundary = state.currentExerciseIndex == 0 &&
        state.completedExerciseIds.isEmpty &&
        !state.isComplete &&
        (state.step == TrainingFlowStep.disclaimer ||
            state.step == TrainingFlowStep.intro);
    if (!isAtSafeBoundary) return;

    state = state.copyWith(
      packageId: resolution.packageId,
      contentVersion: resolution.version,
      contentSource: resolution.source,
      contentIssue: resolution.issue,
      clearContentIssue: resolution.issue == null,
      contentValidationIssues: resolution.validationIssues,
      isCachePending: resolution.isCachePending,
      exercises: resolution.exercises,
      currentExerciseIndex: 0,
    );
  }

  void acceptDisclaimer() {
    state = state.copyWith(
      showDisclaimer: false,
      step: TrainingFlowStep.intro,
    );
  }

  void startSession() {
    if (!state.hasContent) return;
    state = state.copyWith(
      step: state.mode == TrainingSessionMode.tutorial
          ? TrainingFlowStep.video
          : TrainingFlowStep.movement,
    );
  }

  void videoReady() {
    if (!state.hasContent) return;
    state = state.copyWith(step: TrainingFlowStep.position);
  }

  void positionReady() {
    if (!state.hasContent) return;
    state = state.copyWith(step: TrainingFlowStep.preparation);
  }

  void preparationReady() {
    if (!state.hasContent) return;
    state = state.copyWith(step: TrainingFlowStep.movement);
  }

  void exerciseComplete() {
    if (!state.hasContent) return;
    final completed = [
      ...state.completedExerciseIds,
      state.currentExercise.id,
    ];

    if (state.isLastExercise) {
      state = state.copyWith(
        completedExerciseIds: completed,
        step: TrainingFlowStep.outro,
        isComplete: true,
      );
    } else {
      state = state.copyWith(
        completedExerciseIds: completed,
        currentExerciseIndex: state.currentExerciseIndex + 1,
        step: TrainingFlowStep.rest,
      );
    }
  }

  void restComplete() {
    if (!state.hasContent) return;
    state = state.copyWith(
      step: state.mode == TrainingSessionMode.tutorial
          ? TrainingFlowStep.video
          : TrainingFlowStep.movement,
    );
  }

  void setMode(TrainingSessionMode mode) {
    state = state.copyWith(mode: mode);
  }
}

// ── Exercise loading ──────────────────────────────────────────────────────────
//
// Drift rows are treated as an optional cache. TrainingContentResolver validates
// them against the released package contract and keeps the versioned bundled
// snapshot available for a stable offline start.

/// Loads exercises for [packageId] from the local Drift cache.
final _dbExercisesProvider = FutureProvider.autoDispose
    .family<List<Exercise>, String>((ref, packageId) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.exercisesTable)
        ..where((t) => t.packageId.equals(packageId))
        ..orderBy([(t) => OrderingTerm.asc(t.sequenceNumber)]))
      .get();

  return rows
      .map((row) => Exercise.fromRow({
            'id': row.id,
            'package_id': row.packageId,
            'sequence_number': row.sequenceNumber,
            'title_de': row.titleDe,
            'title_en': row.titleEn,
            'position_instructions_de': row.positionInstructionsDe,
            'position_instructions_en': row.positionInstructionsEn,
            'movement_instructions_de': row.movementInstructionsDe,
            'movement_instructions_en': row.movementInstructionsEn,
            'hints_de': row.hintsDe,
            'hints_en': row.hintsEn,
            'execution_guide_de': row.executionGuideDe,
            'execution_guide_en': row.executionGuideEn,
            'duration_seconds': row.durationSeconds,
            'repetitions': row.repetitions,
            'image_path': row.imagePath,
            'duo_image_path': row.duoImagePath,
            'image_url': row.imageUrl,
            'duo_image_url': row.duoImageUrl,
            'video_url': row.videoUrl,
            'video_path': row.videoPath,
            'audio_cue_path': row.audioCuePath,
            'rhythm_type': row.rhythmType,
            'phases_json': row.phasesJson,
            'has_rep_switch': row.hasRepSwitch,
            'hold_cue_de': row.holdCueDe,
            'hold_cue_en': row.holdCueEn,
            'hold_seconds': row.holdSeconds,
            'rest_seconds': row.restSeconds,
            'halfway_switch': row.halfwaySwitch,
          }))
      .toList();
});

final trainingFlowProvider = StateNotifierProvider.autoDispose
    .family<TrainingFlowNotifier, TrainingFlowState, String>((ref, packageId) {
  const resolver = TrainingContentResolver();
  final initialResolution = resolver.resolve(
    packageId: packageId,
    cacheLoading: true,
  );
  final defaultMode = ref.read(settingsProvider).trainingMode;
  final notifier = TrainingFlowNotifier.fromResolution(
    resolution: initialResolution,
    mode: defaultMode,
    requiresDisclaimer: false, // TODO: check progress entry
  );

  ref.listen(
    _dbExercisesProvider(packageId),
    (_, next) {
      final resolution = next.when(
        data: (exercises) => resolver.resolve(
          packageId: packageId,
          cachedExercises: exercises,
        ),
        error: (error, _) => resolver.resolve(
          packageId: packageId,
          cacheError: error,
        ),
        loading: () => resolver.resolve(
          packageId: packageId,
          cacheLoading: true,
        ),
      );
      notifier.applyContentResolution(resolution);
    },
    fireImmediately: true,
  );

  return notifier;
});
