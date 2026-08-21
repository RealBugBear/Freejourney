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
  });
}
