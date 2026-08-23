import 'dart:io';
import 'dart:ui' as ui;

import 'package:corejourney/core/theme/app_colors.dart';
import 'package:corejourney/features/progress/presentation/providers/streak_provider.dart';
import 'package:corejourney/features/progress/presentation/widgets/streak_row.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _out = 'docs/evidence/serie-freischeine';
const _pixelRatio = 2.0;

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

  testWidgets('capture streak evidence screenshots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final view = StreakView(
      length: 4,
      credits: 1,
      trainingDays: {DateTime(2026, 8, 17), DateTime(2026, 8, 18)},
      rescuedDays: {DateTime(2026, 8, 19)},
      newlyRescued: {DateTime(2026, 8, 19)},
    );

    final lightKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: lightKey,
        brightness: Brightness.light,
        child: StreakRow(view: view, today: DateTime(2026, 8, 20)),
      ),
    );
    await _capture(tester, lightKey, '01_streak_row_light.png');

    final darkKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: darkKey,
        brightness: Brightness.dark,
        child: StreakRow(view: view, today: DateTime(2026, 8, 20)),
      ),
    );
    await _capture(tester, darkKey, '02_streak_row_dark.png');

    final pickerKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: pickerKey,
        brightness: Brightness.light,
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in ['Lena', 'Noah'])
                CheckboxListTile(
                  value: true,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(name),
                ),
            ],
          ),
        ),
      ),
    );
    await _capture(tester, pickerKey, '03_joint_training_picker.png');
  });
}
