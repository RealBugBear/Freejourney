import 'package:corejourney/features/training/presentation/widgets/exercise_motion_visualizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('de'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: child,
        ),
      ),
    ),
  );
}

ExerciseMotionVisualizer _visualizer({
  String exerciseId = 'moro_ex1',
  int phaseIndex = 0,
  int repetitionIndex = 0,
  double phaseProgress = .25,
  bool reducedMotion = false,
}) {
  return ExerciseMotionVisualizer(
    exerciseId: exerciseId,
    phaseIndex: phaseIndex,
    repetitionIndex: repetitionIndex,
    phaseProgress: phaseProgress,
    reducedMotion: reducedMotion,
  );
}

void main() {
  test('contract is limited to the seven canonical Moro ids', () {
    expect(
      ExerciseMotionVisualizer.supportedExerciseIds,
      {
        'moro_ex1',
        'moro_ex2',
        'moro_ex3',
        'moro_ex4',
        'moro_ex5',
        'moro_ex6',
        'moro_ex7',
      },
    );
    expect(
      () => _visualizer(exerciseId: 'tlr_ex1'),
      throwsArgumentError,
    );
  });

  testWidgets('all seven motion guides render from supplied timeline state',
      (tester) async {
    for (final exerciseId in ExerciseMotionVisualizer.supportedExerciseIds) {
      await tester.pumpWidget(
        _wrap(
          _visualizer(
            exerciseId: exerciseId,
            phaseIndex: 1,
            repetitionIndex: 2,
            phaseProgress: .5,
          ),
        ),
      );

      expect(
          find.byKey(const ValueKey('exercise-motion-canvas')), findsOneWidget);
      expect(tester.takeException(), isNull, reason: exerciseId);
    }
  });

  testWidgets('semantics describe phase, side, repetition, and coarse progress',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _wrap(
        _visualizer(
          exerciseId: 'moro_ex2',
          phaseIndex: 0,
          repetitionIndex: 1,
          phaseProgress: .56,
        ),
        locale: const Locale('de'),
      ),
    );

    final node = tester.getSemantics(
      find.byKey(const ValueKey('exercise-motion-semantics')),
    );
    expect(
      node.label,
      'Moro 3, Bewegungsvorschau: Fuß hochgleiten, linke Seite',
    );
    expect(node.value, 'Wiederholung 2, 50 Prozent');
    semantics.dispose();
  });

  testWidgets('normal motion repaints as canonical phase progress advances',
      (tester) async {
    await tester.pumpWidget(
      _wrap(_visualizer(phaseProgress: .1)),
    );
    final first = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('exercise-motion-canvas')),
        )
        .painter!;

    await tester.pumpWidget(
      _wrap(_visualizer(phaseProgress: .8)),
    );
    final second = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('exercise-motion-canvas')),
        )
        .painter!;

    expect(second.shouldRepaint(first), isTrue);
  });

  testWidgets('reduced motion holds a static target pose within each phase',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        _visualizer(
          phaseProgress: .1,
          reducedMotion: true,
        ),
      ),
    );
    final first = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('exercise-motion-canvas')),
        )
        .painter!;

    await tester.pumpWidget(
      _wrap(
        _visualizer(
          phaseProgress: .8,
          reducedMotion: true,
        ),
      ),
    );
    final second = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('exercise-motion-canvas')),
        )
        .painter!;

    expect(second.shouldRepaint(first), isFalse);

    await tester.pumpWidget(
      _wrap(
        _visualizer(
          phaseIndex: 1,
          phaseProgress: .8,
          reducedMotion: true,
        ),
      ),
    );
    final nextPhase = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('exercise-motion-canvas')),
        )
        .painter!;
    expect(nextPhase.shouldRepaint(second), isTrue);
  });
}
