// lib/core/training/training_anchor.dart

/// A fixed daily event the training is hooked onto.
///
/// The point of the feature is the anchor, not the clock: waking up happens
/// every day without having to be remembered, which is why it carries a habit
/// better than a time does. The clock time only exists because a reminder
/// needs one (spec §4.4).
enum TrainingAnchor {
  wakeUp,
  afterBreakfast,
  midday,
  evening,
  afterSchool,
  afterDinner,
  fixedTime,
}

/// Which anchors are offered, in display order.
///
/// Families get a different list on purpose (founder decision A2): the school
/// morning is the one slot they cannot reliably deliver.
List<TrainingAnchor> anchorOptionsFor({required bool isAdultSelf}) {
  if (isAdultSelf) {
    return const [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterBreakfast,
      TrainingAnchor.midday,
      TrainingAnchor.evening,
    ];
  }
  return const [
    TrainingAnchor.wakeUp,
    TrainingAnchor.afterSchool,
    TrainingAnchor.afterDinner,
    TrainingAnchor.fixedTime,
  ];
}

/// The anchor marked as recommended, or null when none is.
///
/// Only adults training for themselves get one. For families the founder
/// deliberately chose to offer the choice without a suggestion — the app does
/// not know their day well enough to recommend one.
TrainingAnchor? recommendedAnchorFor({required bool isAdultSelf}) =>
    isAdultSelf ? TrainingAnchor.wakeUp : null;

/// Proposed reminder time as minutes since midnight. Adjustable by the user.
int defaultMinutesFor(TrainingAnchor anchor) {
  return switch (anchor) {
    TrainingAnchor.wakeUp => 7 * 60,
    TrainingAnchor.afterBreakfast => 8 * 60 + 30,
    TrainingAnchor.midday => 12 * 60 + 30,
    TrainingAnchor.afterSchool => 15 * 60 + 30,
    TrainingAnchor.afterDinner => 18 * 60 + 30,
    TrainingAnchor.evening => 19 * 60,
    TrainingAnchor.fixedTime => 17 * 60,
  };
}

/// Whether to show the falling-asleep hint (spec §4.5).
///
/// Only for anchors that sit close to bedtime. It is an observation, never a
/// claim about how the exercises work.
bool showsEveningHint(TrainingAnchor anchor) =>
    anchor == TrainingAnchor.evening || anchor == TrainingAnchor.afterDinner;

/// Decodes a stored name. Unknown values decode to null so a renamed or
/// removed anchor cannot crash the app.
TrainingAnchor? anchorFromName(String? name) {
  if (name == null) return null;
  for (final anchor in TrainingAnchor.values) {
    if (anchor.name == name) return anchor;
  }
  return null;
}
