import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/presentation/widgets/invite_impulse_card.dart';
import 'package:corejourney/l10n/app_localizations.dart';

void main() {
  testWidgets('impulse card is an inline card, not a dialog', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: InviteImpulseCard(onOpen: () => taps++),
        ),
      ),
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('de'));
    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(Card), findsOneWidget);
    expect(find.text(l10n.impulseInviteTitle), findsOneWidget);
    expect(find.text(l10n.impulseInviteBody), findsOneWidget);

    await tester.tap(find.text(l10n.inviteShareAction));
    await tester.pump();
    expect(taps, 1);
  });
}
