import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:corejourney/features/training/presentation/screens/training_outro_screen.dart';
import 'package:corejourney/features/training/presentation/screens/vorrunde_interstitial_screen.dart';
import 'package:corejourney/features/training/presentation/widgets/exercise_transition_widget.dart';
import 'package:corejourney/features/training/presentation/widgets/music_picker_sheet.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Exercise _exercise() => const Exercise(
      id: 'test_exercise',
      packageId: 'moro',
      sequenceNumber: 1,
      titleDe: 'Testübung',
      titleEn: 'Test Exercise',
      positionInstructionsDe: ['Lege dich bequem hin.'],
      positionInstructionsEn: ['Lie down comfortably.'],
      movementInstructionsDe: ['Bewege dich langsam.'],
      movementInstructionsEn: ['Move slowly.'],
      executionGuideDe: 'Deutsche Anleitung',
      executionGuideEn: 'English guide',
      durationSeconds: 30,
      repetitions: 3,
      imagePath:
          'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_1.png',
    );

Widget _wrap(Widget child, {String locale = 'en'}) => MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Material(child: child),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('completion screen renders English session copy', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      _wrap(TrainingOutroScreen(onFinish: () => finished = true)),
    );
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.text("You've successfully completed\ntoday's training."),
        findsOneWidget);
    expect(find.text('Completed Today'), findsOneWidget);
    expect(find.text('Exercises'), findsOneWidget);
    expect(find.text('Minutes'), findsOneWidget);
    expect(find.text('Back to Dashboard'), findsOneWidget);
    expect(find.text('Herzlichen Glückwunsch!'), findsNothing);

    await tester.tap(find.text('Back to Dashboard'));
    expect(finished, isTrue);
  });

  testWidgets('completion screen keeps the original German copy',
      (tester) async {
    await tester.pumpWidget(
      _wrap(TrainingOutroScreen(onFinish: () {}), locale: 'de'),
    );
    await tester.pump(const Duration(milliseconds: 1300));

    expect(find.text('Herzlichen Glückwunsch!'), findsOneWidget);
    expect(
      find.text(
        'Du hast dein heutiges Training\nerfolgreich abgeschlossen.',
      ),
      findsOneWidget,
    );
    expect(find.text('Heute abgeschlossen'), findsOneWidget);
    expect(find.text('Übungen'), findsOneWidget);
    expect(find.text('Minuten'), findsOneWidget);
    expect(find.text('Zum Dashboard'), findsOneWidget);
  });

  testWidgets('warm-up interstitial switches between English and German',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        VorrundeInterstitialScreen(
          onStartVorrunde: () {},
          onSkip: () {},
        ),
      ),
    );

    expect(find.text('Before You Start'), findsOneWidget);
    expect(find.text('Warm-Up Round'), findsOneWidget);
    expect(find.text('Start the Warm-Up Now'), findsOneWidget);
    expect(find.text('recommended'), findsOneWidget);
    expect(find.text('Start the First Package Directly'), findsOneWidget);

    await tester.pumpWidget(
      _wrap(
        VorrundeInterstitialScreen(
          onStartVorrunde: () {},
          onSkip: () {},
        ),
        locale: 'de',
      ),
    );
    await tester.pump();

    expect(find.text('Bevor du startest'), findsOneWidget);
    expect(find.text('Vorrunde'), findsOneWidget);
    expect(find.text('Vorrunde jetzt starten'), findsOneWidget);
    expect(find.text('empfohlen'), findsOneWidget);
    expect(find.text('Direkt mit erstem Paket starten'), findsOneWidget);
  });

  testWidgets('exercise transition localizes English training chrome',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        ExerciseTransitionWidget(
          exercise: _exercise(),
          exerciseIndex: 0,
          totalExercises: 7,
          isRoutineMode: false,
          locale: 'en',
          isDuo: false,
          stage: TrainingSessionStage.exerciseAnnouncement,
          remainingSeconds: 0,
          voiceGuidanceAvailable: false,
          onConfirmReady: () {},
          onStartNow: () {},
          onRepeatInstruction: () {},
        ),
      ),
    );

    expect(find.text('Exercise 1 of 7'), findsOneWidget);
    expect(find.text('3× reps'), findsOneWidget);
    expect(find.text('7 sec / rep'), findsOneWidget);
    expect(find.text('Position'), findsOneWidget);
    expect(find.text('Movement'), findsOneWidget);
    expect(find.text('Start Exercise'), findsOneWidget);
    expect(find.text('Übung 1 von 7'), findsNothing);
  });

  testWidgets('music picker localizes track and control labels',
      (tester) async {
    await tester.pumpWidget(
      _wrap(MusicPickerSheet(onMusicActiveChanged: (_) {})),
    );
    await tester.pump();

    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Off'), findsOneWidget);
    expect(find.text('Ambient Flow'), findsNothing);
    expect(
      find.text(
        'No verified in-app music tracks are available in this release yet.',
      ),
      findsOneWidget,
    );
    expect(find.text('Stille Natur'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        MusicPickerSheet(onMusicActiveChanged: (_) {}),
        locale: 'de',
      ),
    );
    await tester.pump();

    expect(find.text('Musik'), findsOneWidget);
    expect(find.text('Aus'), findsOneWidget);
    expect(find.text('Stille Natur'), findsNothing);
    expect(
      find.text(
        'Für diese Version sind noch keine geprüften internen Musiktitel '
        'verfügbar.',
      ),
      findsOneWidget,
    );
  });
}
