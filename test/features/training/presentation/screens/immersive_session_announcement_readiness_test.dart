import 'dart:io';

import 'package:corejourney/core/training/training_announcement_manifest.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/services/rhythm_cue_player.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:corejourney/features/training/presentation/screens/immersive_session_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/asset_bundles.dart';
import '../../../../support/noop_audioplayers_platform.dart';

/// Mirrors the noop backend used by the sibling completion test: the real
/// player probes assets, which is exactly the channel these tests must avoid.
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

Widget _screen({required AssetBundle bundle}) => MaterialApp(
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
        restoredState: _runningState(),
        announcementAssetBundle: bundle,
        rhythmCuePlayerFactory: () => RhythmCuePlayer.forTesting(
          assetProbe: (_) async => true,
          audioBackend: _NoopRhythmCueAudioBackend(),
        ),
        persistCompletion: (_) async {},
        onCompleted: (_) {},
        onCancelled: () {},
      ),
    );

/// Waits on wall-clock time rather than a pump count: the readiness timeout
/// runs on real time inside [WidgetTester.runAsync], so a fixed number of
/// pumps would be a hidden coupling to that timeout's value.
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() predicate, {
  Duration limit = const Duration(seconds: 8),
}) async {
  final elapsed = Stopwatch()..start();
  while (elapsed.elapsed < limit) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(const Duration(milliseconds: 20));
    if (predicate()) return;
  }
  fail('Condition was not reached within ${limit.inSeconds}s.');
}

void main() {
  setUpAll(installNoopAudioplayersPlatform);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('reads the announcement manifest from the injected bundle',
      (tester) async {
    expect(
      File(TrainingAnnouncementManifest.bundledAssetPath).existsSync(),
      isTrue,
      reason: 'fixture relies on the real bundled manifest',
    );

    await tester.pumpWidget(_screen(bundle: DiskAssetBundle()));

    await _pumpUntil(tester, () => find.text('Resume').evaluate().isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('renders the session when the announcement asset never responds',
      (tester) async {
    await tester.pumpWidget(_screen(bundle: StalledAssetBundle()));

    await _pumpUntil(tester, () => find.text('Resume').evaluate().isNotEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
