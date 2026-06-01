import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../domain/models/exercise.dart';
import '../../domain/models/training_session.dart';

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
  final List<Exercise> exercises;
  final int currentExerciseIndex;
  final TrainingFlowStep step;
  final TrainingSessionMode mode;
  final bool showDisclaimer;
  final List<String> completedExerciseIds;
  final bool isComplete;

  const TrainingFlowState({
    required this.exercises,
    this.currentExerciseIndex = 0,
    this.step = TrainingFlowStep.intro,
    this.mode = TrainingSessionMode.tutorial,
    this.showDisclaimer = false,
    this.completedExerciseIds = const [],
    this.isComplete = false,
  });

  Exercise get currentExercise => exercises[currentExerciseIndex];
  bool get isLastExercise => currentExerciseIndex >= exercises.length - 1;
  int get totalExercises => exercises.length;
  double get progressFraction =>
      exercises.isEmpty ? 0 : currentExerciseIndex / exercises.length;

  TrainingFlowState copyWith({
    int? currentExerciseIndex,
    TrainingFlowStep? step,
    TrainingSessionMode? mode,
    bool? showDisclaimer,
    List<String>? completedExerciseIds,
    bool? isComplete,
  }) {
    return TrainingFlowState(
      exercises: exercises,
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
  }) : super(TrainingFlowState(
          exercises: exercises,
          mode: mode,
          showDisclaimer: requiresDisclaimer,
          step: requiresDisclaimer
              ? TrainingFlowStep.disclaimer
              : TrainingFlowStep.intro,
        ));

  void acceptDisclaimer() {
    state = state.copyWith(
      showDisclaimer: false,
      step: TrainingFlowStep.intro,
    );
  }

  void startSession() {
    state = state.copyWith(
      step: state.mode == TrainingSessionMode.tutorial
          ? TrainingFlowStep.video
          : TrainingFlowStep.movement,
    );
  }

  void videoReady() {
    state = state.copyWith(step: TrainingFlowStep.position);
  }

  void positionReady() {
    state = state.copyWith(step: TrainingFlowStep.preparation);
  }

  void preparationReady() {
    state = state.copyWith(step: TrainingFlowStep.movement);
  }

  void exerciseComplete() {
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
// Exercises are loaded from the local Drift DB cache (populated from Supabase
// by ExercisesSyncService on startup). If the DB cache is empty (first offline
// launch before any sync), falls back to the hardcoded const lists so the app
// remains fully functional without network.

/// Loads exercises for [packageId] from the local Drift cache.
/// Returns null if the cache is empty for that package.
final _dbExercisesProvider = FutureProvider.autoDispose
    .family<List<Exercise>?, String>((ref, packageId) async {
  final db = ref.watch(databaseProvider);
  final rows = await (db.select(db.exercisesTable)
        ..where((t) => t.packageId.equals(packageId))
        ..orderBy([(t) => OrderingTerm.asc(t.sequenceNumber)]))
      .get();

  if (rows.isEmpty) return null; // trigger hardcoded fallback

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

/// Hardcoded fallback — used only when the Drift cache is empty (offline first launch).
List<Exercise> _hardcodedFallback(String packageId) {
  switch (packageId) {
    case 'spinal_galant':
      return spinalGalantExercises;
    case 'tlr':
      return tlrExercises;
    case 'vorrunde':
      return vorrundeExercises;
    case 'moro':
    default:
      return moroExercises;
  }
}

final trainingFlowProvider = StateNotifierProvider.autoDispose
    .family<TrainingFlowNotifier, TrainingFlowState, String>((ref, packageId) {
  // Try DB cache first; use hardcoded fallback if not ready or empty.
  final dbAsync = ref.watch(_dbExercisesProvider(packageId));
  final exercises = dbAsync.valueOrNull ?? _hardcodedFallback(packageId);
  final defaultMode = ref.watch(settingsProvider).trainingMode;

  return TrainingFlowNotifier(
    exercises: exercises,
    mode: defaultMode,
    requiresDisclaimer: false, // TODO: check progress entry
  );
});
