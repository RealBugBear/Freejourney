import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_progress_profile_card.dart';
import 'package:corejourney/features/assessment/presentation/widgets/reflex_radar_chart.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';

Map<String, dynamic> _adultV3Scores() => AdultQuestionnaireScore(
      scoringVersion: kAdultScoringVersion,
      questionnaireVersion: 'adult_v3',
      reflexScores: {
        PrimitiveReflex.moro: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.moro,
          positiveCount: 3,
          answeredCount: 5,
          possibleCount: 6,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 1,
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

ReflexProfileSummary _summary({
  required String type,
  required String version,
  Map<String, dynamic>? scores,
}) {
  return ReflexProfileSummary(
    profile: ReflexSubjectProfile(
      id: 'p1',
      displayName: 'Alex',
      profileType: type,
    ),
    latestAssessment: ReflexProfileAssessment(
      id: 'a1',
      packageId: 'moro',
      subjectProfileId: 'p1',
      questionnaireType:
          type == 'adult_self' ? 'adult_self_report' : 'child_parent',
      questionnaireVersion: version,
      scoringVersion: kAdultScoringVersion,
      status: 'completed',
      answers: const {},
      scores: scores ?? _adultV3Scores(),
      warningConfirmations: const [],
      safetyStatus: 'clear',
      completedAt: DateTime(2026, 8, 21),
      createdAt: DateTime(2026, 8, 21),
    ),
  );
}

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SizedBox(height: 248, child: child),
    ),
  );
}

void main() {
  testWidgets('adult_v3 progress card shows top bands and no radar',
      (tester) async {
    await tester.pumpWidget(
      _harness(
        AdultProgressProfileCard(
          summary: _summary(type: 'adult_self', version: 'adult_v3'),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ReflexRadarChart), findsNothing);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.textContaining('Gehäuftes Antwortmuster'), findsOneWidget);
    expect(find.textContaining('Wenige passende Angaben'), findsOneWidget);
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('legacy adult progress card shows notice without radar',
      (tester) async {
    final de = AppLocalizationsDe();
    await tester.pumpWidget(
      _harness(
        AdultProgressProfileCard(
          summary: _summary(
            type: 'adult_self',
            version: 'adult_v1_unknown',
            scores: const {'legacy': true},
          ),
          onTap: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ReflexRadarChart), findsNothing);
    expect(find.text(de.progressAdultLegacyCardBody), findsOneWidget);
    expect(find.textContaining('Gehäuftes'), findsNothing);
  });

  test('isAdultProgressAssessment keys off questionnaire_type', () {
    final adult = _summary(type: 'adult_self', version: 'adult_v3')
        .latestAssessment!;
    final child = _summary(
      type: 'child',
      version: 'child_parent_v1',
      scores: const {'moro': 0.5},
    ).latestAssessment!;
    expect(isAdultProgressAssessment(adult), isTrue);
    expect(isAdultProgressAssessment(child), isFalse);
  });
}
