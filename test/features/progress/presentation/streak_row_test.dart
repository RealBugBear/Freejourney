// test/features/progress/presentation/streak_row_test.dart
import 'package:corejourney/features/progress/presentation/providers/streak_provider.dart';
import 'package:corejourney/features/progress/presentation/widgets/streak_row.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

StreakView _view({
  int length = 4,
  int credits = 1,
  Set<DateTime>? trainingDays,
  Set<DateTime>? rescuedDays,
  Set<DateTime>? newlyRescued,
}) {
  return StreakView(
    length: length,
    credits: credits,
    trainingDays: trainingDays ?? {DateTime(2026, 8, 17), DateTime(2026, 8, 18)},
    rescuedDays: rescuedDays ?? {DateTime(2026, 8, 19)},
    newlyRescued: newlyRescued ?? const <DateTime>{},
  );
}

void main() {
  testWidgets('shows the streak length and the remaining credits',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();

    expect(find.text('Serie · 4 Tage'), findsOneWidget);
    expect(find.text('1 Freischein'), findsOneWidget);
  });

  testWidgets('marks trained, rescued and open days differently',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();

    // 2026-08-17 is a Monday, so the week runs Mon..Sun at indices 0..6:
    // trained on the 17th and 18th, rescued on the 19th, today is the 20th.
    expect(find.byKey(const ValueKey('streak-day-trained-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-trained-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-rescued-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-today-3')), findsOneWidget);
  });

  testWidgets('shows the rescue notice only when a day was just rescued',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();
    expect(find.text('Ein Freischein hat deine Serie gerettet.'), findsNothing);

    await tester.pumpWidget(
      _harness(
        StreakRow(
          view: _view(newlyRescued: {DateTime(2026, 8, 19)}),
          today: DateTime(2026, 8, 20),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Ein Freischein hat deine Serie gerettet.'),
      findsOneWidget,
    );
  });
}
