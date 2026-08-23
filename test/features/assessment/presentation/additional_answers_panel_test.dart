import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';
import 'package:corejourney/features/assessment/presentation/widgets/additional_answers_panel.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';

/// Built here rather than taken from the catalog: the panel only renders what
/// it is handed, so the test stays independent of questionnaire content.
const _question = ReflexQuestion(
  id: 'q-note',
  number: 1,
  module: ReflexQuestionModule.behaviorEmotion,
  textDe: 'Gibt es sonst etwas, das euch auffaellt?',
  textEn: 'Is there anything else you notice?',
  answerType: ReflexAnswerType.freeText,
  role: ReflexQuestionRole.context,
);

Widget _harness(Widget child) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.light(useMaterial3: true),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  const noteText = 'Schläft seit dem Umzug schlecht';

  List<(ReflexQuestionModule, List<RelevantAnswerItem>)> groups() {
    return [
      (
        _question.module,
        [
          const RelevantAnswerItem(
            question: _question,
            selectedOptionLabels: const [],
            freeText: noteText,
          ),
        ],
      ),
    ];
  }

  testWidgets('additional answers start collapsed', (tester) async {
    await tester.pumpWidget(_harness(AdditionalAnswersPanel(groups: groups())));
    await tester.pump();

    expect(
      find.text(AppLocalizationsDe().reflexResultAdditionalInfo),
      findsOneWidget,
    );
    expect(find.textContaining(noteText), findsNothing);
  });

  testWidgets('tapping the title reveals the entries', (tester) async {
    await tester.pumpWidget(_harness(AdditionalAnswersPanel(groups: groups())));
    await tester.pump();

    await tester.tap(find.text(AppLocalizationsDe().reflexResultAdditionalInfo));
    await tester.pumpAndSettle();

    expect(find.textContaining(noteText), findsOneWidget);
  });

  testWidgets('empty state stays behind the collapsed title', (tester) async {
    await tester.pumpWidget(
      _harness(const AdditionalAnswersPanel(groups: [])),
    );
    await tester.pump();

    expect(find.text(AppLocalizationsDe().reflexResultNoAdditional), findsNothing);

    await tester.tap(find.text(AppLocalizationsDe().reflexResultAdditionalInfo));
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsDe().reflexResultNoAdditional),
      findsOneWidget,
    );
  });
}
