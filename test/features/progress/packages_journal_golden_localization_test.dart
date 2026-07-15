import 'package:corejourney/features/golden_day/presentation/screens/golden_day_screen.dart';
import 'package:corejourney/features/progress/presentation/screens/progress_overview_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Widget _goldenDayApp(Locale locale) => ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const GoldenDayScreen(),
      ),
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en_US');
  });

  test('German source copy stays exact and English uses approved terms', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en', 'US'));

    expect(de.packagesNameTlr, 'Tonischer Labirint Reflex (TLR)');
    expect(en.packagesNameTlr, 'Tonic Labyrinthine Reflex (TLR)');
    expect(de.journalEntrySummary(8, 2), '8 gesamt · 2 Woche');
    expect(en.journalEntrySummary(8, 2), '8 total · 2 this week');
    expect(de.progressProfileAgeYears(1), '1 Jahr');
    expect(de.progressProfileAgeYears(3), '3 Jahre');
    expect(en.progressProfileAgeYears(1), '1 year');
    expect(en.progressProfileAgeYears(3), '3 years');
    expect(
      de.progressCurrentPackageDay('Moro', 4, 28),
      'Moro · Tag 4 von 28',
    );
    expect(
      en.progressCurrentPackageDay('Moro', 4, 28),
      'Moro · Day 4 of 28',
    );
    expect(
      de.progressObservationCount(1),
      '1 Einträge im aktuellen Zeitraum',
    );
    expect(en.progressObservationCount(1), '1 entry in the current period');

    final englishCopy = [
      en.packagesNameSpinalGalant,
      en.packagesNameTlr,
      en.packagesNameBabkin,
      en.packagesNameSuchSaug,
      en.journalTimelineEmptyBody,
      en.progressWellbeingDescription,
      en.progressNoReflexProfileBody,
      en.progressObservationsEmptyBody,
      en.goldenDayCompletionMessage,
    ].join('\n');

    expect(englishCopy, isNot(matches(RegExp(r'[äöüÄÖÜß]'))));
    expect(englishCopy, isNot(contains('FLR')));
    expect(
      englishCopy.toLowerCase(),
      isNot(matches(RegExp(
        r'\b(?:unit|diagnos(?:e|is)|treat(?:ment)?|cure|heal|therapy|medical)\b',
      ))),
    );
  });

  test('journal time keeps German HH:mm and follows en-US conventions', () {
    final timestamp = DateTime(2026, 7, 15, 9, 5);

    expect(DateFormat.jm('de').format(timestamp), '09:05');
    expect(DateFormat.jm('en_US').format(timestamp), '9:05\u202fAM');
    expect(DateFormat.yMMM('de').format(timestamp), 'Juli 2026');
    expect(DateFormat.yMMM('en_US').format(timestamp), 'Jul 2026');
    expect(DateFormat.yMd('de').format(timestamp), '15.7.2026');
    expect(DateFormat.yMd('en_US').format(timestamp), '7/15/2026');
    expect(formatProgressChartDate(timestamp, const Locale('de')), '15.7');
    expect(
      formatProgressChartDate(timestamp, const Locale('en', 'US')),
      '7/15',
    );
  });

  testWidgets('Golden Day renders English and preserves German copy',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_goldenDayApp(const Locale('en', 'US')));
    await tester.pumpAndSettle();

    expect(find.text('Golden Day 🎉'), findsOneWidget);
    expect(find.text('Congratulations!'), findsOneWidget);
    expect(find.text('You completed the 4-week training!'), findsOneWidget);
    expect(find.text('How do you feel?'), findsOneWidget);
    expect(find.text('Ready for More!'), findsOneWidget);
    expect(find.text('Practice a Little More'), findsOneWidget);
    expect(find.text('Glückwunsch!'), findsNothing);

    await tester.pumpWidget(_goldenDayApp(const Locale('de')));
    await tester.pumpAndSettle();

    expect(find.text('Glückwunsch!'), findsOneWidget);
    expect(
      find.text('Du hast das 4-Wochen-Training erfolgreich abgeschlossen!'),
      findsOneWidget,
    );
    expect(find.text('Wie fühlst du dich?'), findsOneWidget);
    expect(find.text('Bereit für mehr!'), findsOneWidget);
    expect(find.text('Noch etwas üben'), findsOneWidget);
  });
}
