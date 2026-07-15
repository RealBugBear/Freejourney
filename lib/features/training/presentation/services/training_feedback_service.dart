import 'package:flutter/services.dart';

import '../../../../core/settings/settings_provider.dart';

/// Provides haptic and TTS feedback during training sessions.
/// Create once per training session, call [init], and dispose when done.
// TTS (flutter_tts) is temporarily disabled — crashes on iOS 26.2.1.
// voiceCues mode will behave like hapticOnly until re-enabled.
class TrainingFeedbackService {
  final TrainingFeedbackMode mode;
  final String locale;

  bool _initialized = false;

  TrainingFeedbackService({required this.mode, required this.locale});

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    // TTS disabled (flutter_tts removed for iOS 26 compatibility diagnosis)
  }

  /// Speak a phrase (no-op — TTS temporarily disabled).
  Future<void> speak(String phrase) async {
    // TTS disabled
  }

  /// Light haptic tap — used for phase transitions.
  void hapticLight() {
    if (mode == TrainingFeedbackMode.silent) return;
    HapticFeedback.lightImpact();
  }

  /// Medium haptic — used for rep completions.
  void hapticMedium() {
    if (mode == TrainingFeedbackMode.silent) return;
    HapticFeedback.mediumImpact();
  }

  /// Heavy haptic — used for session start / all reps complete.
  void hapticHeavy() {
    if (mode == TrainingFeedbackMode.silent) return;
    HapticFeedback.heavyImpact();
  }

  Future<void> dispose() async {
    // TTS disabled
  }
}
