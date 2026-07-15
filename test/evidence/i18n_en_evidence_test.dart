import 'dart:io';
import 'dart:ui' as ui;

import 'package:corejourney/bootstrap/providers.dart';
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/core/navigation/app_router.dart';
import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/core/sync/sync_service.dart';
import 'package:corejourney/core/sync/sync_status.dart';
import 'package:corejourney/core/theme/app_colors.dart';
import 'package:corejourney/core/time/app_clock.dart';
import 'package:corejourney/core/time/app_clock_provider.dart';
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/auth/domain/repositories/auth_repository.dart';
import 'package:corejourney/features/auth/presentation/providers/auth_provider.dart';
import 'package:corejourney/features/auth/presentation/screens/login_screen.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';
import 'package:corejourney/features/consent/presentation/providers/consent_provider.dart';
import 'package:corejourney/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:corejourney/features/onboarding/presentation/screens/entry_points_screen.dart';
import 'package:corejourney/features/profile/domain/models/profile.dart';
import 'package:corejourney/features/profile/presentation/providers/profile_provider.dart';
import 'package:corejourney/features/progress/presentation/providers/progress_provider.dart';
import 'package:corejourney/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:corejourney/features/settings/presentation/screens/settings_screen.dart';
import 'package:corejourney/features/trainer/domain/models/appointment.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';
import 'package:corejourney/features/training/presentation/screens/training_intro_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _logicalPhoneSize = Size(390, 844);
const _screenshotPixelRatio = 2.0;
const _outputDirectory = 'docs/evidence/I18N-EN';

class _StubAuthRepository implements AuthRepository {
  @override
  Stream<AuthState> get authStateChanges => Stream.value(
        const AuthState(AuthChangeEvent.initialSession, null),
      );

  @override
  User? get currentUser => null;

  @override
  Future<void> sendPasswordReset({required String email, String? redirectTo}) {
    return Future.value();
  }

  @override
  Future<void> signInWithApple() => Future.value();

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) {
    return Future.value();
  }

  @override
  Future<void> signInWithGoogle() => Future.value();

  @override
  Future<void> signOut() => Future.value();

  @override
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return false;
  }

  @override
  Future<void> updatePassword({required String newPassword}) {
    return Future.value();
  }
}

class _EvidenceProfileNotifier extends ProfileNotifier {
  @override
  Future<Profile?> build() async => const Profile(
        userId: 'local-evidence-user',
        displayName: 'Evidence User',
      );
}

class _FixedAppClock extends AppClock {
  _FixedAppClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _EvidenceDependencies {
  _EvidenceDependencies({
    required this.prefs,
    required this.database,
    required this.syncService,
    required this.settings,
  });

  final SharedPreferences prefs;
  final AppDatabase database;
  final SyncService syncService;
  final SettingsNotifier settings;

  static Future<_EvidenceDependencies> create(
    Map<String, Object> initialPreferences,
  ) async {
    SharedPreferences.setMockInitialValues(initialPreferences);
    final prefs = await SharedPreferences.getInstance();
    final database = AppDatabase.inMemory();
    return _EvidenceDependencies(
      prefs: prefs,
      database: database,
      syncService: SyncService(database),
      settings: SettingsNotifier(prefs, null),
    );
  }

  Future<void> dispose() async {
    syncService.stop();
    await database.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://i18n-evidence.invalid',
      anonKey: 'local-evidence-anon-key',
      debug: false,
    );
    await _loadEvidenceFonts();
  });

  testWidgets(
    'first launch: choosing English before login previews, persists, and routes',
    (tester) async {
      await _usePhoneSurface(tester);
      tester.binding.platformDispatcher.localeTestValue = const Locale('de');
      addTearDown(
        tester.binding.platformDispatcher.clearLocaleTestValue,
      );

      final dependencies = await _EvidenceDependencies.create({});
      addTearDown(dependencies.dispose);
      final captureKey = GlobalKey();
      final router = GoRouter(
        initialLocation: Routes.languageSelection,
        routes: [
          GoRoute(
            path: Routes.languageSelection,
            builder: (_, __) => const LanguageSelectionScreen(),
          ),
          GoRoute(
            path: Routes.login,
            builder: (_, __) => const LoginScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        _captureFrame(
          captureKey,
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
              settingsProvider.overrideWith((_) => dependencies.settings),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp.router(
                debugShowCheckedModeBanner: false,
                theme: _evidenceTheme(),
                locale: ref.watch(localeProvider),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                routerConfig: router,
              ),
            ),
          ),
        ),
      );
      await _pumpStable(tester);

      final languageScreenContext =
          tester.element(find.byType(LanguageSelectionScreen));
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/brand/free.png'),
          languageScreenContext,
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(RawImage), findsOneWidget);
      expect(
        tester.renderObject<RenderImage>(find.byType(RawImage)).image,
        isNotNull,
        reason: 'The real brand asset must be decoded before evidence capture.',
      );

      expect(find.text('Sprache wählen'), findsOneWidget);
      expect(dependencies.settings.state.hasSelectedLanguage, isFalse);
      expect(
        dependencies.prefs.containsKey(languagePreferenceKey),
        isFalse,
      );

      await tester.tap(find.text('English'));
      await tester.pump();

      expect(find.text('Choose your language'), findsOneWidget);
      expect(
        find.text('You can change this later in Settings.'),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      expect(
        dependencies.prefs.containsKey(languagePreferenceKey),
        isFalse,
        reason: 'The first-launch preview must not persist before Continue.',
      );
      _expectNoFlutterException(tester);
      await _captureScreenshot(
        tester,
        captureKey,
        '01_first_launch_choose_english.png',
      );

      await tester.tap(find.text('Continue'));
      await _pumpStable(tester);

      expect(dependencies.prefs.getString(languagePreferenceKey), 'en');
      expect(dependencies.settings.state.hasSelectedLanguage, isTrue);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('🇩🇪 Deutsch'), findsOneWidget);
      expect(find.text('🇬🇧 English'), findsOneWidget);
      expect(find.text('Anmelden'), findsNothing);
      _expectNoFlutterException(tester);
      await _captureScreenshot(
        tester,
        captureKey,
        '02_first_launch_login_english.png',
      );
    },
  );

  testWidgets(
    'running app: Settings to English updates the whole screen immediately',
    (tester) async {
      await _usePhoneSurface(tester);
      final dependencies = await _EvidenceDependencies.create({
        languagePreferenceKey: 'de',
      });
      addTearDown(dependencies.dispose);
      final captureKey = GlobalKey();

      await tester.pumpWidget(
        _captureFrame(
          captureKey,
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
              sharedPreferencesProvider.overrideWithValue(dependencies.prefs),
              databaseProvider.overrideWithValue(dependencies.database),
              syncServiceProvider.overrideWithValue(dependencies.syncService),
              syncStatusProvider.overrideWith(
                (_) => Stream.value(const SyncStatus()),
              ),
              settingsProvider.overrideWith((_) => dependencies.settings),
              activeEnrollmentProvider.overrideWith(
                (_) => Stream<EnrollmentsTableData?>.value(null),
              ),
              moroCompletedProvider.overrideWithValue(false),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: _evidenceTheme(),
                locale: ref.watch(localeProvider),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: const SettingsScreen(),
              ),
            ),
          ),
        ),
      );
      await _pumpStable(tester);

      expect(find.text('Einstellungen'), findsOneWidget);
      await tester.tap(find.text('English'));
      await _pumpStable(tester);

      expect(dependencies.prefs.getString(languagePreferenceKey), 'en');
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('SESSIONS'), findsOneWidget);
      expect(find.text('REMINDERS'), findsOneWidget);
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Einstellungen'), findsNothing);
      final languageSelector = tester.widget<SegmentedButton<String>>(
        find.byWidgetPredicate(
          (widget) => widget is SegmentedButton<String>,
        ),
      );
      expect(languageSelector.selected, {'en'});
      _expectNoFlutterException(tester);
      await _captureScreenshot(
        tester,
        captureKey,
        '03_settings_after_switch_english.png',
      );
    },
  );

  testWidgets(
      'representative onboarding screen renders English without overflow',
      (tester) async {
    await _usePhoneSurface(tester);
    final dependencies = await _EvidenceDependencies.create({
      languagePreferenceKey: 'en',
    });
    addTearDown(dependencies.dispose);
    final captureKey = GlobalKey();

    await tester.pumpWidget(
      _captureFrame(
        captureKey,
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
            settingsProvider.overrideWith((_) => dependencies.settings),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _evidenceTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const EntryPointsScreen(),
          ),
        ),
      ),
    );
    await _pumpStable(tester);

    expect(find.text('Many Paths Lead Here'), findsOneWidget);
    expect(find.text('Body & Tension'), findsOneWidget);
    await tester.tap(find.text('Body & Tension'));
    await _pumpStable(tester);
    expect(find.textContaining('Active reflex patterns can keep muscles'),
        findsOneWidget);
    expect(find.text('Less ↑'), findsOneWidget);
    expect(find.text('More ↓'), findsNWidgets(4));
    expect(find.text('Viele Wege führen hierher'), findsNothing);
    _expectNoFlutterException(tester);
    await _captureScreenshot(
      tester,
      captureKey,
      '04_onboarding_english.png',
    );
  });

  testWidgets('representative dashboard renders deterministic English state',
      (tester) async {
    await _usePhoneSurface(tester);
    final dependencies = await _EvidenceDependencies.create({
      languagePreferenceKey: 'en',
      'routine_tip_shown': true,
    });
    addTearDown(dependencies.dispose);
    final captureKey = GlobalKey();
    const subjectProfile = ReflexSubjectProfile(
      id: 'local-profile',
      displayName: 'Sam',
      profileType: 'child',
      ageYears: 8,
    );

    await tester.pumpWidget(
      _captureFrame(
        captureKey,
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_StubAuthRepository()),
            sharedPreferencesProvider.overrideWithValue(dependencies.prefs),
            databaseProvider.overrideWithValue(dependencies.database),
            syncServiceProvider.overrideWithValue(dependencies.syncService),
            settingsProvider.overrideWith((_) => dependencies.settings),
            hasSeenAnalysisPlaceholderProvider.overrideWith((_) async => true),
            hasConsentedProvider.overrideWith((_) async => true),
            profileProvider.overrideWith(_EvidenceProfileNotifier.new),
            allReflexSubjectProfilesProvider.overrideWith(
              (_) async => const [subjectProfile],
            ),
            activeEnrollmentProvider.overrideWith(
              (_) => Stream<EnrollmentsTableData?>.value(null),
            ),
            activeProgressProvider.overrideWith(
              (_) => Stream<ProgressEntriesTableData?>.value(null),
            ),
            thisWeekSessionsProvider.overrideWith(
              (_) => Stream<List<TrainingSessionsTableData>>.value(const []),
            ),
            todayVorrundeSessionProvider.overrideWith(
              (_) => Stream<bool>.value(false),
            ),
            traineeProposalsProvider.overrideWith(
              (_) async => const <Appointment>[],
            ),
            unreadDmCountProvider.overrideWithValue(0),
            appClockProvider.overrideWith(
              (_) => _FixedAppClock(DateTime(2026, 7, 15, 12)),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _evidenceTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const DashboardScreen(),
          ),
        ),
      ),
    );
    await _pumpStable(tester);

    expect(find.text('Sam'), findsOneWidget);
    expect(find.text('No Active Package Yet'), findsOneWidget);
    expect(find.text('Start Package'), findsOneWidget);
    expect(find.text('Noch kein aktives Paket'), findsNothing);
    _expectNoFlutterException(tester);
    await _captureScreenshot(
      tester,
      captureKey,
      '05_dashboard_english.png',
    );
  });

  testWidgets('representative training intro renders English without overflow',
      (tester) async {
    await _usePhoneSurface(tester);
    final captureKey = GlobalKey();

    await tester.pumpWidget(
      _captureFrame(
        captureKey,
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _evidenceTheme(),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: TrainingIntroScreen(onStart: () {}),
        ),
      ),
    );
    await _pumpStable(tester);

    expect(find.text('Welcome to Your Session'), findsOneWidget);
    expect(
      find.text("Today, you'll practice seven movements at a calm pace."),
      findsOneWidget,
    );
    expect(find.text('Start Session'), findsOneWidget);
    expect(find.text('Willkommen zu deiner Einheit'), findsNothing);
    _expectNoFlutterException(tester);
    await _captureScreenshot(
      tester,
      captureKey,
      '06_training_english.png',
    );
  });
}

Widget _captureFrame(GlobalKey key, Widget child) {
  return RepaintBoundary(
    key: key,
    child: ColoredBox(
      color: Colors.white,
      child: child,
    ),
  );
}

Future<void> _usePhoneSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(_logicalPhoneSize);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Future<void> _pumpStable(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 650));
}

Future<void> _captureScreenshot(
  WidgetTester tester,
  GlobalKey captureKey,
  String filename,
) async {
  await tester.pump();
  _replaceTestFontFallbacks();
  await tester.pump();
  _expectNoFlutterException(tester);
  final boundary =
      captureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final file = File('$_outputDirectory/$filename');
  final result = await tester.runAsync(() async {
    final image = await boundary.toImage(
      pixelRatio: _screenshotPixelRatio,
    );
    final pngBytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final rgbaBytes =
        await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final bytes = pngBytes!.buffer.asUint8List();
    final rgba = rgbaBytes!.buffer.asUint8List();
    int pixelAt(int x, int y) {
      final offset = (y * image.width + x) * 4;
      return (rgba[offset] << 24) |
          (rgba[offset + 1] << 16) |
          (rgba[offset + 2] << 8) |
          rgba[offset + 3];
    }

    final cornerPixels = [
      pixelAt(0, 0),
      pixelAt(image.width - 1, 0),
      pixelAt(0, image.height - 1),
      pixelAt(image.width - 1, image.height - 1),
    ];
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    final exists = await file.exists();
    final dimensions = (width: image.width, height: image.height);
    image.dispose();
    return (
      dimensions: dimensions,
      byteCount: bytes.length,
      exists: exists,
      cornerPixels: cornerPixels,
    );
  });

  expect(result!.dimensions.width, 780);
  expect(result.dimensions.height, 1688);
  expect(result.byteCount, greaterThan(10000));
  expect(result.exists, isTrue);
  expect(
    result.cornerPixels,
    everyElement(
      allOf(
        predicate<int>((pixel) => pixel & 0xFF == 0xFF),
        predicate<int>((pixel) => pixel >> 8 != 0),
      ),
    ),
    reason: 'Evidence PNG edges must be opaque and must not render black.',
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
  final text = span.text
      ?.replaceAll('🇩🇪 ', '')
      .replaceAll('🇬🇧 ', '')
      .replaceAll(' ↑', '')
      .replaceAll(' ↓', '');
  return TextSpan(
    text: text,
    children: span.children?.map(_withEvidenceFont).toList(),
    style: style.copyWith(
      fontFamily: style.fontFamily ?? 'Poppins',
    ),
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

void _expectNoFlutterException(WidgetTester tester) {
  expect(
    tester.takeException(),
    isNull,
    reason:
        'The rendered screen must not throw, including RenderFlex overflow.',
  );
}

ThemeData _evidenceTheme() {
  final base = ThemeData.light(useMaterial3: true);
  final colors = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(onPrimary: AppColors.textPrimary);
  final textTheme = base.textTheme.apply(
    fontFamily: 'Poppins',
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  );
  const buttonTextStyle = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: buttonTextStyle,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        textStyle: buttonTextStyle,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight1,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider),
  );
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
  final executable = File((which.stdout as String).trim());
  final resolved = File(await executable.resolveSymbolicLinks());
  return resolved.parent.parent;
}

Future<void> _loadFont({
  required String family,
  required File file,
}) async {
  if (!await file.exists()) {
    throw StateError('Evidence font missing: ${file.path}');
  }
  final bytes = await file.readAsBytes();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.sublistView(bytes)));
  await loader.load();
}
