import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_answer_choice_grid.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_reflex_profile_result_view.dart';
import 'package:corejourney/l10n/app_localizations.dart';

const _out = 'docs/evidence/adult-reflexprofil';
const _phone = Size(390, 844);
const _pixelRatio = 2.0;

void _noopChoice(ReflexAnswerChoice _) {}

Map<String, dynamic> _sampleScores() {
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

ReflexProfileAssessment _assessment({
  required Map<String, dynamic> scores,
  String version = 'adult_v3',
}) {
  return ReflexProfileAssessment(
    id: 'evidence',
    packageId: 'moro',
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

Widget _frame({
  required GlobalKey key,
  required Widget child,
  required ThemeData theme,
  Locale locale = const Locale('de'),
}) {
  return RepaintBoundary(
    key: key,
    child: ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final file = File('$_out/$filename');
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: _pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
    image.dispose();
  });
  expect(file.existsSync(), isTrue, reason: filename);
  expect(file.lengthSync(), greaterThan(5000), reason: filename);
}

void main() {
  testWidgets('capture adult reflexprofil evidence screenshots', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // 1) Adult result — light
    final lightKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: lightKey,
        theme: ThemeData.light(useMaterial3: true),
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    expect(find.text('Dein Reflexprofil'), findsOneWidget);
    await _capture(tester, lightKey, '01_adult_result_light.png');

    // 2) Adult result — dark
    final darkKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: darkKey,
        theme: ThemeData.dark(useMaterial3: true),
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    await _capture(tester, darkKey, '02_adult_result_dark.png');

    // 3) Legacy notice
    final legacyKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: legacyKey,
        theme: ThemeData.light(useMaterial3: true),
        child: AdultReflexProfileLegacyNotice(
          assessment: _assessment(
            scores: const {'legacy': true},
            version: 'adult_v1_unknown',
          ),
        ),
      ),
    );
    expect(find.text('Erstellt mit älterer Methode'), findsOneWidget);
    await _capture(tester, legacyKey, '03_adult_result_legacy.png');

    // 4) 2×2 answer grid (questionnaire answer surfaces)
    final gridKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: gridKey,
        theme: ThemeData.light(useMaterial3: true),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Beispielangabe',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              SizedBox(height: 16),
              AdultAnswerChoiceGrid(
                value: ReflexAnswerValue(yesNoUnknown: true),
                onSelected: _noopChoice,
                yesLabel: 'Ja',
                noLabel: 'Nein',
                unknownLabel: 'Weiß nicht',
                notApplicableLabel: 'Trifft nicht zu',
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Ja'), findsOneWidget);
    expect(find.text('Trifft nicht zu'), findsOneWidget);
    await _capture(tester, gridKey, '04_adult_answer_grid_2x2.png');

    // Real invite placement (same light result; invite slot below actions)
    final inviteKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: inviteKey,
        theme: ThemeData.light(useMaterial3: true),
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    await _capture(tester, inviteKey, 'adult_result_invite_placement.png');
  });
}
