import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:corejourney/core/navigation/app_router.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/profile/presentation/widgets/subject_profile_reflex_action_tile.dart';
import 'package:corejourney/l10n/app_localizations.dart';

ReflexProfileSummary _summary({ReflexProfileAssessment? assessment}) {
  return ReflexProfileSummary(
    profile: const ReflexSubjectProfile(
      id: 'adult-1',
      displayName: 'Alex',
      profileType: 'adult_self',
    ),
    latestAssessment: assessment,
  );
}

ReflexProfileAssessment _assessment() {
  return ReflexProfileAssessment(
    id: 'a1',
    packageId: 'moro',
    subjectProfileId: 'adult-1',
    questionnaireType: 'adult_self_report',
    questionnaireVersion: 'adult_v3',
    scoringVersion: 'adult_equal_weight_v1',
    status: 'completed',
    answers: const {},
    scores: const {},
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 8, 21),
    createdAt: DateTime(2026, 8, 21),
  );
}

void main() {
  testWidgets('with assessment shows view label and routes to result',
      (tester) async {
    String? pushed;
    Object? extra;
    final router = GoRouter(
      initialLocation: '/start',
      routes: [
        GoRoute(
          path: '/start',
          builder: (_, __) => Scaffold(
            body: SubjectProfileReflexActionTile(
              summary: _summary(assessment: _assessment()),
              onPressed: () {
                pushed = Routes.reflexProfileResult;
                extra = {'assessment': _assessment()};
              },
            ),
          ),
        ),
        GoRoute(
          path: Routes.reflexProfileResult,
          builder: (_, __) => const SizedBox(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    expect(find.text('Reflexprofil ansehen'), findsOneWidget);
    expect(find.text('Reflexprofil ausfüllen'), findsNothing);
    await tester.tap(find.text('Reflexprofil ansehen'));
    await tester.pump();
    expect(pushed, Routes.reflexProfileResult);
    expect(extra, isA<Map>());
  });

  testWidgets('without assessment shows fill label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SubjectProfileReflexActionTile(
            summary: _summary(),
            onPressed: () {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Reflexprofil ausfüllen'), findsOneWidget);
    expect(find.text('Reflexprofil ansehen'), findsNothing);
  });
}
