// test/features/training/presentation/apply_training_anchor_test.dart
import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/core/training/training_anchor_settings.dart';
import 'package:corejourney/features/training/presentation/apply_training_anchor.dart';
import 'package:corejourney/features/training/presentation/widgets/training_anchor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('applying an answer switches reminders on and sets the time',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsProvider.overrideWith((ref) => SettingsNotifier(prefs, null)),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await applyTrainingAnchor(
      captured,
      const TrainingAnchorResult(
        anchor: TrainingAnchor.afterSchool,
        minutes: 15 * 60 + 30,
      ),
    );

    final settings = captured.read(settingsProvider);
    expect(settings.remindersEnabled, isTrue);
    expect(settings.reminderStartMinutes, 15 * 60 + 30);

    expect(TrainingAnchorSettings.anchor(prefs), TrainingAnchor.afterSchool);
    expect(TrainingAnchorSettings.wasAsked(prefs), isTrue);
  });
}
