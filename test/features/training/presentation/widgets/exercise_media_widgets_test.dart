import 'dart:async';

import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/presentation/widgets/exercise_image_widget.dart';
import 'package:corejourney/features/training/presentation/widgets/exercise_video_widget.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

Exercise _exercise({
  String imagePath = 'assets/images/does-not-exist.png',
  String? imageUrl,
  String? videoPath,
  String? videoUrl,
}) {
  return Exercise(
    id: 'media_test',
    packageId: 'moro',
    sequenceNumber: 1,
    titleDe: 'Medientest',
    titleEn: 'Media test',
    positionInstructionsDe: const ['Rückenlage'],
    positionInstructionsEn: const ['Lie on your back'],
    movementInstructionsDe: const ['Langsam bewegen'],
    movementInstructionsEn: const ['Move slowly'],
    executionGuideDe: 'Langsam bewegen.',
    executionGuideEn: 'Move slowly.',
    durationSeconds: 20,
    repetitions: 1,
    imagePath: imagePath,
    imageUrl: imageUrl,
    videoPath: videoPath,
    videoUrl: videoUrl,
  );
}

Widget _wrap(
  Widget child, {
  bool reducedMotion = false,
}) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(
          size: const Size(600, 800),
          disableAnimations: reducedMotion,
        ),
        child: SizedBox(
          width: 600,
          height: 800,
          child: child,
        ),
      ),
    ),
  );
}

class _FakeVideoController extends VideoPlayerController {
  _FakeVideoController({this.hangOnInitialize = false})
      : super.networkUrl(Uri.parse('https://example.test/video.mp4'));

  final bool hangOnInitialize;
  final Completer<void> _hangingInitialization = Completer<void>();
  final List<bool> loopingValues = [];
  int initializeCalls = 0;
  int playCalls = 0;
  int pauseCalls = 0;
  bool disposed = false;

  @override
  Future<void> initialize() async {
    initializeCalls++;
    if (hangOnInitialize) {
      await _hangingInitialization.future;
      return;
    }
    value = const VideoPlayerValue(
      duration: Duration(seconds: 12),
      size: Size(16, 9),
      isInitialized: true,
    );
  }

  @override
  Future<void> setLooping(bool looping) async {
    loopingValues.add(looping);
    value = value.copyWith(isLooping: looping);
  }

  @override
  Future<void> play() async {
    playCalls++;
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}

void main() {
  group('ExerciseImageWidget', () {
    testWidgets('missing local image terminates in a controlled fallback',
        (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 240,
            height: 160,
            child: ExerciseImageWidget(exercise: _exercise()),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('exercise-image-fallback')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(find.bySemanticsLabel('Media test'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Media test. Failed to load'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('invalid remote URL safely uses the bundled local image',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 240,
            height: 160,
            child: ExerciseImageWidget(
              exercise: _exercise(
                imagePath:
                    'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_1.png',
                imageUrl: 'not a supported remote URL',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('exercise-image-fallback')),
        findsNothing,
      );
      expect(find.byType(Image), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ExerciseVideoWidget', () {
    testWidgets('remote initialization times out into an honest retry state',
        (tester) async {
      final controller = _FakeVideoController(hangOnInitialize: true);

      await tester.pumpWidget(
        _wrap(
          ExerciseVideoWidget(
            exercise: _exercise(
              videoUrl: 'https://example.test/video.mp4',
            ),
            onReady: () {},
            remoteInitializationTimeout: const Duration(milliseconds: 40),
            networkControllerBuilder: (_) => controller,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(controller.initializeCalls, 1);
      expect(controller.disposed, isTrue);
      expect(
        find.byKey(const ValueKey('exercise-video-error')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
      expect(find.text('Failed to load'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Preparing video...'), findsNothing);
    });

    testWidgets('reduced motion initializes without autoplay or looping',
        (tester) async {
      final controller = _FakeVideoController();

      await tester.pumpWidget(
        _wrap(
          ExerciseVideoWidget(
            exercise: _exercise(
              videoUrl: 'https://example.test/video.mp4',
            ),
            onReady: () {},
            networkControllerBuilder: (_) => controller,
          ),
          reducedMotion: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.loopingValues, [false]);
      expect(controller.playCalls, 0);
      expect(controller.value.isPlaying, isFalse);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.bySemanticsLabel('Video: Start Now'), findsOneWidget);
    });

    testWidgets('standard motion preserves deliberate autoplay and looping',
        (tester) async {
      final controller = _FakeVideoController();

      await tester.pumpWidget(
        _wrap(
          ExerciseVideoWidget(
            exercise: _exercise(
              videoUrl: 'https://example.test/video.mp4',
            ),
            onReady: () {},
            networkControllerBuilder: (_) => controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.loopingValues, [true]);
      expect(controller.playCalls, 1);
      expect(controller.value.isPlaying, isTrue);
      expect(find.bySemanticsLabel('Video: Pause'), findsOneWidget);
    });
    testWidgets('late native playback error exposes fallback and retry',
        (tester) async {
      final controller = _FakeVideoController();
      await tester.pumpWidget(_wrap(ExerciseVideoWidget(
        exercise: _exercise(videoUrl: 'https://example.test/video.mp4'),
        onReady: () {},
        networkControllerBuilder: (_) => controller,
      )));
      await tester.pumpAndSettle();
      controller.value = controller.value
          .copyWith(errorDescription: 'synthetic decoder failure');
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('exercise-video-error')), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(controller.disposed, isTrue);
    });

    testWidgets('hung bundled asset initialization reaches fallback',
        (tester) async {
      final controller = _FakeVideoController(hangOnInitialize: true);
      await tester.pumpWidget(_wrap(ExerciseVideoWidget(
        exercise: _exercise(videoPath: 'assets/videos/test.mp4'),
        onReady: () {},
        assetControllerBuilder: (_) => controller,
        remoteInitializationTimeout: const Duration(milliseconds: 100),
      )));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(
          find.byKey(const ValueKey('exercise-video-error')), findsOneWidget);
      expect(controller.disposed, isTrue);
    });
  });
}
