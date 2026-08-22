import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/services/reflex_profile_pdf_radar.dart';
import 'package:corejourney/features/assessment/domain/services/reflex_profile_pdf_service.dart';
import 'package:corejourney/features/assessment/presentation/reflex_profile_pdf_copy.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = ReflexProfilePdfService();
  final l10n = AppLocalizationsDe();
  final copy = reflexProfilePdfCopyFromL10n(l10n);
  const locale = Locale('de');

  group('ReflexProfilePdfService §10.3b', () {
    test('radar axis order follows PrimitiveReflex declaration, not percent',
        () {
      final base = _childScoresFromCatalog();
      final scoresBase = radarScoresForPdf(base, localeCode: 'de');
      expect(scoresBase.length, greaterThan(1));

      final first = scoresBase.first;
      final second = scoresBase.firstWhere(
        (score) => score.percent != first.percent,
        orElse: () => throw StateError('Need two reflexes with different percents'),
      );

      PrimitiveReflex? reflexForShortLabel(String shortLabel) {
        for (final reflex in PrimitiveReflex.values) {
          if (reflex.shortLabel('de') == shortLabel) return reflex;
        }
        return null;
      }

      final firstReflex = reflexForShortLabel(first.shortLabel)!;
      final secondReflex = reflexForShortLabel(second.shortLabel)!;

      final swapped = Map<String, dynamic>.from(base);
      final firstMap = Map<String, dynamic>.from(swapped[firstReflex.name] as Map);
      final secondMap =
          Map<String, dynamic>.from(swapped[secondReflex.name] as Map);
      swapped[firstReflex.name] = secondMap;
      swapped[secondReflex.name] = firstMap;

      final orderBase =
          scoresBase.map((score) => score.shortLabel).toList();
      final orderSwapped = radarScoresForPdf(swapped, localeCode: 'de')
          .map((score) => score.shortLabel)
          .toList();

      expect(orderBase, orderSwapped);

      final scoresSwapped = radarScoresForPdf(swapped, localeCode: 'de');
      final firstIndex = scoresBase.indexOf(first);
      final secondIndex = scoresBase.indexOf(second);
      expect(
        scoresBase[firstIndex].percent,
        isNot(scoresSwapped[firstIndex].percent),
      );
      expect(
        scoresBase[secondIndex].percent,
        isNot(scoresSwapped[secondIndex].percent),
      );
    });

    test('child PDF is one page without answer overview', () async {
      final assessment = _childAssessment(_childScoresFromCatalog());
      final content = service.buildSummaryContent(
        assessment,
        locale: locale,
        copy: copy,
        subjectName: 'Mila',
      );
      final bytes = await service.renderSummaryPdfBytes(
        assessment,
        locale: locale,
        copy: copy,
        subjectName: 'Mila',
      );

      expect(countPdfPages(bytes), 1);
      expect(content.subjectName, 'Mila');
      expect(content.listRows, isNotEmpty);
      expect(content.radarScores.length, greaterThanOrEqualTo(3));
    });

    test(
        'child insufficientData shows dash in percent column, not a number',
        () {
      final assessment = _childAssessment(_childScoresFromCatalog());
      final content = service.buildSummaryContent(
        assessment,
        locale: locale,
        copy: copy,
        subjectName: 'Mila',
      );

      final moroRow = content.listRows.firstWhere(
        (row) => row.label == PrimitiveReflex.moro.label('de'),
      );
      expect(moroRow.percent, '-');
      expect(RegExp(r'\d').hasMatch(moroRow.percent), isFalse);
      expect(moroRow.band, l10n.scoreBandInsufficientData);

      final delayRow = content.listRows.firstWhere(
        (row) => row.label == PrimitiveReflex.delay.label('de'),
      );
      expect(delayRow.percent, '0%');
    });

    test('adult PDF is one page with amphibian in list but not as radar axis',
        () async {
      final assessment = _adultAssessment(_adultScoresFromCatalog());
      final content = service.buildSummaryContent(
        assessment,
        locale: locale,
        copy: copy,
        subjectName: 'Alex',
      );

      expect(content.radarScores.any((score) => score.shortLabel == 'Amphib.'),
          isFalse);
      expect(content.listRows.any((row) => row.isAmphibian), isTrue);
      expect(
        content.listRows.any((row) => row.label.contains('Entwicklungsverz')),
        isFalse,
      );

      final amphibian = content.listRows.firstWhere((row) => row.isAmphibian);
      expect(amphibian.percent, isEmpty);
      expect(amphibian.band, l10n.adultAmphibianSingleHint);

      final moroRow = content.listRows
          .where((row) => row.label == PrimitiveReflex.moro.label('de'))
          .firstOrNull;
      expect(moroRow, isNotNull);
      expect(moroRow!.percent, '-');
      expect(moroRow.band, l10n.adultHintBandInsufficientData);

      final dataBasisValues =
          content.listRows.map((row) => row.dataBasis).toSet();
      expect(dataBasisValues.length, greaterThan(1));

      final bytes = await service.renderSummaryPdfBytes(
        assessment,
        locale: locale,
        copy: copy,
        subjectName: 'Alex',
      );

      expect(countPdfPages(bytes), 1);
      expect(content.radarScores.length, 12);
      expect(
        content.listRows.where((row) => !row.isAmphibian).length,
        13,
      );
      expect(
        content.radarScores
            .any((score) => score.shortLabel == PrimitiveReflex.moro.shortLabel('de')),
        isFalse,
      );
    });
  });

  test('generate evidence PDFs when RUN_PDF_EVIDENCE=1', () async {
    await writePdfEvidenceIfRequested();
  });
}

ReflexProfileAssessment _childAssessment(Map<String, dynamic> scores) {
  return ReflexProfileAssessment(
    id: 'child-pdf-test',
    questionnaireType: 'child_parent_report',
    questionnaireVersion: 'child_v1',
    scoringVersion: 'score_equal_weight_v1',
    status: 'completed',
    answers: const {
      'q044': {'answer': 'yes'},
      'q045': {'answer': 'no'},
    },
    scores: scores,
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 8, 22),
    createdAt: DateTime(2026, 8, 22),
  );
}

ReflexProfileAssessment _adultAssessment(Map<String, dynamic> scores) {
  return ReflexProfileAssessment(
    id: 'adult-pdf-test',
    questionnaireType: 'adult_self_report',
    questionnaireVersion: 'adult_v3',
    scoringVersion: kAdultScoringVersion,
    status: 'completed',
    answers: const {},
    scores: scores,
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 8, 22),
    createdAt: DateTime(2026, 8, 22),
  );
}

/// Realistic child_v1 scores: varied denominators, Moro insufficientData.
Map<String, dynamic> _childScoresFromCatalog() {
  const scoring = ReflexProfileScoringService();
  final answers = <String, ReflexAnswerValue>{};

  for (final question in childParentQuestionnaireV1.questions) {
    if (question.role == ReflexQuestionRole.safety) {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: false);
      continue;
    }
    if (!question.contributesToScore) continue;

    if (question.reflexes.contains(PrimitiveReflex.moro)) {
      answers[question.id] = const ReflexAnswerValue();
      continue;
    }

    final digits = RegExp(r'\d+').firstMatch(question.id)?.group(0);
    final n = digits == null ? 0 : int.parse(digits);
    if (n % 7 == 0) {
      answers[question.id] = const ReflexAnswerValue();
    } else if (n % 4 == 0) {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: false);
    } else if (n % 3 == 0) {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: false);
    } else {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: true);
    }
  }

  return {
    for (final entry in scoring
        .score(
          definition: childParentQuestionnaireV1,
          answers: answers,
        )
        .reflexScores
        .entries)
      entry.key.name: entry.value.toJson(),
  };
}

/// Realistic adult_v3 scores: varied denominators, Moro insufficientData,
/// amphibian single hint — no child-only reflexes like delay.
Map<String, dynamic> _adultScoresFromCatalog() {
  const engine = AdultReflexProfileScoringService();
  final answers = <String, ReflexAnswerValue>{};

  for (final question in adultSelfQuestionnaireV3.questions) {
    if (question.role == ReflexQuestionRole.safety) {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: false);
      continue;
    }
    if (!adultQuestionScores(question, movementEnabled: false)) {
      continue;
    }

    if (question.reflexes.contains(PrimitiveReflex.moro)) {
      answers[question.id] = const ReflexAnswerValue(isUnknown: true);
      continue;
    }

    final digits = RegExp(r'\d+').firstMatch(question.id)?.group(0);
    final n = digits == null ? 0 : int.parse(digits);
    if (n % 7 == 0) {
      answers[question.id] = const ReflexAnswerValue(isUnknown: true);
    } else if (n % 4 == 0) {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: false);
    } else if (n % 3 == 0) {
      answers[question.id] = const ReflexAnswerValue(isNotApplicable: true);
    } else {
      answers[question.id] = const ReflexAnswerValue(yesNoUnknown: true);
    }
  }

  answers['s017'] = const ReflexAnswerValue(yesNoUnknown: true);
  answers['s102'] = const ReflexAnswerValue(yesNoUnknown: false);

  return engine
      .score(
        definition: adultSelfQuestionnaireV3,
        answers: answers,
      )
      .toJson();
}

/// Writes evidence PDFs when RUN_PDF_EVIDENCE=1 (used by release script).
Future<void> writePdfEvidenceIfRequested() async {
  if (Platform.environment['RUN_PDF_EVIDENCE'] != '1') return;

  TestWidgetsFlutterBinding.ensureInitialized();
  const service = ReflexProfilePdfService();
  final l10n = AppLocalizationsDe();
  final copy = reflexProfilePdfCopyFromL10n(l10n);
  const locale = Locale('de');
  final outDir = Directory('docs/evidence/adult-reflexprofil');
  await outDir.create(recursive: true);

  final child = await service.renderSummaryPdfBytes(
    _childAssessment(_childScoresFromCatalog()),
    locale: locale,
    copy: copy,
    subjectName: 'Mila',
  );
  final adult = await service.renderSummaryPdfBytes(
    _adultAssessment(_adultScoresFromCatalog()),
    locale: locale,
    copy: copy,
    subjectName: 'Alex',
  );

  await File('${outDir.path}/07_pdf_child_summary.pdf')
      .writeAsBytes(child, flush: true);
  await File('${outDir.path}/08_pdf_adult_summary.pdf')
      .writeAsBytes(adult, flush: true);
}
