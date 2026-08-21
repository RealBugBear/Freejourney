import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_result_copy.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/adult_score_band_l10n.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_amphibian_detail_tile.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_reflex_detail_tile.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_reflex_profile_result_view.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';
import 'package:corejourney/l10n/app_localizations_en.dart';

ReflexProfileAssessment _adultAssessment({
  required Map<String, dynamic> scores,
  String version = 'adult_v3',
}) {
  return ReflexProfileAssessment(
    id: 'test-adult',
    packageId: 'moro',
    subjectProfileId: 'subj',
    questionnaireType: 'adult_self_report',
    questionnaireVersion: version,
    scoringVersion: kAdultScoringVersion,
    status: 'completed',
    answers: const {},
    scores: scores,
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 8, 21),
    createdAt: DateTime(2026, 8, 21),
  );
}

Map<String, dynamic> _sampleAdultScores() {
  return AdultQuestionnaireScore(
    scoringVersion: kAdultScoringVersion,
    questionnaireVersion: 'adult_v3',
    reflexScores: {
      PrimitiveReflex.moro: const AdultReflexScoreResult(
        reflex: PrimitiveReflex.moro,
        positiveCount: 3,
        answeredCount: 5,
        possibleCount: 6,
        unknownCount: 1,
        notApplicableCount: 0,
        missingCount: 0,
        percent: 60,
        percentDisplay: 60,
        band: AdultHintBand.clusteredPattern,
      ),
      PrimitiveReflex.flr: const AdultReflexScoreResult(
        reflex: PrimitiveReflex.flr,
        positiveCount: 1,
        answeredCount: 4,
        possibleCount: 5,
        unknownCount: 0,
        notApplicableCount: 0,
        missingCount: 1,
        percent: 25,
        percentDisplay: 25,
        band: AdultHintBand.fewMatching,
      ),
    },
    amphibian: const AdultAmphibianScore(
      positiveCount: 0,
      answeredCount: 1,
      display: AmphibianDisplay.noneMatching,
      showDisclaimer: true,
    ),
    meta: const AdultScoreMeta(
      hiddenItemIds: [],
      notApplicableItemIds: [],
      unknownItemIds: [],
      noPublicTotalScore: true,
      movementIncluded: false,
      filterAnswers: {},
    ),
  ).toJson();
}

Widget _harness({
  required Widget child,
  ThemeData? theme,
  double textScale = 1.0,
  Locale locale = const Locale('de'),
}) {
  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: theme ?? ThemeData.light(useMaterial3: true),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('adult result UI', () {
    testWidgets('shows title, band text, no overall score, amphibian count',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: _sampleAdultScores()),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Dein Reflexprofil'), findsOneWidget);
      expect(find.textContaining('Gehäuftes Antwortmuster'), findsWidgets);
      expect(find.text('1 von 2 Merkmalen beantwortet'), findsOneWidget);
      expect(find.textContaining('Gesamt'), findsNothing);
      expect(find.textContaining('Durchschnitt'), findsNothing);
      expect(find.textContaining('Aufgrund der wenigen'), findsNothing);
    });

    testWidgets('legacy version shows legacy notice instead of bars',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          child: AdultReflexProfileLegacyNotice(
            assessment: _adultAssessment(
              scores: const {'legacy': true},
              version: 'adult_v1_unknown',
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Erstellt mit älterer Methode'), findsOneWidget);
      expect(find.textContaining('nicht angezeigt'), findsOneWidget);
      expect(find.textContaining('Gehäuftes'), findsNothing);
    });

    testWidgets('dark theme still shows band text without relying on color alone',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          theme: ThemeData.dark(useMaterial3: true),
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: _sampleAdultScores()),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('Wenige passende Angaben'), findsWidgets);
      expect(find.text('Dein Reflexprofil'), findsOneWidget);
    });

    testWidgets('200% text scale does not overflow', (tester) async {
      await tester.pumpWidget(
        _harness(
          textScale: 2.0,
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: _sampleAdultScores()),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      expect(find.text('Dein Reflexprofil'), findsOneWidget);
    });

    testWidgets('invite placement is below export actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: _sampleAdultScores()),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final pdf = find.textContaining('PDF');
      final inviteDivider = find.byType(Divider);
      expect(pdf, findsOneWidget);
      expect(inviteDivider, findsOneWidget);
      expect(
        tester.getTopLeft(inviteDivider).dy,
        greaterThan(tester.getTopLeft(pdf).dy),
      );
    });
  });

  group('adult copy hygiene', () {
    test('adult result chrome has no amphibian justification copy', () {
      final de = AppLocalizationsDe();
      final en = AppLocalizationsEn();
      final corpus = [
        de.adultResultTitle,
        de.adultResultDisclaimer,
        de.adultResultHintListTitle,
        de.adultAmphibianInsufficientData,
        de.adultAmphibianNoneMatching,
        de.adultAmphibianSingleHint,
        de.adultAmphibianClearSingleHint,
        de.adultResultLegacyBody,
        en.adultResultTitle,
        en.adultResultDisclaimer,
        en.adultResultHintListTitle,
        en.adultAmphibianInsufficientData,
        en.adultAmphibianNoneMatching,
        en.adultAmphibianSingleHint,
        en.adultAmphibianClearSingleHint,
        en.adultResultLegacyBody,
      ].join('\n');

      expect(corpus.contains('stabiler Profilwert'), isFalse);
      expect(corpus.contains('Aufgrund der wenigen'), isFalse);
      expect(corpus.contains('stable profile value'), isFalse);
      expect(corpus.contains('few available features'), isFalse);
    });

    testWidgets('amphibian card is last in same list with name once',
        (tester) async {
      final de = AppLocalizationsDe();
      final amphName = PrimitiveReflex.amphibian.copy.label('de');

      await tester.pumpWidget(
        _harness(
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: _sampleAdultScores()),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(AdultReflexDetailTile), findsNWidgets(2));
      expect(find.byType(AdultAmphibianDetailTile), findsOneWidget);
      expect(find.text(amphName), findsOneWidget);

      final lastRegular = tester.getTopLeft(
        find.byType(AdultReflexDetailTile).last,
      );
      final amph = tester.getTopLeft(find.byType(AdultAmphibianDetailTile));
      expect(amph.dy, greaterThan(lastRegular.dy));

      expect(find.text(de.adultAmphibianNoneMatching), findsOneWidget);
      expect(find.textContaining('stabiler Profilwert'), findsNothing);
      expect(find.textContaining('Aufgrund der wenigen'), findsNothing);
    });

    testWidgets('insufficientData shows short Keine Angaben label',
        (tester) async {
      final de = AppLocalizationsDe();
      final scores = AdultQuestionnaireScore(
        scoringVersion: kAdultScoringVersion,
        questionnaireVersion: 'adult_v3',
        reflexScores: const {},
        amphibian: const AdultAmphibianScore(
          positiveCount: 0,
          answeredCount: 0,
          display: AmphibianDisplay.insufficientData,
          showDisclaimer: true,
        ),
        meta: const AdultScoreMeta(
          hiddenItemIds: [],
          notApplicableItemIds: [],
          unknownItemIds: [],
          noPublicTotalScore: true,
          movementIncluded: false,
          filterAnswers: {},
        ),
      ).toJson();

      await tester.pumpWidget(
        _harness(
          child: AdultReflexProfileResultView(
            assessment: _adultAssessment(scores: scores),
            packageId: 'moro',
            isFirstResultDisplay: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(de.adultAmphibianInsufficientData), findsOneWidget);
      expect(de.adultAmphibianInsufficientData, 'Keine Angaben');
      expect(find.text(de.adultHintBandInsufficientData), findsNothing);
    });

    test('band and amphibian labels exist in DE/EN', () {
      final de = AppLocalizationsDe();
      final en = AppLocalizationsEn();
      for (final band in AdultHintBand.values) {
        expect(adultHintBandLabel(de, band).trim(), isNotEmpty);
        expect(adultHintBandLabel(en, band).trim(), isNotEmpty);
      }
      for (final display in AmphibianDisplay.values) {
        expect(amphibianDisplayLabel(de, display).trim(), isNotEmpty);
        expect(amphibianDisplayLabel(en, display).trim(), isNotEmpty);
      }
      expect(
        de.adultAmphibianInsufficientData,
        isNot(de.adultAmphibianNoneMatching),
      );
      expect(de.adultAmphibianInsufficientData, 'Keine Angaben');
      expect(
        de.adultAmphibianInsufficientData,
        isNot(de.adultHintBandInsufficientData),
      );
    });

    test('forbidden medical-claim fragments absent from adult result chrome',
        () {
      final de = AppLocalizationsDe();
      final en = AppLocalizationsEn();
      const forbidden = [
        'heilen',
        'Heilung',
        'Therapieerfolg',
        'diagnostiziert',
        'cure',
        'heal you',
        'treatment success',
      ];
      final corpus = [
        de.adultResultTitle,
        de.adultResultDisclaimer,
        de.adultResultLegacyBody,
        en.adultResultTitle,
        en.adultResultDisclaimer,
        en.adultResultLegacyBody,
        for (final copy in adultReflexResultCopyByReflex.values) ...[
          copy.shortDescriptionDe,
          copy.shortDescriptionEn,
          copy.limitsDe,
          copy.limitsEn,
        ],
      ].join('\n').toLowerCase();

      for (final word in forbidden) {
        expect(corpus.contains(word.toLowerCase()), isFalse, reason: word);
      }
    });
  });
}
