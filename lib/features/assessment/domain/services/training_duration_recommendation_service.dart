import '../models/reflex_profile_assessment.dart';
import '../reflex_questionnaire.dart';

class TrainingDurationRecommendation {
  const TrainingDurationRecommendation({
    required this.weeks,
    required this.consideredPercents,
    required this.consideredReflexes,
    required this.usedAssessment,
    required this.hadIsometricWithTrainer,
  });

  final int weeks;
  final Map<PrimitiveReflex, double?> consideredPercents;
  final List<PrimitiveReflex> consideredReflexes;
  final bool usedAssessment;
  final bool hadIsometricWithTrainer;

  double? get strongestPercent {
    double? strongest;
    for (final value in consideredPercents.values) {
      if (value == null) continue;
      strongest = strongest == null || value > strongest ? value : strongest;
    }
    return strongest;
  }
}

const _packageReflexes = <String, List<PrimitiveReflex>>{
  'moro': [PrimitiveReflex.moro, PrimitiveReflex.flr],
  'spinal_galant': [PrimitiveReflex.spinalGalant],
  'tlr': [PrimitiveReflex.tlr],
  'atnr': [PrimitiveReflex.atnr],
  'stnr': [PrimitiveReflex.stnr],
  'babkin': [
    PrimitiveReflex.babkin,
    PrimitiveReflex.palmar,
    PrimitiveReflex.plantar,
  ],
  'such_saug': [PrimitiveReflex.rootingSucking],
  'babinski': [PrimitiveReflex.babinski],
  'landau': [PrimitiveReflex.landau],
};

TrainingDurationRecommendation recommendTrainingDuration({
  required String packageId,
  required bool hadIsometricWithTrainer,
  ReflexProfileAssessment? assessment,
}) {
  final consideredReflexes =
      _packageReflexes[packageId] ?? const <PrimitiveReflex>[];
  final consideredPercents = <PrimitiveReflex, double?>{
    for (final reflex in consideredReflexes)
      reflex: _percentFor(assessment?.scores, reflex),
  };
  final strongest = consideredPercents.values.whereType<double>().fold<double?>(
      null, (max, value) => max == null || value > max ? value : max);
  final usedAssessment =
      assessment != null && assessment.isCompleted && strongest != null;

  if (!usedAssessment) {
    return TrainingDurationRecommendation(
      weeks: hadIsometricWithTrainer ? 4 : 8,
      consideredPercents: consideredPercents,
      consideredReflexes: consideredReflexes,
      usedAssessment: false,
      hadIsometricWithTrainer: hadIsometricWithTrainer,
    );
  }

  final weeks = switch (_DurationBand.fromPercent(strongest)) {
    _DurationBand.low => hadIsometricWithTrainer ? 4 : 6,
    _DurationBand.medium => hadIsometricWithTrainer ? 5 : 7,
    _DurationBand.high => hadIsometricWithTrainer ? 6 : 8,
  };

  return TrainingDurationRecommendation(
    weeks: weeks,
    consideredPercents: consideredPercents,
    consideredReflexes: consideredReflexes,
    usedAssessment: true,
    hadIsometricWithTrainer: hadIsometricWithTrainer,
  );
}

enum _DurationBand {
  low,
  medium,
  high;

  static _DurationBand fromPercent(double percent) {
    if (percent < 75) return _DurationBand.low;
    if (percent <= 85) return _DurationBand.medium;
    return _DurationBand.high;
  }
}

double? _percentFor(Map<String, dynamic>? scores, PrimitiveReflex reflex) {
  if (scores == null || scores.isEmpty) return null;
  final raw = scores[reflex.name] ?? scores[_snakeCase(reflex.name)];
  if (raw is num) return raw.toDouble();
  if (raw is Map) {
    final percent = raw['percent'];
    if (percent is num) return percent.toDouble();
  }
  return null;
}

String _snakeCase(String value) {
  return value.replaceAllMapped(
    RegExp('[A-Z]'),
    (match) => '_${match.group(0)!.toLowerCase()}',
  );
}
