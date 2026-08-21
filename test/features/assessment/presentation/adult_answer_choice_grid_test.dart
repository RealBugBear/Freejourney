import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/widgets/adult_answer_choice_grid.dart';
import 'package:corejourney/l10n/app_localizations.dart';

void main() {
  testWidgets('adult answer grid exposes semantics on all four choices',
      (tester) async {
    ReflexAnswerChoice? selected;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: AdultAnswerChoiceGrid(
            value: null,
            onSelected: (choice) => selected = choice,
            yesLabel: 'Yes',
            noLabel: 'No',
            unknownLabel: "I don't know",
            notApplicableLabel: 'Not applicable',
          ),
        ),
      ),
    );

    for (final label in [
      'Yes',
      'No',
      "I don't know",
      'Not applicable',
    ]) {
      final node = tester.getSemantics(find.text(label));
      expect(node.label, label);
      expect(node.hasFlag(SemanticsFlag.isButton), isTrue);
    }

    await tester.tap(find.text('Not applicable'));
    expect(selected, ReflexAnswerChoice.notApplicable);
  });

  testWidgets('changing choice keeps prior answers when rebuilding',
      (tester) async {
    final answers = <String, ReflexAnswerValue>{
      's035': const ReflexAnswerValue(yesNoUnknown: true),
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  AdultAnswerChoiceGrid(
                    value: answers['s035'],
                    onSelected: (choice) {
                      setState(() {
                        answers['s035'] = ReflexAnswerValue.fromChoice(choice);
                      });
                    },
                    yesLabel: 'Yes',
                    noLabel: 'No',
                    unknownLabel: '?',
                    notApplicableLabel: 'n/a',
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        answers['other'] =
                            const ReflexAnswerValue(yesNoUnknown: false);
                      });
                    },
                    child: const Text('next-module-sim'),
                  ),
                  Text(answers['s035']?.choice?.name ?? 'none'),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('yes'), findsOneWidget);
    await tester.tap(find.text('next-module-sim'));
    await tester.pump();
    expect(answers['s035']!.choice, ReflexAnswerChoice.yes);
    expect(find.text('yes'), findsOneWidget);
  });
}
