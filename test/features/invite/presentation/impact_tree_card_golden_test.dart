import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/presentation/widgets/impact_tree_card.dart';
import 'package:corejourney/features/invite/presentation/widgets/impact_tree_painter.dart';
import 'package:corejourney/l10n/app_localizations.dart';

/// Goldens capture the card itself (RepaintBoundary), not empty phone chrome.
const _evidenceRoot = '../../../../docs/evidence/invite-phase3';
const _surfaceKey = ValueKey('invite-tree-surface');

Future<void> _pumpCard(
  WidgetTester tester, {
  required int activatedCount,
  required Brightness brightness,
  double textScale = 1,
  Size surface = const Size(360, 640),
}) async {
  await tester.binding.setSurfaceSize(surface);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF009E6B),
          brightness: brightness,
        ),
        useMaterial3: true,
      ),
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(
          size: surface,
          textScaler: TextScaler.linear(textScale),
          disableAnimations: true,
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: RepaintBoundary(
                key: _surfaceKey,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: ImpactTreeCard(
                    activatedCount: activatedCount,
                    previousActivatedCount: activatedCount,
                    height: 160,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('crown tier densifies only after twelve activations', () {
    expect(ImpactTreeLayout.crownTier(0), 0);
    expect(ImpactTreeLayout.crownTier(12), 0);
    expect(ImpactTreeLayout.crownTier(13), 1);
    expect(ImpactTreeLayout.crownTier(24), 1);
    expect(ImpactTreeLayout.crownTier(25), 2);
    expect(ImpactTreeLayout.crownTier(50), 2);
  });

  // 13 / 25 prove canopy densification after the branch cap.
  for (final count in [0, 1, 5, 12, 13, 25]) {
    for (final brightness in Brightness.values) {
      final mode = brightness == Brightness.dark ? 'dark' : 'light';
      testWidgets('impact tree golden count=$count $mode', (tester) async {
        await _pumpCard(
          tester,
          activatedCount: count,
          brightness: brightness,
        );
        await expectLater(
          find.byKey(_surfaceKey),
          matchesGoldenFile('$_evidenceRoot/tree_${count}_$mode.png'),
        );
      });
    }
  }

  testWidgets('impact tree at 200% text scale does not overflow',
      (tester) async {
    await _pumpCard(
      tester,
      activatedCount: 5,
      brightness: Brightness.light,
      textScale: 2,
      surface: const Size(390, 844),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(ImpactTreeCard), findsOneWidget);
  });
}
