import 'package:corejourney/features/accompaniment/presentation/screens/accompaniment_screen.dart';
import 'package:corejourney/features/mood/presentation/widgets/mood_chart_widget.dart';
import 'package:corejourney/features/mood/presentation/widgets/mood_trend_chart.dart';
import 'package:corejourney/features/profile/presentation/screens/profile_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('de');
    await initializeDateFormatting('en_US');
  });

  test('German source copy stays exact and English is idiomatic', () {
    final de = lookupAppLocalizations(const Locale('de'));
    final en = lookupAppLocalizations(const Locale('en', 'US'));

    expect(de.accompanimentTitle, 'Begleitung');
    expect(
      de.accompanimentProfessionalBody,
      'Manche Übungen werden mit einer zweiten Person durchgeführt. Dabei '
      'geht es nicht um Krafttraining, sondern um klares Spüren von Richtung, '
      'Bewegung und Widerstand. Ein geschulter Trainer kann dich dabei sicher '
      'anleiten.',
    );
    expect(
      de.moodMetricSelectionHint,
      'Tippe auf einen Wert, um ihn auszuwählen, oder lass ihn frei.',
    );
    expect(de.themeChanged('Dunkel'), 'Theme geändert zu: Dunkel');
    expect(de.profileContactNameQuestion, 'Wie sollen wir dich nennen?');

    expect(en.accompanimentSharedExperiencesAction, 'View Experiences');
    expect(en.moodForWhom, 'Who Is This For?');
    expect(en.moodExperienceSinceMoreCalm, 'calmer');
    expect(en.profileConnectedWith('Alex'), 'Connected to Alex');
    expect(
      en.profileContactNameHint,
      'e.g., Maria or the Miller family',
    );

    expect(de.accompanimentProposalCount(1), '1 offener Terminvorschlag');
    expect(de.accompanimentProposalCount(3), '3 offene Terminvorschläge');
    expect(en.accompanimentProposalCount(1), '1 Open Appointment Proposal');
    expect(en.accompanimentProposalCount(3), '3 Open Appointment Proposals');
    expect(de.profileAgeYears(1), '1 Jahr');
    expect(de.profileAgeYears(4), '4 Jahre');
    expect(en.profileAgeYears(1), '1 year old');
    expect(en.profileAgeYears(4), '4 years old');

    final englishCopy = [
      en.accompanimentConnectBody,
      en.accompanimentProfessionalBody,
      en.accompanimentNoTrainerBody,
      en.moodExperienceDescription,
      en.moodNoteBody,
      en.profileCommunityDisplayNameHint,
      en.profileContactNameBodyWithCommunity,
    ].join('\n');
    expect(englishCopy, isNot(matches(RegExp(r'[äöüÄÖÜß]'))));
    expect(
      englishCopy.toLowerCase(),
      isNot(matches(RegExp(
        r'\b(?:diagnos(?:e|is)|treat(?:ment)?|cure|heal|therapy|medical)\b',
      ))),
    );
  });

  test('date helpers preserve German copy and follow en-US conventions', () {
    final timestamp = DateTime(2026, 7, 15, 15, 30);

    expect(
      formatMoodNoteDate(timestamp, const Locale('de')),
      '15.07.2026',
    );
    expect(
      formatMoodNoteDate(timestamp, const Locale('en', 'US')),
      '7/15/2026',
    );
    expect(formatMoodChartDate(timestamp, const Locale('de')), '15.7');
    expect(
      formatMoodChartDate(timestamp, const Locale('en', 'US')),
      '7/15',
    );
    expect(
      formatProfileBirthDate(timestamp, const Locale('de')),
      '15.07.2026',
    );
    expect(
      formatProfileBirthDate(timestamp, const Locale('en', 'US')),
      '7/15/2026',
    );
    expect(
      formatAccompanimentAppointmentDate(timestamp, const Locale('de')),
      'Mi., 15. Juli · 15:30',
    );
    final englishAppointment = formatAccompanimentAppointmentDate(
      timestamp,
      const Locale('en', 'US'),
    );
    expect(englishAppointment, contains('Wed, Jul 15'));
    expect(englishAppointment, contains('3:30'));
    expect(englishAppointment, contains('PM'));
  });
}
