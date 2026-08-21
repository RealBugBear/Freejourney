import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/presentation/widgets/impact_tree_card.dart';
import 'package:corejourney/l10n/app_localizations.dart';

void main() {
  testWidgets('impact tree card exposes a single aggregated semantics label',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ImpactTreeCard(
            activatedCount: 1,
            previousActivatedCount: 1,
            height: 140,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ImpactTreeCard)),
    );
    final expected = l10n.inviteTreeSemantics(1);
    final headline = l10n.inviteTreeHeadline(1);

    expect(find.bySemanticsLabel(expected), findsOneWidget);
    expect(
      find.bySemanticsLabel(headline),
      findsNothing,
      reason: 'excludeSemantics must hide the visible headline from AT',
    );
    expect(tester.getSemantics(find.byType(ImpactTreeCard)).label, expected);
  });

  testWidgets('empty tree semantics includes headline and empty hint',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: ImpactTreeCard(
            activatedCount: 0,
            previousActivatedCount: 0,
            height: 140,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ImpactTreeCard)),
    );
    final expected =
        '${l10n.inviteTreeHeadlineZero}. ${l10n.inviteTreeEmptyHint}';

    expect(find.bySemanticsLabel(expected), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(ImpactTreeCard)).label,
      expected,
    );
    expect(
      expected.contains(l10n.inviteTreeEmptyHint),
      isTrue,
      reason: 'AT must hear that a branch grows after first training',
    );
  });
}
