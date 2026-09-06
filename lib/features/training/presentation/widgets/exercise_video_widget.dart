import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import 'exercise_image_widget.dart';

typedef NetworkVideoControllerBuilder = VideoPlayerController Function(Uri uri);
typedef AssetVideoControllerBuilder = VideoPlayerController Function(
  String assetPath,
);

class ExerciseVideoWidget extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onReady;
  final Duration remoteInitializationTimeout;

  /// Injectable seams keep timeout and playback policy tests independent of a
  /// native video backend.
  final NetworkVideoControllerBuilder? networkControllerBuilder;
  final AssetVideoControllerBuilder? assetControllerBuilder;

  const ExerciseVideoWidget({
    super.key,
    required this.exercise,
    required this.onReady,
    this.remoteInitializationTimeout = const Duration(seconds: 8),
    this.networkControllerBuilder,
    this.assetControllerBuilder,
  }) : assert(remoteInitializationTimeout > Duration.zero);

  @override
  State<ExerciseVideoWidget> createState() => _ExerciseVideoWidgetState();
}

class _ExerciseVideoWidgetState extends State<ExerciseVideoWidget> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _initializationStarted = false;
  bool _reducedMotion = false;
  int _loadAttempt = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final shouldReduceMotion = mediaQuery?.disableAnimations == true ||
        mediaQuery?.accessibleNavigation == true;
    final preferenceChanged = shouldReduceMotion != _reducedMotion;
    _reducedMotion = shouldReduceMotion;

    if (!_initializationStarted) {
      _initializationStarted = true;
      unawaited(_initVideo());
    } else if (preferenceChanged) {
      unawaited(_applyMotionPreference());
    }
  }

  @override
  void didUpdateWidget(covariant ExerciseVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sourceChanged =
        oldWidget.exercise.videoUrl != widget.exercise.videoUrl ||
            oldWidget.exercise.videoPath != widget.exercise.videoPath;
    if (sourceChanged) {
      _retryVideo();
    }
  }

  Future<void> _initVideo() async {
    final attempt = ++_loadAttempt;
    final videoUrl = widget.exercise.videoUrl; // already normalized by model
    final videoPath = widget.exercise.videoPath;

    if (videoUrl == null && videoPath == null) {
      _setFailed(attempt);
      return;
    }

    VideoPlayerController? controller;

    // 1. Try remote URL first.
    final remoteUri = videoUrl == null ? null : Uri.tryParse(videoUrl);
    final hasValidRemoteUri = remoteUri != null &&
        (remoteUri.scheme == 'https' || remoteUri.scheme == 'http') &&
        remoteUri.host.isNotEmpty;
    if (hasValidRemoteUri) {
      final builder = widget.networkControllerBuilder;
      final candidate = builder == null
          ? VideoPlayerController.networkUrl(remoteUri)
          : builder(remoteUri);
      try {
        await candidate
            .initialize()
            .timeout(widget.remoteInitializationTimeout);
        if (_isCurrentAttempt(attempt)) {
          controller = candidate;
        } else {
          unawaited(_disposeQuietly(candidate));
          return;
        }
      } on Object {
        unawaited(_disposeQuietly(candidate));
      }
    }

    // 2. Fall back to bundled asset if network failed or no URL.
    if (controller == null && videoPath != null) {
      final builder = widget.assetControllerBuilder;
      final candidate = builder == null
          ? VideoPlayerController.asset(videoPath)
          : builder(videoPath);
      try {
        await candidate
            .initialize()
            .timeout(widget.remoteInitializationTimeout);
        if (_isCurrentAttempt(attempt)) {
          controller = candidate;
        } else {
          unawaited(_disposeQuietly(candidate));
          return;
        }
      } on Object {
        unawaited(_disposeQuietly(candidate));
      }
    }

    if (controller == null) {
      _setFailed(attempt);
      return;
    }

    if (!_isCurrentAttempt(attempt)) {
      unawaited(_disposeQuietly(controller));
      return;
    }

    try {
      await controller.setLooping(!_reducedMotion);
      if (!_reducedMotion) {
        await controller.play();
      }
    } on Object {
      unawaited(_disposeQuietly(controller));
      _setFailed(attempt);
      return;
    }

    if (!_isCurrentAttempt(attempt)) {
      unawaited(_disposeQuietly(controller));
      return;
    }

    setState(() {
      _controller = controller;
      _initialized = true;
      _videoFailed = false;
      _isPlaying = controller!.value.isPlaying;
    });
    controller.addListener(_onControllerChanged);
    _onControllerChanged();
  }

  void _onControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) return;
    if (controller.value.hasError) {
      _failActiveController();
    } else if (_isPlaying != controller.value.isPlaying) {
      setState(() => _isPlaying = controller.value.isPlaying);
    }
  }

  Future<void> _togglePlay() async {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (controller.value.isPlaying) {
        await controller.pause();
      } else {
        await controller.setLooping(!_reducedMotion);
        await controller.play();
      }
    } on Object {
      _failActiveController();
      return;
    }
    if (!mounted) return;
    setState(() => _isPlaying = controller.value.isPlaying);
  }

  Future<void> _applyMotionPreference() async {
    final controller = _controller;
    if (controller == null || !_initialized) return;
    try {
      await controller.setLooping(!_reducedMotion);
      if (_reducedMotion && controller.value.isPlaying) {
        await controller.pause();
      }
    } on Object {
      _failActiveController();
      return;
    }
    if (!mounted) return;
    setState(() => _isPlaying = controller.value.isPlaying);
  }

  void _retryVideo() {
    final previous = _controller;
    _controller = null;
    _loadAttempt++;
    if (previous != null) unawaited(_disposeQuietly(previous));
    if (mounted) {
      setState(() {
        _videoFailed = false;
        _initialized = false;
        _isPlaying = false;
      });
    }
    unawaited(_initVideo());
  }

  bool _isCurrentAttempt(int attempt) => mounted && attempt == _loadAttempt;

  void _setFailed(int attempt) {
    if (!_isCurrentAttempt(attempt)) return;
    setState(() {
      _videoFailed = true;
      _initialized = false;
      _isPlaying = false;
    });
  }

  void _failActiveController() {
    final failed = _controller;
    _controller = null;
    _loadAttempt++;
    if (failed != null) unawaited(_disposeQuietly(failed));
    if (!mounted) return;
    setState(() {
      _videoFailed = true;
      _initialized = false;
      _isPlaying = false;
    });
  }

  Future<void> _disposeQuietly(VideoPlayerController controller) async {
    controller.removeListener(_onControllerChanged);
    try {
      await controller.dispose();
    } on Object {
      // Cleanup must never replace the user-facing media state with an error.
    }
  }

  @override
  void dispose() {
    _loadAttempt++;
    final controller = _controller;
    if (controller != null) unawaited(_disposeQuietly(controller));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StepLabel(label: l10n.trainingVideo),
          const SizedBox(height: 16),
          Text(
            widget.exercise.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildVideoArea(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onReady,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
            ),
            child: Text(l10n.next,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoArea() {
    final hasVideo =
        widget.exercise.videoUrl != null || widget.exercise.videoPath != null;

    if (_videoFailed || !hasVideo) {
      return _FallbackImage(
        exercise: widget.exercise,
        onRetry: hasVideo ? _retryVideo : null,
      );
    }

    if (!_initialized || _controller == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ExerciseImageWidget(exercise: widget.exercise, fit: BoxFit.cover),
          Container(color: AppColors.backgroundDark.withValues(alpha: .72)),
          const CircularProgressIndicator(color: AppColors.primary),
          Positioned(
            bottom: 16,
            child: Text(
              AppLocalizations.of(context).trainingVideoPreparing,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 13,
              ),
            ),
          ),
        ],
      );
    }

    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label:
          '${l10n.trainingVideo}: ${_isPlaying ? l10n.trainingPause : l10n.trainingStartNow}',
      onTap: _togglePlay,
      child: GestureDetector(
        excludeFromSemantics: true,
        onTap: _togglePlay,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0,
              duration: _reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withValues(alpha: .64),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(16),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.textPrimaryDark,
                  size: 48,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primary,
                  backgroundColor: Colors.white24,
                  bufferedColor: Colors.white38,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onRetry;

  const _FallbackImage({
    required this.exercise,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final errorLabel = '${l10n.trainingVideo}: ${l10n.errorLoadFailedInline}';
    return Semantics(
      key: const ValueKey('exercise-video-error'),
      container: true,
      liveRegion: true,
      label: errorLabel,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExerciseImageWidget(exercise: exercise, fit: BoxFit.contain),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundDark.withValues(alpha: .82),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: AppColors.textSecondaryDark,
                size: 52,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.errorLoadFailedInline,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StepLabel extends StatelessWidget {
  final String label;
  const _StepLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
