import 'dart:io';

import 'package:corejourney/core/theme/app_colors.dart';
import 'package:corejourney/core/training/training_feedback_settings.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:corejourney/features/training/presentation/screens/immersive_exercise_screen.dart';
import 'package:corejourney/features/training/presentation/widgets/exercise_motion_visualizer.dart';
import 'package:corejourney/features/training/presentation/widgets/exercise_transition_widget.dart';
import 'package:corejourney/features/training/presentation/widgets/training_intro_widget.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _evidenceSurfaceKey = ValueKey('training-evidence-surface');
const _evidenceRoot = '../../../../../docs/evidence/training-moro-20260723';
const _evidenceFontFamily = 'TrainingEvidenceRoboto';
const _portrait = Size(390, 844);
const _landscape = Size(844, 390);

TrainingSessionState _sessionState({
  TrainingSessionMode mode = TrainingSessionMode.tutorial,
  TrainingSessionStage stage = TrainingSessionStage.activeMovement,
  int exerciseIndex = 0,
  int repetitionIndex = 0,
  int phaseIndex = 0,
  Duration elapsed = const Duration(seconds: 1),
  Duration duration = const Duration(seconds: 3),
  bool requiresSideSwitch = false,
  TrainingPauseReason? pauseReason,
  TrainingSessionStage? resumeStage,
}) {
  return TrainingSessionState(
    sessionId: 'responsive-a11y-session',
    packageId: 'moro',
    contentVersion: 'moro-v1',
    mode: mode,
    stage: stage,
    exerciseIndex: exerciseIndex,
    repetitionIndex: repetitionIndex,
    phaseIndex: phaseIndex,
    stepElapsed: elapsed,
    stepDuration: duration,
    completedExerciseIds: moroExercises
        .take(exerciseIndex)
        .map((exercise) => exercise.id)
        .toList(),
    requiresSideSwitch: requiresSideSwitch,
    pauseReason: pauseReason,
    resumeStage: resumeStage,
  );
}

TrainingIntroWidget _intro({
  TrainingSessionMode mode = TrainingSessionMode.tutorial,
  bool routineEnabled = false,
  int? completedSessions = 0,
  String? contentNotice,
  VoidCallback? onStart,
  ValueChanged<TrainingSessionMode>? onModeChanged,
}) {
  return TrainingIntroWidget(
    exercise: moroExercises.first,
    exerciseIndex: 0,
    totalExercises: moroExercises.length,
    mode: mode,
    completedSessions: completedSessions,
    contentNotice: contentNotice,
    routineEnabled: routineEnabled,
    onStart: onStart ?? () {},
    onModeChanged: onModeChanged ?? (_) {},
  );
}

ExerciseTransitionWidget _transition({
  String locale = 'en',
  bool isRoutineMode = false,
  bool compactGuidance = false,
  TrainingSessionStage stage = TrainingSessionStage.exerciseAnnouncement,
  int remainingSeconds = 0,
  bool voiceGuidanceAvailable = true,
  VoidCallback? onConfirmReady,
  VoidCallback? onStartNow,
  VoidCallback? onRepeatInstruction,
  VoidCallback? onEndSession,
}) {
  return ExerciseTransitionWidget(
    exercise: moroExercises.first,
    exerciseIndex: 0,
    totalExercises: moroExercises.length,
    isRoutineMode: isRoutineMode,
    locale: locale,
    isDuo: false,
    stage: stage,
    remainingSeconds: remainingSeconds,
    voiceGuidanceAvailable: voiceGuidanceAvailable,
    compactGuidance: compactGuidance,
    onConfirmReady: onConfirmReady ?? () {},
    onStartNow: onStartNow ?? () {},
    onRepeatInstruction: onRepeatInstruction ?? () {},
    onEndSession: onEndSession,
  );
}

ImmersiveExerciseScreen _immersive({
  Exercise? exercise,
  TrainingSessionState? state,
  bool isRoutineMode = false,
  bool reducedMotion = true,
  TrainingFeedbackMode feedbackMode = TrainingFeedbackMode.hapticOnly,
  VoidCallback? onPause,
  VoidCallback? onResume,
  VoidCallback? onRepeatInstruction,
  VoidCallback? onEndSession,
}) {
  final resolvedExercise = exercise ?? moroExercises.first;
  return ImmersiveExerciseScreen(
    exercise: resolvedExercise,
    exerciseIndex: state?.exerciseIndex ?? 0,
    totalExercises: moroExercises.length,
    isRoutineMode: isRoutineMode,
    state: state ?? _sessionState(),
    sessionProgress: .24,
    currentBeat: 2,
    beatsInCurrentStep: 3,
    tempoSeconds: 1,
    feedbackMode: feedbackMode,
    reducedMotion: reducedMotion,
    onPause: onPause ?? () {},
    onResume: onResume ?? () {},
    onSlower: () {},
    onFaster: () {},
    onCycleFeedback: () {},
    onRepeatInstruction: onRepeatInstruction ?? () {},
    onEndSession: onEndSession ?? () {},
  );
}

Future<void> _pumpSurface(
  WidgetTester tester, {
  required Widget child,
  required Size size,
  required String locale,
  double textScale = 2,
  bool reducedMotion = true,
  String? fontFamily,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
      ),
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
            accessibleNavigation: reducedMotion,
          ),
          child: RepaintBoundary(
            key: _evidenceSurfaceKey,
            child: ColoredBox(
              color: AppColors.backgroundDark,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final images = tester.widgetList<Image>(find.byType(Image)).toList();
  final pendingImages = [
    for (final image in images)
      (provider: image.image, context: tester.element(find.byWidget(image))),
  ];
  await tester.runAsync(() async {
    for (final image in pendingImages) {
      await precacheImage(image.provider, image.context);
    }
  });
  await tester.pumpAndSettle();
}

Future<void> _loadEvidenceFont() async {
  var candidate = File(Platform.resolvedExecutable).parent;
  File? fontFile;
  for (var index = 0; index < 8; index++) {
    final sdkFont = File(
      '${candidate.path}/bin/cache/artifacts/material_fonts/'
      'Roboto-Regular.ttf',
    );
    if (sdkFont.existsSync()) {
      fontFile = sdkFont;
      break;
    }
    candidate = candidate.parent;
  }
  if (fontFile == null) {
    throw StateError(
      'Roboto evidence font was not found in the Flutter SDK above '
      '${Platform.resolvedExecutable}.',
    );
  }
  final bytes = await fontFile.readAsBytes();
  final loader = FontLoader(_evidenceFontFamily)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();

  final iconFontFile = File(
    '${fontFile.parent.path}/MaterialIcons-Regular.otf',
  );
  if (!iconFontFile.existsSync()) {
    throw StateError(
      'Material Icons evidence font was not found at ${iconFontFile.path}.',
    );
  }
  final iconBytes = await iconFontFile.readAsBytes();
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(iconBytes)));
  await iconLoader.load();
}

Future<void> _ensureVisible(
  WidgetTester tester,
  Finder finder,
) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> _scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  required Finder scrollable,
}) async {
  await tester.scrollUntilVisible(
    finder,
    320,
    scrollable: scrollable,
    maxScrolls: 30,
  );
  await tester.pumpAndSettle();
}

Finder _explicitSemanticsLabel(String label, {bool? liveRegion}) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Semantics &&
        widget.properties.label == label &&
        (liveRegion == null || widget.properties.liveRegion == liveRegion),
  );
}

Finder _buttonWithText(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
  );
}

void _expectAtLeast48(WidgetTester tester, Finder finder) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));
}

void _expectNoRenderException(WidgetTester tester) {
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(_loadEvidenceFont);

  group('TrainingIntroWidget responsive and accessible', () {
    testWidgets('DE portrait supports 200% text, reduced motion, and semantics',
        (tester) async {
      var starts = 0;
      TrainingSessionMode? selectedMode;
      final semantics = tester.ensureSemantics();

      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        child: _intro(
          contentNotice: 'Die geprüften Offline-Inhalte sind verfügbar.',
          onStart: () => starts++,
          onModeChanged: (mode) => selectedMode = mode,
        ),
      );

      expect(find.text('Willkommen zu deiner Einheit'), findsOneWidget);
      expect(
        find.text('Erster Durchlauf: in Ruhe kennenlernen'),
        findsOneWidget,
      );
      expect(
        find.text('Nach zwei begleiteten Einheiten'),
        findsOneWidget,
      );
      expect(
        tester
            .widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .every((widget) => widget.duration == Duration.zero),
        isTrue,
      );

      final learningNode = tester.getSemantics(
        find.bySemanticsLabel(
          RegExp(r'^Lernmodus\.'),
        ),
      );
      expect(learningNode.flagsCollection.isButton, isTrue);
      expect(
        learningNode.flagsCollection.isSelected.toBoolOrNull(),
        isTrue,
      );

      final routineNode = tester.getSemantics(
        find.bySemanticsLabel(
          RegExp(r'^Routinemodus\.'),
        ),
      );
      expect(routineNode.flagsCollection.isButton, isTrue);
      expect(
        routineNode.flagsCollection.isEnabled.toBoolOrNull(),
        isFalse,
      );

      await _ensureVisible(tester, find.text('Routinemodus'));
      await tester.tap(find.text('Routinemodus'));
      expect(selectedMode, isNull);

      final startButton = _buttonWithText('Einheit beginnen');
      await _ensureVisible(tester, startButton);
      _expectAtLeast48(tester, startButton);
      await tester.tap(startButton);
      expect(starts, 1);
      _expectNoRenderException(tester);
      semantics.dispose();
    });

    testWidgets('EN landscape uses two columns at 200% text', (tester) async {
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        child: _intro(
          mode: TrainingSessionMode.routine,
          routineEnabled: true,
          completedSessions: 3,
        ),
      );

      final image = find.byKey(const ValueKey('exercise-image-semantics'));
      final title = find.text('Welcome to Your Session');
      expect(
          tester.getTopLeft(image).dx, lessThan(tester.getTopLeft(title).dx));
      expect(find.text('Routine Mode is available'), findsOneWidget);

      final startButton = _buttonWithText('Start Session');
      await _ensureVisible(tester, startButton);
      _expectAtLeast48(tester, startButton);
      _expectNoRenderException(tester);
    });
  });

  group('ExerciseTransitionWidget responsive and accessible', () {
    testWidgets('DE portrait learning state remains operable at 200%',
        (tester) async {
      var confirms = 0;
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        child: _transition(
          locale: 'de',
          onConfirmReady: () => confirms++,
        ),
      );

      expect(find.text('Übung 1 von 7'), findsOneWidget);
      expect(find.text('Orientierung'), findsOneWidget);

      final instructionList = find.byType(Scrollable);
      await _scrollUntilVisible(
        tester,
        find.text('Sicherheit'),
        scrollable: instructionList,
      );
      expect(find.text('Sicherheit'), findsOneWidget);
      final button = _buttonWithText('Übung starten');
      await _scrollUntilVisible(
        tester,
        button,
        scrollable: instructionList,
      );
      _expectAtLeast48(tester, button);
      await tester.tap(button);
      expect(confirms, 1);

      final readyNode = tester.getSemantics(
        find.text('Bereit für die Bewegung?'),
      );
      expect(readyNode.flagsCollection.isHeader, isTrue);
      _expectNoRenderException(tester);
      semantics.dispose();
    });

    testWidgets(
        'EN landscape preparation exposes countdown and honest audio state',
        (tester) async {
      var starts = 0;
      var ends = 0;
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        child: _transition(
          locale: 'en',
          isRoutineMode: true,
          compactGuidance: true,
          stage: TrainingSessionStage.preparation,
          remainingSeconds: 3,
          voiceGuidanceAvailable: false,
          onStartNow: () => starts++,
          onEndSession: () => ends++,
        ),
      );

      final image = find.byKey(const ValueKey('exercise-image-semantics'));
      final title = find.text('Moro 5');
      expect(
          tester.getTopLeft(image).dx, lessThan(tester.getTopLeft(title).dx));

      final instructionList = find.byType(Scrollable);
      await _scrollUntilVisible(
        tester,
        find.text('Voice guidance is not available yet'),
        scrollable: instructionList,
      );
      expect(find.text('Voice guidance is not available yet'), findsOneWidget);
      final startButton = _buttonWithText('Start Now');
      await _scrollUntilVisible(
        tester,
        startButton,
        scrollable: instructionList,
      );
      _expectAtLeast48(tester, startButton);
      expect(
        _explicitSemanticsLabel(
          'Starting in 3 seconds',
          liveRegion: true,
        ),
        findsOneWidget,
      );
      await tester.tap(startButton);
      await tester.pumpAndSettle();
      expect(starts, 1);

      final exitButton = _buttonWithText('Exit Session');
      await _scrollUntilVisible(
        tester,
        exitButton,
        scrollable: instructionList,
      );
      _expectAtLeast48(tester, exitButton);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Exit Session'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      await tester.tap(exitButton);
      await tester.pumpAndSettle();
      expect(ends, 1);
      expect(tester.binding.transientCallbackCount, 0);
      _expectNoRenderException(tester);
      semantics.dispose();
    });
  });

  group('ImmersiveExerciseScreen responsive and accessible', () {
    testWidgets('DE portrait active phase works at 200% with reduced motion',
        (tester) async {
      var pauses = 0;
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        child: _immersive(onPause: () => pauses++),
      );

      expect(find.text('HOCH'), findsOneWidget);
      expect(find.text('Seite 1'), findsOneWidget);
      expect(find.text('Noch 2 Sekunden'), findsOneWidget);
      expect(
        _explicitSemanticsLabel(
          'Hoch. Wiederholung 1 von 3. Noch 2 Sekunden. Seite 1',
          liveRegion: true,
        ),
        findsOneWidget,
      );

      final visualizer = tester.widget<ExerciseMotionVisualizer>(
        find.byType(ExerciseMotionVisualizer),
      );
      expect(visualizer.reducedMotion, isTrue);

      final tempoIndicator = find.text('1.0s / Schlag');
      final slowerButton = _buttonWithText('Langsamer');
      final fasterButton = _buttonWithText('Schneller');
      expect(
        tester.getTopLeft(tempoIndicator).dy,
        lessThan(tester.getTopLeft(slowerButton).dy),
      );
      expect(
        tester.getTopLeft(slowerButton).dy,
        lessThan(tester.getTopLeft(fasterButton).dy),
      );
      expect(tester.getSize(slowerButton).width, greaterThanOrEqualTo(340));
      expect(tester.getSize(fasterButton).width, greaterThanOrEqualTo(340));
      expect(tester.getSize(find.text('Langsamer')).height, lessThan(50));
      expect(tester.getSize(find.text('Schneller')).height, lessThan(50));

      final pauseButton = _buttonWithText('Pause');
      await _ensureVisible(tester, pauseButton);
      _expectAtLeast48(tester, pauseButton);
      await tester.tap(pauseButton);
      await tester.pumpAndSettle();
      expect(pauses, 1);
      expect(tester.binding.transientCallbackCount, 0);
      _expectNoRenderException(tester);
      semantics.dispose();
    });

    testWidgets(
        'DE portrait voluntary controls stack full-width and remain operable at 200%',
        (tester) async {
      var repeats = 0;
      var ends = 0;
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        fontFamily: _evidenceFontFamily,
        child: _immersive(
          onRepeatInstruction: () => repeats++,
          onEndSession: () => ends++,
        ),
      );

      final repeatLabel = find.text('Anleitung wiederholen');
      final exitLabel = find.text('Training abbrechen');
      final repeatButton = _buttonWithText('Anleitung wiederholen');
      final exitButton = _buttonWithText('Training abbrechen');

      expect(repeatLabel, findsOneWidget);
      expect(exitLabel, findsOneWidget);
      expect(
        tester.getTopLeft(repeatButton).dy,
        lessThan(tester.getTopLeft(exitButton).dy),
      );
      expect(tester.getSize(repeatButton).width, greaterThanOrEqualTo(340));
      expect(tester.getSize(exitButton).width, greaterThanOrEqualTo(340));
      expect(tester.getSize(repeatLabel).height, lessThan(50));
      expect(tester.getSize(exitLabel).height, lessThan(50));
      _expectAtLeast48(tester, repeatButton);
      _expectAtLeast48(tester, exitButton);

      final repeatNode = tester.getSemantics(
        find.bySemanticsLabel('Anleitung wiederholen'),
      );
      final exitNode = tester.getSemantics(
        find.bySemanticsLabel('Training abbrechen'),
      );
      expect(repeatNode.flagsCollection.isButton, isTrue);
      expect(exitNode.flagsCollection.isButton, isTrue);

      await _ensureVisible(tester, repeatButton);
      await tester.tap(repeatButton);
      await tester.pumpAndSettle();
      expect(repeats, 1);

      await _ensureVisible(tester, exitButton);
      await tester.tap(exitButton);
      await tester.pumpAndSettle();
      expect(ends, 1);
      _expectNoRenderException(tester);
      semantics.dispose();
    });

    testWidgets('EN landscape paused state remains readable at 200%',
        (tester) async {
      var resumes = 0;
      var ends = 0;
      final paused = _sessionState(
        stage: TrainingSessionStage.paused,
        repetitionIndex: 1,
        pauseReason: TrainingPauseReason.user,
        resumeStage: TrainingSessionStage.activeMovement,
      );
      final semantics = tester.ensureSemantics();
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        fontFamily: _evidenceFontFamily,
        child: _immersive(
          state: paused,
          isRoutineMode: true,
          feedbackMode: TrainingFeedbackMode.silent,
          onResume: () => resumes++,
          onEndSession: () => ends++,
        ),
      );

      expect(find.text('TRAINING PAUSED'), findsOneWidget);
      expect(find.text('Side 2'), findsOneWidget);
      expect(
        find.text(
          'The timer is stopped. Check your position and resume deliberately.',
        ),
        findsOneWidget,
      );
      expect(
        _explicitSemanticsLabel(
          'Training paused. Repetition 2 of 3. 2 seconds remaining. Side 2',
          liveRegion: true,
        ),
        findsOneWidget,
      );

      final visual = find.byType(ExerciseMotionVisualizer);
      final pausedAction = find.text('TRAINING PAUSED');
      expect(
        tester.getCenter(visual).dx,
        closeTo(tester.getCenter(pausedAction).dx, 1),
      );
      expect(
        tester.getTopLeft(visual).dy,
        lessThan(tester.getTopLeft(pausedAction).dy),
      );
      expect(
        tester.getTopLeft(visual).dy,
        lessThan(_landscape.height),
      );

      final resumeButton = _buttonWithText('Resume');
      await _ensureVisible(tester, resumeButton);
      _expectAtLeast48(tester, resumeButton);
      await tester.tap(resumeButton);
      expect(resumes, 1);

      final exitButton = _buttonWithText('Exit Session');
      await _ensureVisible(tester, exitButton);
      _expectAtLeast48(tester, exitButton);
      expect(tester.getSize(exitButton).width, greaterThanOrEqualTo(794));
      expect(tester.getSize(find.text('Exit Session')).height, lessThan(50));
      expect(
        tester.getSemantics(find.bySemanticsLabel('Exit Session'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      await tester.tap(exitButton);
      await tester.pumpAndSettle();
      expect(ends, 1);
      _expectNoRenderException(tester);
      semantics.dispose();
    });

    testWidgets('hold/rest recovery maps to the static pause visualization',
        (tester) async {
      final recoveryState = _sessionState(
        mode: TrainingSessionMode.routine,
        stage: TrainingSessionStage.recovery,
        exerciseIndex: 5,
        repetitionIndex: 2,
        duration: const Duration(seconds: 3),
        requiresSideSwitch: true,
      );
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        child: _immersive(
          exercise: moroExercises[5],
          state: recoveryState,
          isRoutineMode: true,
        ),
      );

      expect(find.text('ARMKREUZ WECHSELN'), findsOneWidget);
      expect(find.text('Armkreuz 1'), findsOneWidget);
      final visualizer = tester.widget<ExerciseMotionVisualizer>(
        find.byType(ExerciseMotionVisualizer),
      );
      expect(visualizer.phaseIndex, 1);
      expect(visualizer.reducedMotion, isTrue);
      _expectNoRenderException(tester);
    });
  });

  group('100% and 150% responsive operability smoke', () {
    final scenarios = <({
      String name,
      String locale,
      Size size,
      double textScale,
      String introStart,
      String transitionStart,
      String repeat,
      String exit,
    })>[
      (
        name: '100% DE portrait',
        locale: 'de',
        size: _portrait,
        textScale: 1,
        introStart: 'Einheit beginnen',
        transitionStart: 'Übung starten',
        repeat: 'Anleitung wiederholen',
        exit: 'Training abbrechen',
      ),
      (
        name: '100% EN landscape',
        locale: 'en',
        size: _landscape,
        textScale: 1,
        introStart: 'Start Session',
        transitionStart: 'Start Exercise',
        repeat: 'Repeat instructions',
        exit: 'Exit Session',
      ),
      (
        name: '150% EN portrait',
        locale: 'en',
        size: _portrait,
        textScale: 1.5,
        introStart: 'Start Session',
        transitionStart: 'Start Exercise',
        repeat: 'Repeat instructions',
        exit: 'Exit Session',
      ),
      (
        name: '150% DE landscape',
        locale: 'de',
        size: _landscape,
        textScale: 1.5,
        introStart: 'Einheit beginnen',
        transitionStart: 'Übung starten',
        repeat: 'Anleitung wiederholen',
        exit: 'Training abbrechen',
      ),
    ];

    for (final scenario in scenarios) {
      testWidgets(scenario.name, (tester) async {
        var introStarts = 0;
        await _pumpSurface(
          tester,
          size: scenario.size,
          locale: scenario.locale,
          textScale: scenario.textScale,
          fontFamily: _evidenceFontFamily,
          child: _intro(
            routineEnabled: true,
            onStart: () => introStarts++,
          ),
        );
        final introButton = _buttonWithText(scenario.introStart);
        await _ensureVisible(tester, introButton);
        _expectAtLeast48(tester, introButton);
        await tester.tap(introButton);
        await tester.pumpAndSettle();
        expect(introStarts, 1);
        _expectNoRenderException(tester);

        var transitionStarts = 0;
        var transitionExits = 0;
        await _pumpSurface(
          tester,
          size: scenario.size,
          locale: scenario.locale,
          textScale: scenario.textScale,
          fontFamily: _evidenceFontFamily,
          child: _transition(
            locale: scenario.locale,
            onConfirmReady: () => transitionStarts++,
            onEndSession: () => transitionExits++,
          ),
        );
        final transitionButton = _buttonWithText(scenario.transitionStart);
        await _scrollUntilVisible(
          tester,
          transitionButton,
          scrollable: find.byType(Scrollable),
        );
        _expectAtLeast48(tester, transitionButton);
        await tester.tap(transitionButton);
        await tester.pumpAndSettle();
        expect(transitionStarts, 1);

        final transitionExitButton = _buttonWithText(scenario.exit);
        await _scrollUntilVisible(
          tester,
          transitionExitButton,
          scrollable: find.byType(Scrollable),
        );
        _expectAtLeast48(tester, transitionExitButton);
        if (scenario.textScale >= 1.5) {
          expect(
            tester.getSize(transitionExitButton).width,
            greaterThanOrEqualTo(scenario.size.width / 2 - 50),
          );
          expect(
            tester.getSize(find.text(scenario.exit)).height,
            lessThan(40),
          );
        }
        await tester.tap(transitionExitButton);
        await tester.pumpAndSettle();
        expect(transitionExits, 1);
        _expectNoRenderException(tester);

        var repeats = 0;
        var exits = 0;
        await _pumpSurface(
          tester,
          size: scenario.size,
          locale: scenario.locale,
          textScale: scenario.textScale,
          fontFamily: _evidenceFontFamily,
          child: _immersive(
            onRepeatInstruction: () => repeats++,
            onEndSession: () => exits++,
          ),
        );
        final repeatButton = _buttonWithText(scenario.repeat);
        final exitButton = _buttonWithText(scenario.exit);
        expect(repeatButton, findsOneWidget);
        expect(exitButton, findsOneWidget);
        _expectAtLeast48(tester, repeatButton);
        _expectAtLeast48(tester, exitButton);
        if (scenario.textScale >= 1.5) {
          expect(
            tester.getSize(repeatButton).width,
            greaterThanOrEqualTo(scenario.size.width - 50),
          );
          expect(
            tester.getSize(exitButton).width,
            greaterThanOrEqualTo(scenario.size.width - 50),
          );
          expect(
              tester.getSize(find.text(scenario.repeat)).height, lessThan(40));
          expect(tester.getSize(find.text(scenario.exit)).height, lessThan(40));
        }
        await _ensureVisible(tester, repeatButton);
        await tester.tap(repeatButton);
        await tester.pumpAndSettle();
        expect(repeats, 1);

        await _ensureVisible(tester, exitButton);
        await tester.tap(exitButton);
        await tester.pumpAndSettle();
        expect(exits, 1);
        _expectNoRenderException(tester);
      });
    }
  });

  group('deterministic screenshot evidence', () {
    testWidgets('intro DE portrait 200%', (tester) async {
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        fontFamily: _evidenceFontFamily,
        child: _intro(
          contentNotice: 'Die geprüften Offline-Inhalte sind verfügbar.',
        ),
      );
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile('$_evidenceRoot/01_intro_de_portrait_200.png'),
      );
    });

    testWidgets('transition EN landscape 200%', (tester) async {
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        fontFamily: _evidenceFontFamily,
        child: _transition(
          locale: 'en',
          isRoutineMode: true,
          compactGuidance: true,
          stage: TrainingSessionStage.preparation,
          remainingSeconds: 3,
          voiceGuidanceAvailable: false,
          onEndSession: () {},
        ),
      );
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile(
          '$_evidenceRoot/02_transition_en_landscape_200.png',
        ),
      );
    });

    testWidgets('transition EN landscape preparation actions 200%',
        (tester) async {
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        fontFamily: _evidenceFontFamily,
        child: _transition(
          locale: 'en',
          isRoutineMode: true,
          compactGuidance: true,
          stage: TrainingSessionStage.preparation,
          remainingSeconds: 3,
          voiceGuidanceAvailable: false,
          onEndSession: () {},
        ),
      );
      await _scrollUntilVisible(
        tester,
        _buttonWithText('Exit Session'),
        scrollable: find.byType(Scrollable),
      );
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile(
          '$_evidenceRoot/02b_transition_en_landscape_actions_200.png',
        ),
      );
    });

    testWidgets('immersive DE portrait 200%', (tester) async {
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        fontFamily: _evidenceFontFamily,
        child: _immersive(),
      );
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile(
          '$_evidenceRoot/03_immersive_de_portrait_200.png',
        ),
      );
    });

    testWidgets('immersive DE portrait controls 200%', (tester) async {
      await _pumpSurface(
        tester,
        size: _portrait,
        locale: 'de',
        fontFamily: _evidenceFontFamily,
        child: _immersive(),
      );
      await _ensureVisible(tester, _buttonWithText('Training abbrechen'));
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile(
          '$_evidenceRoot/03b_immersive_de_portrait_controls_200.png',
        ),
      );
    });

    testWidgets('immersive EN paused landscape 200%', (tester) async {
      await _pumpSurface(
        tester,
        size: _landscape,
        locale: 'en',
        fontFamily: _evidenceFontFamily,
        child: _immersive(
          state: _sessionState(
            stage: TrainingSessionStage.paused,
            repetitionIndex: 1,
            pauseReason: TrainingPauseReason.user,
            resumeStage: TrainingSessionStage.activeMovement,
          ),
          isRoutineMode: true,
          feedbackMode: TrainingFeedbackMode.silent,
        ),
      );
      await _ensureVisible(tester, find.text('TRAINING PAUSED'));
      await expectLater(
        find.byKey(_evidenceSurfaceKey),
        matchesGoldenFile(
          '$_evidenceRoot/04_immersive_en_landscape_paused_200.png',
        ),
      );
    });
  });
}
