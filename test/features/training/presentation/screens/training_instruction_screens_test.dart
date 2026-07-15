import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/presentation/screens/training_intro_screen.dart';
import 'package:corejourney/features/training/presentation/screens/training_movement_screen.dart';
import 'package:corejourney/features/training/presentation/screens/training_position_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _exercise({int repetitions = 3}) => Exercise(
      id: 'test_exercise',
      packageId: 'moro',
      sequenceNumber: 1,
      titleDe: 'Testübung',
      titleEn: 'Test Exercise',
      positionInstructionsDe: ['Lege dich bequem hin.'],
      positionInstructionsEn: ['Lie down comfortably.'],
      movementInstructionsDe: ['Bewege dich langsam.'],
      movementInstructionsEn: ['Move slowly.'],
      hintsDe: ['Atme ruhig weiter.'],
      hintsEn: ['Keep breathing calmly.'],
      executionGuideDe: 'Deutsche Anleitung',
      executionGuideEn: 'English guide',
      durationSeconds: 30,
      repetitions: repetitions,
      imagePath:
          'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_1.png',
    );

Widget _wrap(Widget child, {String locale = 'en'}) => ProviderScope(
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('training intro renders natural English copy', (tester) async {
    var started = false;

    await tester.pumpWidget(
      _wrap(TrainingIntroScreen(onStart: () => started = true)),
    );

    expect(find.text('Welcome to Your Session'), findsOneWidget);
    expect(
      find.text("Today, you'll practice seven movements at a calm pace."),
      findsOneWidget,
    );
    expect(
      find.text('Consistency matters more than intensity.'),
      findsOneWidget,
    );
    expect(find.text('7 movements'), findsOneWidget);
    expect(find.text('About 15–20 minutes'), findsOneWidget);
    expect(find.text('Comfortable clothing recommended'), findsOneWidget);
    expect(find.text('Start Session'), findsOneWidget);
    expect(find.text('Willkommen zu deiner Einheit'), findsNothing);

    await tester.ensureVisible(find.text('Start Session'));
    await tester.tap(find.text('Start Session'));
    expect(started, isTrue);
  });

  testWidgets('position step localizes chrome, progress, and exit dialog',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        TrainingPositionScreen(
          exercise: _exercise(),
          onContinue: () {},
        ),
      ),
    );

    expect(find.text('Lie down comfortably.'), findsOneWidget);
    expect(find.text('Continue to Movement'), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
    expect(find.byTooltip('Exit Session'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == 'Progress: step 1 of 21.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Exit Session?'), findsOneWidget);
    expect(
      find.text(
        'Are you sure you want to exit this session? Your progress will be lost.',
      ),
      findsOneWidget,
    );
    expect(find.text('Keep Training'), findsOneWidget);
    expect(find.text('Exit Session'), findsOneWidget);
  });

  testWidgets('movement step uses English instructions, tip, and repetitions',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        TrainingMovementScreen(
          exercise: _exercise(),
          onContinue: () {},
        ),
      ),
    );

    expect(find.text('Move slowly.'), findsOneWidget);
    expect(find.text('Tip'), findsOneWidget);
    expect(find.text('• Keep breathing calmly.'), findsOneWidget);
    expect(find.text('3 repetitions'), findsOneWidget);
    expect(find.text('Start Exercise'), findsOneWidget);
    expect(find.text('Hinweis'), findsNothing);
  });

  testWidgets('repetition count uses English singular and plural forms',
      (tester) async {
    await tester.pumpWidget(
      _wrap(
        TrainingMovementScreen(
          exercise: _exercise(repetitions: 1),
          onContinue: () {},
        ),
      ),
    );

    expect(find.text('1 repetition'), findsOneWidget);
    expect(find.text('1 repetitions'), findsNothing);

    await tester.pumpWidget(
      _wrap(
        TrainingMovementScreen(
          exercise: _exercise(repetitions: 3),
          onContinue: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3 repetitions'), findsOneWidget);
  });

  testWidgets('German training copy remains unchanged', (tester) async {
    await tester.pumpWidget(
      _wrap(
        TrainingMovementScreen(
          exercise: _exercise(),
          onContinue: () {},
        ),
        locale: 'de',
      ),
    );

    expect(find.text('Bewege dich langsam.'), findsOneWidget);
    expect(find.text('Hinweis'), findsOneWidget);
    expect(find.text('• Atme ruhig weiter.'), findsOneWidget);
    expect(find.text('3× Wiederholungen'), findsOneWidget);
    expect(find.text('Übung starten'), findsOneWidget);
  });
}
