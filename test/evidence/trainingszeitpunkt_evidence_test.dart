import 'dart:io';
import 'dart:ui' as ui;

import 'package:corejourney/core/theme/app_colors.dart';
import 'package:corejourney/features/training/presentation/widgets/training_anchor_sheet.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = 'docs/evidence/trainingszeitpunkt';
const _pixelRatio = 2.0;

ThemeData _evidenceTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
    ),
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: 'Poppins'),
  );
}

Widget _frame({
  required GlobalKey key,
  required Widget child,
}) {
  return RepaintBoundary(
    key: key,
    child: ColoredBox(
      color: AppColors.surfaceDark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _evidenceTheme(),
        locale: const Locale('de'),
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
  expect(file.lengthSync(), greaterThan(8000), reason: filename);
}

Future<void> _loadEvidenceFonts() async {
  final configuredRoot = Platform.environment['FLUTTER_ROOT'];
  final flutterRoot = configuredRoot != null && configuredRoot.isNotEmpty
      ? Directory(configuredRoot)
      : Directory(
          File((await Process.run('which', ['flutter'])).stdout.toString().trim())
              .parent
              .parent
              .path,
        );
  final materialFonts = Directory(
    '${flutterRoot.path}/bin/cache/artifacts/material_fonts',
  );
  final roboto = File('${materialFonts.path}/Roboto-Regular.ttf');
  for (final family in const ['Poppins', 'Roboto']) {
    final bytes = await roboto.readAsBytes();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadEvidenceFonts();
  });

  testWidgets('capture training anchor sheet evidence', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final adultKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: adultKey,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTrainingAnchorSheet(
              context,
              isAdultSelf: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _capture(tester, adultKey, '01_anchor_sheet_adult.png');
    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();

    final familyKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: familyKey,
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showTrainingAnchorSheet(
              context,
              isAdultSelf: false,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await _capture(tester, familyKey, '02_anchor_sheet_family.png');
  });
}
