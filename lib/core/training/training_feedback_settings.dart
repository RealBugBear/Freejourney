import 'package:shared_preferences/shared_preferences.dart';

enum TrainingFeedbackMode {
  silent,
  hapticOnly,
  voiceAndCues,
}

/// The production contract for every feedback channel used during training.
///
/// Consumers must ask this policy instead of deriving behaviour from enum
/// comparisons. In particular, [TrainingFeedbackMode.silent] is a true
/// all-channel mute and [TrainingFeedbackMode.hapticOnly] never permits audio.
class TrainingFeedbackPolicy {
  final bool allowsVoice;
  final bool allowsTones;
  final bool allowsMusic;
  final bool allowsHaptics;

  const TrainingFeedbackPolicy({
    required this.allowsVoice,
    required this.allowsTones,
    required this.allowsMusic,
    required this.allowsHaptics,
  });

  static const Map<TrainingFeedbackMode, TrainingFeedbackPolicy> matrix = {
    TrainingFeedbackMode.silent: TrainingFeedbackPolicy(
      allowsVoice: false,
      allowsTones: false,
      allowsMusic: false,
      allowsHaptics: false,
    ),
    TrainingFeedbackMode.hapticOnly: TrainingFeedbackPolicy(
      allowsVoice: false,
      allowsTones: false,
      allowsMusic: false,
      allowsHaptics: true,
    ),
    TrainingFeedbackMode.voiceAndCues: TrainingFeedbackPolicy(
      allowsVoice: true,
      allowsTones: true,
      allowsMusic: true,
      allowsHaptics: true,
    ),
  };

  static TrainingFeedbackPolicy forMode(TrainingFeedbackMode mode) {
    return matrix[mode]!;
  }
}

extension TrainingFeedbackModePolicy on TrainingFeedbackMode {
  TrainingFeedbackPolicy get policy => TrainingFeedbackPolicy.forMode(this);
}

enum TrainingVoicePreset {
  calm,
  neutral,
  dynamic,
}

class TrainingFeedbackSettings {
  /// The only supported persistence key and format for the feedback mode.
  ///
  /// Values are the canonical [TrainingFeedbackMode.name] strings.
  static const String trainingFeedbackModeKey = 'training_feedback_mode';
  static const String _legacyFeedbackModeKey = 'settings.feedbackMode';

  static const String trainingVoicePresetKey = 'training_voice_preset';
  static const String trainingVoiceNameKey = 'training_voice_name';
  static const String trainingVoiceLocaleKey = 'training_voice_locale';

  /// Reads the canonical value and the legacy integer value conservatively.
  ///
  /// If both keys exist, the quieter valid mode wins. This makes a partially
  /// completed migration fail closed instead of unexpectedly enabling audio.
  static TrainingFeedbackMode feedbackMode(SharedPreferences prefs) {
    final candidates = <TrainingFeedbackMode>[
      if (_parseStoredMode(prefs.get(trainingFeedbackModeKey)) case final mode?)
        mode,
      if (_parseStoredMode(prefs.get(_legacyFeedbackModeKey)) case final mode?)
        mode,
    ];

    if (candidates.isEmpty) return TrainingFeedbackMode.voiceAndCues;
    return candidates.reduce(_quieterMode);
  }

  /// Rewrites either historical representation to the single string contract.
  static Future<TrainingFeedbackMode> migrateFeedbackMode(
    SharedPreferences prefs,
  ) async {
    final mode = feedbackMode(prefs);
    await prefs.setString(trainingFeedbackModeKey, mode.name);
    await prefs.remove(_legacyFeedbackModeKey);
    return mode;
  }

  static Future<void> setFeedbackMode(
    SharedPreferences prefs,
    TrainingFeedbackMode mode,
  ) async {
    await prefs.setString(trainingFeedbackModeKey, mode.name);
    await prefs.remove(_legacyFeedbackModeKey);
  }

  static TrainingFeedbackMode? _parseStoredMode(Object? raw) {
    return switch (raw) {
      'silent' || 0 => TrainingFeedbackMode.silent,
      'hapticOnly' || 'haptic' || 1 => TrainingFeedbackMode.hapticOnly,
      'voiceAndCues' || 'voiceCues' || 2 => TrainingFeedbackMode.voiceAndCues,
      _ => null,
    };
  }

  static TrainingFeedbackMode _quieterMode(
    TrainingFeedbackMode first,
    TrainingFeedbackMode second,
  ) {
    return _quietnessRank(first) <= _quietnessRank(second) ? first : second;
  }

  static int _quietnessRank(TrainingFeedbackMode mode) {
    return switch (mode) {
      TrainingFeedbackMode.silent => 0,
      TrainingFeedbackMode.hapticOnly => 1,
      TrainingFeedbackMode.voiceAndCues => 2,
    };
  }

  static TrainingVoicePreset voicePreset(SharedPreferences prefs) {
    final raw = prefs.getString(trainingVoicePresetKey);
    return switch (raw) {
      'calm' => TrainingVoicePreset.calm,
      'dynamic' => TrainingVoicePreset.dynamic,
      'neutral' => TrainingVoicePreset.neutral,
      _ => TrainingVoicePreset.calm,
    };
  }

  static Future<void> setVoicePreset(
    SharedPreferences prefs,
    TrainingVoicePreset preset,
  ) {
    return prefs.setString(trainingVoicePresetKey, preset.name);
  }

  static String? voiceNameOrNull(SharedPreferences prefs) {
    return prefs.getString(trainingVoiceNameKey);
  }

  static TrainingVoiceSelection? voiceSelectionOrNull(SharedPreferences prefs) {
    final name = prefs.getString(trainingVoiceNameKey);
    if (name == null || name.isEmpty) return null;
    final locale = prefs.getString(trainingVoiceLocaleKey);
    if (locale == null || locale.isEmpty) {
      return TrainingVoiceSelection(name: name);
    }
    return TrainingVoiceSelection(name: name, locale: locale);
  }

  static Future<void> setVoiceName(
    SharedPreferences prefs,
    String? voiceName,
  ) {
    if (voiceName == null || voiceName.isEmpty) {
      return Future.wait([
        prefs.remove(trainingVoiceNameKey),
        prefs.remove(trainingVoiceLocaleKey),
      ]);
    }
    return prefs.setString(trainingVoiceNameKey, voiceName);
  }

  static Future<void> setVoiceSelection(
    SharedPreferences prefs,
    TrainingVoiceSelection? selection,
  ) async {
    if (selection == null) {
      await Future.wait([
        prefs.remove(trainingVoiceNameKey),
        prefs.remove(trainingVoiceLocaleKey),
      ]);
      return;
    }
    await prefs.setString(trainingVoiceNameKey, selection.name);
    if (selection.locale == null || selection.locale!.isEmpty) {
      await prefs.remove(trainingVoiceLocaleKey);
      return;
    }
    await prefs.setString(trainingVoiceLocaleKey, selection.locale!);
  }
}

class TrainingVoiceSelection {
  final String name;
  final String? locale;

  const TrainingVoiceSelection({
    required this.name,
    this.locale,
  });
}
