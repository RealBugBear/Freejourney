import 'package:flutter/services.dart';

import '../../../../core/training/training_feedback_settings.dart';

/// Provides the legacy haptic facade used by older training surfaces.
/// Create once per training session, call [init], and dispose when done.
///
/// Runtime voice guidance is deliberately limited to pre-recorded,
/// manifest-gated assets handled by AudioAnnouncementService. This class does
/// not synthesize speech and must not be used as a TTS fallback.
class TrainingFeedbackService {
  final TrainingFeedbackMode mode;
  final String locale;

  bool _initialized = false;

  TrainingFeedbackService({required this.mode, required this.locale});

  TrainingFeedbackPolicy get policy => mode.policy;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// Legacy no-op. Speech may only come from approved recorded assets.
  Future<void> speak(String phrase) async {
    if (!policy.allowsVoice) return;
  }

  /// Light haptic tap — used for phase transitions.
  void hapticLight() {
    if (!policy.allowsHaptics) return;
    HapticFeedback.lightImpact();
  }

  /// Medium haptic — used for rep completions.
  void hapticMedium() {
    if (!policy.allowsHaptics) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic — used for session start / all reps complete.
  void hapticHeavy() {
    if (!policy.allowsHaptics) return;
    HapticFeedback.heavyImpact();
  }

  Future<void> dispose() async {}
}
