import 'dart:async';

import 'package:corejourney/core/training/training_familiarity_settings.dart';
import 'package:corejourney/core/training/training_feedback_settings.dart';
import 'package:corejourney/core/training/training_session_checkpoint_store.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/services/rhythm_cue_player.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:corejourney/features/training/presentation/screens/immersive_session_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/noop_audioplayers_platform.dart';

const _exercise = Exercise(
  id: 'exercise-1',
  packageId: 'moro',
  sequenceNumber: 1,
  titleDe: 'Übung',
  titleEn: 'Exercise',
  positionInstructionsDe: [],
  positionInstructionsEn: [],
  movementInstructionsDe: [],
  movementInstructionsEn: [],
  executionGuideDe: '',
  executionGuideEn: '',
  durationSeconds: 1,
  repetitions: 1,
  imagePath: '',
);

TrainingSessionState _completedState() {
  return const TrainingSessionState(
    sessionId: 'session-1',
    packageId: 'moro',
    contentVersion: 'v1',
    mode: TrainingSessionMode.routine,
    stage: TrainingSessionStage.completed,
    exerciseIndex: 0,
    repetitionIndex: 0,
    phaseIndex: 0,
    stepElapsed: Duration.zero,
    stepDuration: Duration.zero,
    completedExerciseIds: ['exercise-1'],
  );
}

TrainingSessionState _almostCompletedState() {
  return const TrainingSessionState(
    sessionId: 'session-1',
    packageId: 'moro',
    contentVersion: 'v1',
    mode: TrainingSessionMode.routine,
    stage: TrainingSessionStage.activeMovement,
    exerciseIndex: 0,
    repetitionIndex: 0,
    phaseIndex: 0,
    stepElapsed: Duration(microseconds: 999999),
    stepDuration: Duration(seconds: 1),
    completedExerciseIds: [],
  );
}

TrainingSessionState _runningState() {
  return const TrainingSessionState(
    sessionId: 'session-1',
    packageId: 'moro',
    contentVersion: 'v1',
    mode: TrainingSessionMode.routine,
    stage: TrainingSessionStage.activeMovement,
    exerciseIndex: 0,
    repetitionIndex: 0,
    phaseIndex: 0,
    stepElapsed: Duration(seconds: 2),
    stepDuration: Duration(seconds: 10),
    completedExerciseIds: [],
  );
}

Widget _screen({
  required TrainingSessionState restoredState,
  required Future<void> Function(TrainingSessionState state) persistCompletion,
  required ValueChanged<TrainingSessionState> onCompleted,
  VoidCallback? onCancelled,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ImmersiveSessionScreen(
      exercises: const [_exercise],
      mode: TrainingSessionMode.routine,
      packageId: 'moro',
      contentVersion: 'v1',
      sessionId: 'session-1',
      profileId: 'profile-1',
      completedSessions: 0,
      restoredState: restoredState,
      rhythmCuePlayerFactory: () => RhythmCuePlayer.forTesting(
        assetProbe: (_) async => true,
        audioBackend: _NoopRhythmCueAudioBackend(),
      ),
      persistCompletion: persistCompletion,
      onCompleted: onCompleted,
      onCancelled: onCancelled ?? () {},
    ),
  );
}

class _NoopRhythmCueAudioBackend implements RhythmCueAudioBackend {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> playAsset(String assetKey) async {}

  @override
  Future<void> stop() async {}
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  String Function()? diagnostic,
}) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (predicate()) return;
  }
  fail(
    'Condition was not reached before the widget-test deadline.'
    '${diagnostic == null ? '' : ' ${diagnostic()}'}',
  );
}

void main() {
  setUpAll(installNoopAudioplayersPlatform);

  setUp(() {
    SharedPreferences.setMockInitialValues({
      TrainingFeedbackSettings.trainingFeedbackModeKey:
          TrainingFeedbackMode.silent.name,
    });
  });

  testWidgets(
      'completion retry preserves checkpoint and is delivered idempotently',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final checkpointStore = TrainingSessionCheckpointStore(prefs);
    final state = _completedState();
    var persistCalls = 0;
    var deliveryCalls = 0;

    await tester.pumpWidget(
      _screen(
        restoredState: state,
        persistCompletion: (completedState) async {
          persistCalls++;
          expect(completedState.sessionId, state.sessionId);
          expect(
            checkpointStore
                .load(
                  profileId: 'profile-1',
                  packageId: 'moro',
                  contentVersion: 'v1',
                )
                ?.stage,
            TrainingSessionStage.completed,
          );
          await TrainingFamiliaritySettings.recordCompletion(
            prefs,
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
            sessionId: state.sessionId,
          );
          if (persistCalls == 1) {
            throw StateError('failure after familiarity persistence');
          }
        },
        onCompleted: (_) => deliveryCalls++,
      ),
    );

    await _pumpUntil(
      tester,
      () => find.text('Retry').evaluate().isNotEmpty,
      diagnostic: () {
        final text = tester
            .widgetList<Text>(find.byType(Text))
            .map((widget) => widget.data)
            .whereType<String>()
            .join(' | ');
        return 'persistCalls=$persistCalls, deliveryCalls=$deliveryCalls, '
            'text=$text';
      },
    );

    expect(persistCalls, 1);
    expect(deliveryCalls, 0);
    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-1',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
    expect(
      checkpointStore
          .load(
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
          )
          ?.stage,
      TrainingSessionStage.completed,
    );

    await tester.tap(find.text('Retry'));
    await tester.tap(find.text('Retry'));
    await _pumpUntil(tester, () => deliveryCalls == 1);

    expect(persistCalls, 2);
    expect(deliveryCalls, 1);
    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-1',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
    expect(
      checkpointStore.load(
        profileId: 'profile-1',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'final timeline tick persists and delivers exactly once during lifecycle churn',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final checkpointStore = TrainingSessionCheckpointStore(prefs);
    final persistGate = Completer<void>();
    var persistCalls = 0;
    var deliveryCalls = 0;

    await tester.pumpWidget(
      _screen(
        restoredState: _almostCompletedState(),
        persistCompletion: (_) {
          persistCalls++;
          return persistGate.future;
        },
        onCompleted: (_) => deliveryCalls++,
      ),
    );

    await _pumpUntil(
      tester,
      () => find.text('Resume').evaluate().isNotEmpty,
      diagnostic: () => tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .join(' | '),
    );
    await tester.tap(find.text('Resume'));
    await _pumpUntil(tester, () => persistCalls == 1);

    expect(deliveryCalls, 0);
    expect(
      checkpointStore
          .load(
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
          )
          ?.stage,
      TrainingSessionStage.completed,
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 250));

    expect(persistCalls, 1);
    expect(deliveryCalls, 0);

    persistGate.complete();
    await _pumpUntil(tester, () => deliveryCalls == 1);
    await tester.pump(const Duration(seconds: 1));

    expect(persistCalls, 1);
    expect(deliveryCalls, 1);
    expect(
      checkpointStore.load(
        profileId: 'profile-1',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('abort dialog freezes timeline and stay resumes exact checkpoint',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final checkpointStore = TrainingSessionCheckpointStore(prefs);
    var deliveryCalls = 0;

    await tester.pumpWidget(
      _screen(
        restoredState: _runningState(),
        persistCompletion: (_) async {},
        onCompleted: (_) => fail('The running session must not complete.'),
        onCancelled: () => deliveryCalls++,
      ),
    );

    await _pumpUntil(tester, () => find.text('Resume').evaluate().isNotEmpty);
    await tester.tap(find.text('Resume'));
    await _pumpUntil(
      tester,
      () =>
          checkpointStore
              .load(
                profileId: 'profile-1',
                packageId: 'moro',
                contentVersion: 'v1',
              )
              ?.stage ==
          TrainingSessionStage.activeMovement,
    );

    final exitButton = find.text('Exit Session');
    await tester.ensureVisible(exitButton);
    await tester.tap(exitButton);
    await _pumpUntil(
      tester,
      () => find.text('Exit Session?').evaluate().isNotEmpty,
    );
    await _pumpUntil(
      tester,
      () =>
          checkpointStore
              .load(
                profileId: 'profile-1',
                packageId: 'moro',
                contentVersion: 'v1',
              )
              ?.isPaused ==
          true,
    );

    final pausedCheckpoint = checkpointStore.load(
      profileId: 'profile-1',
      packageId: 'moro',
      contentVersion: 'v1',
    )!;
    expect(pausedCheckpoint.pauseReason, TrainingPauseReason.user);
    expect(
      pausedCheckpoint.resumeStage,
      TrainingSessionStage.activeMovement,
    );

    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      checkpointStore
          .load(
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
          )!
          .toJson(),
      pausedCheckpoint.toJson(),
    );

    await tester.tap(find.text('Keep Training'));
    await _pumpUntil(
      tester,
      () =>
          checkpointStore
              .load(
                profileId: 'profile-1',
                packageId: 'moro',
                contentVersion: 'v1',
              )
              ?.stage ==
          TrainingSessionStage.activeMovement,
    );

    final resumedCheckpoint = checkpointStore.load(
      profileId: 'profile-1',
      packageId: 'moro',
      contentVersion: 'v1',
    )!;
    expect(resumedCheckpoint.stepElapsed, pausedCheckpoint.stepElapsed);
    expect(resumedCheckpoint.pauseReason, isNull);
    expect(resumedCheckpoint.resumeStage, isNull);
    expect(deliveryCalls, 0);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'confirmed abort clears checkpoint before one delivery under rapid taps',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final checkpointStore = TrainingSessionCheckpointStore(prefs);
    var completionCalls = 0;
    var cancellationCalls = 0;
    TrainingSessionState? checkpointAtCancellation;

    await tester.pumpWidget(
      _screen(
        restoredState: _runningState(),
        persistCompletion: (_) async => completionCalls++,
        onCompleted: (_) => completionCalls++,
        onCancelled: () {
          cancellationCalls++;
          checkpointAtCancellation = checkpointStore.load(
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
          );
        },
      ),
    );

    await _pumpUntil(tester, () => find.text('Resume').evaluate().isNotEmpty);
    await tester.tap(find.text('Resume'));
    await _pumpUntil(
      tester,
      () =>
          checkpointStore.load(
            profileId: 'profile-1',
            packageId: 'moro',
            contentVersion: 'v1',
          ) !=
          null,
    );

    final exitButton = find.text('Exit Session');
    await tester.ensureVisible(exitButton);
    await tester.tap(exitButton);
    await _pumpUntil(
      tester,
      () => find.text('Exit Session?').evaluate().isNotEmpty,
    );

    final confirmButton = find.widgetWithText(FilledButton, 'Exit Session');
    expect(confirmButton, findsOneWidget);
    await tester.tap(confirmButton);
    await tester.tap(confirmButton, warnIfMissed: false);
    await tester.tap(confirmButton, warnIfMissed: false);
    await _pumpUntil(tester, () => cancellationCalls == 1);
    await tester.pump(const Duration(milliseconds: 500));

    expect(cancellationCalls, 1);
    expect(completionCalls, 0);
    expect(checkpointAtCancellation, isNull);
    expect(
      checkpointStore.load(
        profileId: 'profile-1',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      isNull,
    );

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
