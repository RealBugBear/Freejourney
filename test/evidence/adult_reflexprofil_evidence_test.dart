import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/core/theme/app_colors.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_answer_json.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';
import 'package:corejourney/features/assessment/presentation/widgets/additional_answers_panel.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_answer_choice_grid.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_progress_profile_card.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_reflex_profile_result_view.dart';
import 'package:corejourney/features/profile/presentation/widgets/subject_profile_reflex_action_tile.dart';
import 'package:corejourney/l10n/app_localizations.dart';

const _out = 'docs/evidence/adult-reflexprofil';
const _phone = Size(390, 844);
const _pixelRatio = 2.0;

void _noopChoice(ReflexAnswerChoice _) {}

/// Two typed-in notes, enough to show what the collapsed panel holds.
List<(ReflexQuestionModule, List<RelevantAnswerItem>)> _additionalAnswerGroups() {
  const sleepNote = ReflexQuestion(
    id: 'ev-note-sleep',
    number: 1,
    module: ReflexQuestionModule.behaviorEmotion,
    textDe: 'Gibt es sonst etwas, das euch auffällt?',
    textEn: 'Is there anything else you notice?',
    answerType: ReflexAnswerType.freeText,
    role: ReflexQuestionRole.context,
  );
  const walkingAge = ReflexQuestion(
    id: 'ev-note-walking',
    number: 2,
    module: ReflexQuestionModule.motorSkills,
    textDe: 'Mit wie vielen Monaten lief euer Kind frei?',
    textEn: 'At how many months did your child walk unaided?',
    answerType: ReflexAnswerType.monthsNumber,
    role: ReflexQuestionRole.context,
  );

  return [
    (
      walkingAge.module,
      const [RelevantAnswerItem(question: walkingAge, selectedOptionLabels: [], months: 17)],
    ),
    (
      sleepNote.module,
      const [
        RelevantAnswerItem(
          question: sleepNote,
          selectedOptionLabels: [],
          freeText: 'Schläft seit dem Umzug schlechter ein.',
        ),
      ],
    ),
  ];
}

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
      // Five axes so the evidence screenshots show a real radar rather than
      // the "too little data" fallback (the chart needs at least three).
      PrimitiveReflex.atnr: const AdultReflexScoreResult(
        reflex: PrimitiveReflex.atnr,
        positiveCount: 2,
        answeredCount: 4,
        possibleCount: 4,
        unknownCount: 0,
        notApplicableCount: 0,
        missingCount: 0,
        percent: 50,
        percentDisplay: 50,
        band: AdultHintBand.someMatching,
      ),
      PrimitiveReflex.tlr: const AdultReflexScoreResult(
        reflex: PrimitiveReflex.tlr,
        positiveCount: 3,
        answeredCount: 4,
        possibleCount: 5,
        unknownCount: 1,
        notApplicableCount: 0,
        missingCount: 0,
        percent: 75,
        percentDisplay: 75,
        band: AdultHintBand.stronglyClustered,
      ),
      PrimitiveReflex.spinalGalant: const AdultReflexScoreResult(
        reflex: PrimitiveReflex.spinalGalant,
        positiveCount: 1,
        answeredCount: 5,
        possibleCount: 5,
        unknownCount: 0,
        notApplicableCount: 0,
        missingCount: 0,
        percent: 20,
        percentDisplay: 20,
        band: AdultHintBand.fewMatching,
      ),
    },
    amphibian: const AdultAmphibianScore(
      positiveCount: 1,
      answeredCount: 2,
      display: AmphibianDisplay.singleHint,
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
  Map<String, dynamic> answers = const {},
}) {
  return ReflexProfileAssessment(
    id: 'evidence',
    packageId: 'moro',
    questionnaireType: 'adult_self_report',
    questionnaireVersion: version,
    scoringVersion: kAdultScoringVersion,
    status: 'completed',
    answers: answers,
    scores: scores,
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 8, 21),
    createdAt: DateTime(2026, 8, 21),
  );
}

/// One amphibian item matching → one filled dot (§10.2b evidence).
Map<String, dynamic> _amphibianSampleAnswers() => {
      's017': reflexAnswerToJson(
        const ReflexAnswerValue(yesNoUnknown: true),
      ),
      's102': reflexAnswerToJson(
        const ReflexAnswerValue(yesNoUnknown: false),
      ),
    };

ThemeData _evidenceTheme({required Brightness brightness}) {
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ),
  );
  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.light
        ? AppColors.backgroundLight
        : null,
    textTheme: base.textTheme.apply(fontFamily: 'Poppins'),
  );
}

Widget _frame({
  required GlobalKey key,
  required Widget child,
  required Brightness brightness,
  Locale locale = const Locale('de'),
}) {
  return RepaintBoundary(
    key: key,
    child: ColoredBox(
      color: brightness == Brightness.light
          ? AppColors.backgroundLight
          : const Color(0xFF121212),
      child: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _evidenceTheme(brightness: brightness),
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    ),
  );
}

void _replaceTestFontFallbacks() {
  for (final element in find.byType(RichText, skipOffstage: false).evaluate()) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderParagraph) continue;
    final text = renderObject.text;
    if (text is TextSpan) {
      renderObject.text = _withEvidenceFont(text);
    }
  }
}

InlineSpan _withEvidenceFont(InlineSpan span) {
  if (span is! TextSpan) return span;
  final style = span.style ?? const TextStyle();
  return TextSpan(
    text: span.text,
    children: span.children?.map(_withEvidenceFont).toList(),
    style: style.copyWith(fontFamily: style.fontFamily ?? 'Poppins'),
    recognizer: span.recognizer,
    mouseCursor: span.mouseCursor,
    onEnter: span.onEnter,
    onExit: span.onExit,
    semanticsLabel: span.semanticsLabel,
    semanticsIdentifier: span.semanticsIdentifier,
    locale: span.locale,
    spellOut: span.spellOut,
  );
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey key,
  String filename,
) async {
  await tester.pump();
  _replaceTestFontFallbacks();
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
  expect(file.lengthSync(), greaterThan(8000), reason: filename);
}

Future<void> _loadEvidenceFonts() async {
  final flutterRoot = await _findFlutterRoot();
  final materialFonts = Directory(
    '${flutterRoot.path}/bin/cache/artifacts/material_fonts',
  );
  final roboto = File('${materialFonts.path}/Roboto-Regular.ttf');
  for (final family in const ['Poppins', 'Roboto', '.SF Pro Text']) {
    await _loadFont(family: family, file: roboto);
  }
  await _loadFont(
    family: 'MaterialIcons',
    file: File('${materialFonts.path}/MaterialIcons-Regular.otf'),
  );
}

Future<Directory> _findFlutterRoot() async {
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  if (configuredRoot != null && configuredRoot.isNotEmpty) {
    return Directory(configuredRoot);
  }
  final which = await Process.run('which', ['flutter']);
  if (which.exitCode != 0) {
    throw StateError('Flutter SDK not found; set FLUTTER_ROOT.');
  }
  final flutterBin = File((which.stdout as String).trim());
  return flutterBin.parent.parent;
}

Future<void> _loadFont({required String family, required File file}) async {
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadEvidenceFonts();
  });

  testWidgets('capture adult reflexprofil evidence screenshots', (tester) async {
    await tester.binding.setSurfaceSize(_phone);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final lightKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: lightKey,
        brightness: Brightness.light,
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores(), answers: _amphibianSampleAnswers()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    expect(find.text('Dein Reflexprofil'), findsOneWidget);
    await _capture(tester, lightKey, '01_adult_result_light.png');

    // Child result: the parent's own notes start collapsed (founder decision
    // 2026-08-23), so the result reads as radar plus bars.
    final collapsedKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: collapsedKey,
        brightness: Brightness.light,
        child: AdditionalAnswersPanel(groups: _additionalAnswerGroups()),
      ),
    );
    await _capture(
      tester,
      collapsedKey,
      '09_child_additional_answers_collapsed.png',
    );

    await tester.tap(find.text('Ergänzende Angaben'));
    await tester.pumpAndSettle();
    await _capture(
      tester,
      collapsedKey,
      '10_child_additional_answers_expanded.png',
    );

    final darkKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: darkKey,
        brightness: Brightness.dark,
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores(), answers: _amphibianSampleAnswers()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    await _capture(tester, darkKey, '02_adult_result_dark.png');

    final legacyKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: legacyKey,
        brightness: Brightness.light,
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

    final gridKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: gridKey,
        brightness: Brightness.light,
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Beispielangabe',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
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

    final inviteKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: inviteKey,
        brightness: Brightness.light,
        child: AdultReflexProfileResultView(
          assessment: _assessment(scores: _sampleScores(), answers: _amphibianSampleAnswers()),
          packageId: 'moro',
          isFirstResultDisplay: false,
        ),
      ),
    );
    await _capture(tester, inviteKey, 'adult_result_invite_placement.png');

    // 5) Progress strip — adult card (no radar) beside child-sized chrome
    final progressKey = GlobalKey();
    final adultSummary = ReflexProfileSummary(
      profile: const ReflexSubjectProfile(
        id: 'adult-1',
        displayName: 'Alex',
        profileType: 'adult_self',
      ),
      latestAssessment: _assessment(
        scores: _sampleScores(),
        answers: _amphibianSampleAnswers(),
      ),
    );
    await tester.pumpWidget(
      _frame(
        key: progressKey,
        brightness: Brightness.light,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reflexprofile',
                style: ThemeData.light(useMaterial3: true)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: AdultProgressProfileCard(
                  summary: adultSummary,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Alex'), findsOneWidget);
    await _capture(tester, progressKey, '05_progress_adult_reflex_card.png');

    // 6) Profile section — view / fill rows
    final profileKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: profileKey,
        brightness: Brightness.light,
        child: ListView(
          padding: const EdgeInsets.all(8),
          children: [
            const ListTile(
              leading: Icon(Icons.person_outline),
              title: Text('Alex'),
              subtitle: Text('Erwachsenenprofil'),
            ),
            SubjectProfileReflexActionTile(
              summary: adultSummary,
              onPressed: () {},
            ),
            const ListTile(
              leading: Icon(Icons.child_care_outlined),
              title: Text('Sam'),
              subtitle: Text('Kinderprofil'),
            ),
            SubjectProfileReflexActionTile(
              summary: const ReflexProfileSummary(
                profile: ReflexSubjectProfile(
                  id: 'child-1',
                  displayName: 'Sam',
                  profileType: 'child',
                ),
              ),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    expect(find.text('Reflexprofil ansehen'), findsOneWidget);
    expect(find.text('Reflexprofil ausfüllen'), findsOneWidget);
    await _capture(tester, profileKey, '06_profile_reflex_actions.png');
  });
}
