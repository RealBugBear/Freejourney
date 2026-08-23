// test/features/training/presentation/training_anchor_sheet_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/features/training/presentation/widgets/training_anchor_sheet.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({required bool isAdultSelf, required void Function(TrainingAnchorResult?) onDone}) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            onDone(await showTrainingAnchorSheet(context, isAdultSelf: isAdultSelf));
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  final de = AppLocalizationsDe();

  testWidgets('adults see the recommendation badge', (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: true, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(de.trainingAnchorWakeUpAdult), findsOneWidget);
    expect(find.text(de.trainingAnchorRecommended), findsOneWidget);
    expect(find.text(de.trainingAnchorAfterSchool), findsNothing);
  });

  testWidgets('families see their own options and no recommendation',
      (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: false, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(de.trainingAnchorWakeUpChild), findsOneWidget);
    expect(find.text(de.trainingAnchorAfterSchool), findsOneWidget);
    expect(find.text(de.trainingAnchorRecommended), findsNothing);
  });

  testWidgets('the sleep hint appears only for a late anchor', (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: false, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsNothing);

    await tester.tap(find.text(de.trainingAnchorAfterDinner));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsOneWidget);

    await tester.tap(find.text(de.trainingAnchorWakeUpChild));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsNothing);
  });

  testWidgets('later returns nothing', (tester) async {
    TrainingAnchorResult? result;
    var called = false;
    await tester.pumpWidget(_harness(
      isAdultSelf: true,
      onDone: (value) {
        result = value;
        called = true;
      },
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorLater));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
  });

  testWidgets('confirming returns the anchor and its proposed time',
      (tester) async {
    TrainingAnchorResult? result;
    await tester.pumpWidget(
      _harness(isAdultSelf: true, onDone: (value) => result = value),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorMidday));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorConfirm));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.anchor, TrainingAnchor.midday);
    expect(result!.minutes, defaultMinutesFor(TrainingAnchor.midday));
  });
}
