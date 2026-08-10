import 'package:corejourney/core/settings/settings_provider.dart'
    show SettingsNotifier, languagePreferenceKey;
import 'package:corejourney/core/training/training_feedback_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TrainingFeedbackSettings migration', () {
    test('defaults to voice and cues and writes the canonical string key',
        () async {
      final prefs = await SharedPreferences.getInstance();

      expect(
        TrainingFeedbackSettings.feedbackMode(prefs),
        TrainingFeedbackMode.voiceAndCues,
      );

      final migrated =
          await TrainingFeedbackSettings.migrateFeedbackMode(prefs);

      expect(migrated, TrainingFeedbackMode.voiceAndCues);
      expect(
        prefs.getString(TrainingFeedbackSettings.trainingFeedbackModeKey),
        'voiceAndCues',
      );
      expect(prefs.containsKey('settings.feedbackMode'), isFalse);
    });

    test('migrates the legacy integer format', () async {
      SharedPreferences.setMockInitialValues({
        'settings.feedbackMode': 2,
      });
      final prefs = await SharedPreferences.getInstance();

      final migrated =
          await TrainingFeedbackSettings.migrateFeedbackMode(prefs);

      expect(migrated, TrainingFeedbackMode.voiceAndCues);
      expect(
        prefs.getString(TrainingFeedbackSettings.trainingFeedbackModeKey),
        'voiceAndCues',
      );
      expect(prefs.containsKey('settings.feedbackMode'), isFalse);
    });

    test('understands historical string enum names', () async {
      SharedPreferences.setMockInitialValues({
        TrainingFeedbackSettings.trainingFeedbackModeKey: 'voiceCues',
      });
      final prefs = await SharedPreferences.getInstance();

      final migrated =
          await TrainingFeedbackSettings.migrateFeedbackMode(prefs);

      expect(migrated, TrainingFeedbackMode.voiceAndCues);
      expect(
        prefs.getString(TrainingFeedbackSettings.trainingFeedbackModeKey),
        'voiceAndCues',
      );
    });

    test('chooses the quieter mode when both formats disagree', () async {
      SharedPreferences.setMockInitialValues({
        TrainingFeedbackSettings.trainingFeedbackModeKey: 'voiceAndCues',
        'settings.feedbackMode': 1,
      });
      final prefs = await SharedPreferences.getInstance();

      final migrated =
          await TrainingFeedbackSettings.migrateFeedbackMode(prefs);

      expect(migrated, TrainingFeedbackMode.hapticOnly);
      expect(
        prefs.getString(TrainingFeedbackSettings.trainingFeedbackModeKey),
        'hapticOnly',
      );
      expect(prefs.containsKey('settings.feedbackMode'), isFalse);
    });

    test('never overrides canonical silent with a louder legacy value',
        () async {
      SharedPreferences.setMockInitialValues({
        TrainingFeedbackSettings.trainingFeedbackModeKey: 'silent',
        'settings.feedbackMode': 2,
      });
      final prefs = await SharedPreferences.getInstance();

      expect(
        await TrainingFeedbackSettings.migrateFeedbackMode(prefs),
        TrainingFeedbackMode.silent,
      );
    });

    test('explicit writes remove the integer legacy key', () async {
      SharedPreferences.setMockInitialValues({
        'settings.feedbackMode': 0,
      });
      final prefs = await SharedPreferences.getInstance();

      await TrainingFeedbackSettings.setFeedbackMode(
        prefs,
        TrainingFeedbackMode.voiceAndCues,
      );

      expect(
        TrainingFeedbackSettings.feedbackMode(prefs),
        TrainingFeedbackMode.voiceAndCues,
      );
      expect(prefs.containsKey('settings.feedbackMode'), isFalse);
    });

    test('SettingsNotifier serializes migration before an immediate user write',
        () async {
      SharedPreferences.setMockInitialValues({
        languagePreferenceKey: 'de',
        TrainingFeedbackSettings.trainingFeedbackModeKey: 'voiceAndCues',
        'settings.feedbackMode': 0,
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = SettingsNotifier(prefs, null);

      expect(notifier.state.feedbackMode, TrainingFeedbackMode.silent);
      notifier.setFeedbackMode(TrainingFeedbackMode.voiceAndCues);
      await _flushAsync();

      expect(notifier.state.feedbackMode, TrainingFeedbackMode.voiceAndCues);
      expect(
        prefs.getString(TrainingFeedbackSettings.trainingFeedbackModeKey),
        'voiceAndCues',
      );
      expect(prefs.containsKey('settings.feedbackMode'), isFalse);
      notifier.dispose();
    });
  });

  test('feedback policy matrix has exact channel permissions', () {
    expect(
      TrainingFeedbackPolicy.matrix,
      hasLength(TrainingFeedbackMode.values.length),
    );

    final silent = TrainingFeedbackMode.silent.policy;
    expect(silent.allowsVoice, isFalse);
    expect(silent.allowsTones, isFalse);
    expect(silent.allowsMusic, isFalse);
    expect(silent.allowsHaptics, isFalse);

    final hapticOnly = TrainingFeedbackMode.hapticOnly.policy;
    expect(hapticOnly.allowsVoice, isFalse);
    expect(hapticOnly.allowsTones, isFalse);
    expect(hapticOnly.allowsMusic, isFalse);
    expect(hapticOnly.allowsHaptics, isTrue);

    final voiceAndCues = TrainingFeedbackMode.voiceAndCues.policy;
    expect(voiceAndCues.allowsVoice, isTrue);
    expect(voiceAndCues.allowsTones, isTrue);
    expect(voiceAndCues.allowsMusic, isTrue);
    expect(voiceAndCues.allowsHaptics, isTrue);
  });
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
