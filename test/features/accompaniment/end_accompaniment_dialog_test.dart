import 'package:corejourney/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required void Function(bool?) onResult}) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async =>
              onResult(await showEndAccompanimentDialog(context)),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('names all three consequences before confirming',
      (tester) async {
    await tester.pumpWidget(_host(onResult: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Begleitung wirklich beenden?'), findsOneWidget);
    expect(
      find.text('Dein Trainer kann deine Reflexprofile nicht mehr sehen.'),
      findsOneWidget,
    );
    expect(find.textContaining('keine Nachrichten mehr schreiben'),
        findsOneWidget);
    expect(find.text('Alle offenen Termine werden abgesagt.'), findsOneWidget);
    expect(find.text('Dein Trainer wird darüber informiert.'), findsOneWidget);
  });

  testWidgets('cancelling returns a non-confirming result', (tester) async {
    bool? result = true;
    await tester.pumpWidget(_host(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result, isNot(true));
  });

  testWidgets('confirming returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(_host(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('end_accompaniment_confirm')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
