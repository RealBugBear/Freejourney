import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import 'exercise_image_widget.dart';

class ExerciseVideoWidget extends StatefulWidget {
  final Exercise exercise;
  final VoidCallback onReady;

  const ExerciseVideoWidget({
    super.key,
    required this.exercise,
    required this.onReady,
  });

  @override
  State<ExerciseVideoWidget> createState() => _ExerciseVideoWidgetState();
}

class _ExerciseVideoWidgetState extends State<ExerciseVideoWidget> {
  VideoPlayerController? _controller;
  bool _videoFailed = false;
  bool _initialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final videoUrl = widget.exercise.videoUrl; // already normalized by model
    final videoPath = widget.exercise.videoPath;

    if (videoUrl == null && videoPath == null) {
      setState(() => _videoFailed = true);
      return;
    }

    VideoPlayerController? controller;

    // 1. Try remote URL first.
    if (videoUrl != null) {
      final c = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      try {
        await c.initialize();
        controller = c;
      } catch (_) {
        await c.dispose();
      }
    }

    // 2. Fall back to bundled asset if network failed or no URL.
    if (controller == null && videoPath != null) {
      final c = VideoPlayerController.asset(videoPath);
      try {
        await c.initialize();
        controller = c;
      } catch (_) {
        await c.dispose();
      }
    }

    if (controller == null) {
      if (mounted) setState(() => _videoFailed = true);
      return;
    }

    controller.setLooping(true);

    if (!mounted) {
      controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _initialized = true;
    });

    controller.play();
    setState(() => _isPlaying = true);
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _isPlaying = false;
      } else {
        controller.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
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
      return _FallbackImage(exercise: widget.exercise);
    }

    if (!_initialized || _controller == null) {
      return Stack(
        alignment: Alignment.center,
        children: [
          ExerciseImageWidget(exercise: widget.exercise, fit: BoxFit.cover),
          Container(color: Colors.black54),
          const CircularProgressIndicator(color: AppColors.primary),
        ],
      );
    }

    return GestureDetector(
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
            duration: const Duration(milliseconds: 300),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(16),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
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
    );
  }
}

class _FallbackImage extends StatelessWidget {
  final Exercise exercise;
  const _FallbackImage({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        ExerciseImageWidget(exercise: exercise, fit: BoxFit.contain),
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
        Positioned(
          bottom: 16,
          child: Text(
            l10n.trainingVideoPreparing,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      ],
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
