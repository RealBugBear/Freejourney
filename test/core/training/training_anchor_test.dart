// test/core/training/training_anchor_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adults are offered four anchors, waking up first', () {
    final options = anchorOptionsFor(isAdultSelf: true);
    expect(options, [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterBreakfast,
      TrainingAnchor.midday,
      TrainingAnchor.evening,
    ]);
  });

  test('families are offered their own four anchors', () {
    final options = anchorOptionsFor(isAdultSelf: false);
    expect(options, [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterSchool,
      TrainingAnchor.afterDinner,
      TrainingAnchor.fixedTime,
    ]);
  });

  test('only adults get a recommendation (A2)', () {
    expect(recommendedAnchorFor(isAdultSelf: true), TrainingAnchor.wakeUp);
    expect(recommendedAnchorFor(isAdultSelf: false), isNull);
  });

  test('every offered anchor proposes a time inside the day', () {
    for (final isAdult in [true, false]) {
      for (final anchor in anchorOptionsFor(isAdultSelf: isAdult)) {
        final minutes = defaultMinutesFor(anchor);
        expect(minutes, greaterThanOrEqualTo(0));
        expect(minutes, lessThan(24 * 60));
      }
    }
  });

  test('the proposed times follow the order of the day', () {
    expect(defaultMinutesFor(TrainingAnchor.wakeUp), 7 * 60);
    expect(defaultMinutesFor(TrainingAnchor.afterBreakfast), 8 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.midday), 12 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.afterSchool), 15 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.afterDinner), 18 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.evening), 19 * 60);
  });

  test('the sleep hint belongs to the late anchors only', () {
    expect(showsEveningHint(TrainingAnchor.evening), isTrue);
    expect(showsEveningHint(TrainingAnchor.afterDinner), isTrue);
    expect(showsEveningHint(TrainingAnchor.wakeUp), isFalse);
    expect(showsEveningHint(TrainingAnchor.afterSchool), isFalse);
    expect(showsEveningHint(TrainingAnchor.fixedTime), isFalse);
  });

  test('unknown or missing names decode to null', () {
    expect(anchorFromName('wakeUp'), TrainingAnchor.wakeUp);
    expect(anchorFromName('nonsense'), isNull);
    expect(anchorFromName(null), isNull);
  });
}
