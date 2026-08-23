// test/core/training/training_anchor_settings_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/core/training/training_anchor_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('nothing is stored before the question is answered', () {
    expect(TrainingAnchorSettings.anchor(prefs), isNull);
    expect(TrainingAnchorSettings.wasAsked(prefs), isFalse);
  });

  test('a stored anchor survives a reload', () async {
    await TrainingAnchorSettings.setAnchor(prefs, TrainingAnchor.afterSchool);
    expect(TrainingAnchorSettings.anchor(prefs), TrainingAnchor.afterSchool);
  });

  test('asks after exactly one completed session', () async {
    await prefs.setInt('completed_session_count', 1);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isTrue);
  });

  test('does not ask before the first session', () async {
    await prefs.setInt('completed_session_count', 0);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });

  test('does not ask again once the question was put', () async {
    await prefs.setInt('completed_session_count', 1);
    await TrainingAnchorSettings.markAsked(prefs);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });

  test('a missed moment is not made up later', () async {
    // Someone who trained twice before this shipped is not asked at all —
    // the question belongs to the moment right after the first session.
    await prefs.setInt('completed_session_count', 5);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });
}
