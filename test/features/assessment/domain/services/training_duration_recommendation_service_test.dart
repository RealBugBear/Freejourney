import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/services/training_duration_recommendation_service.dart';

ReflexProfileAssessment _assessment(Map<String, dynamic> scores) {
  return ReflexProfileAssessment(
    id: 'assessment-1',
    packageId: 'moro',
    subjectProfileId: 'subject-1',
    questionnaireType: 'child_parent_report',
    questionnaireVersion: 'v1',
    scoringVersion: 'v1',
    status: 'completed',
    answers: const {},
    scores: scores,
    warningConfirmations: const [],
    safetyStatus: 'clear',
    completedAt: DateTime(2026, 5, 1),
    createdAt: DateTime(2026, 5, 1),
  );
}

void main() {
  group('recommendTrainingDuration', () {
    test('uses isometric yes thresholds for Moro max value', () {
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: true,
          assessment: _assessment({
            'moro': {'percent': 65},
            'flr': {'percent': 64},
          }),
        ).weeks,
        4,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: true,
          assessment: _assessment({
            'moro': {'percent': 75},
            'flr': {'percent': 74},
          }),
        ).weeks,
        5,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: true,
          assessment: _assessment({
            'moro': {'percent': 85},
            'flr': {'percent': 84},
          }),
        ).weeks,
        5,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: true,
          assessment: _assessment({
            'moro': {'percent': 86},
            'flr': {'percent': 84},
          }),
        ).weeks,
        6,
      );
    });

    test('uses isometric no thresholds for Moro max value', () {
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: false,
          assessment: _assessment({
            'moro': {'percent': 65},
            'flr': {'percent': 64},
          }),
        ).weeks,
        6,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: false,
          assessment: _assessment({
            'moro': {'percent': 75},
            'flr': {'percent': 74},
          }),
        ).weeks,
        7,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: false,
          assessment: _assessment({
            'moro': {'percent': 86},
            'flr': {'percent': 84},
          }),
        ).weeks,
        8,
      );
    });

    test('Moro uses max of Moro and FLR and returns both values', () {
      final result = recommendTrainingDuration(
        packageId: 'moro',
        hadIsometricWithTrainer: true,
        assessment: _assessment({
          'moro': {'percent': 68},
          'flr': {'percent': 82},
        }),
      );

      expect(result.weeks, 5);
      expect(result.strongestPercent, 82);
      expect(result.consideredReflexes, [
        PrimitiveReflex.moro,
        PrimitiveReflex.flr,
      ]);
      expect(result.consideredPercents[PrimitiveReflex.moro], 68);
      expect(result.consideredPercents[PrimitiveReflex.flr], 82);
    });

    test('missing mapped value is exposed as null', () {
      final result = recommendTrainingDuration(
        packageId: 'moro',
        hadIsometricWithTrainer: true,
        assessment: _assessment({
          'moro': {'percent': 68},
        }),
      );

      expect(result.usedAssessment, isTrue);
      expect(result.consideredPercents[PrimitiveReflex.moro], 68);
      expect(result.consideredPercents[PrimitiveReflex.flr], isNull);
    });

    test('missing assessment uses fallback defaults', () {
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: true,
        ).weeks,
        4,
      );
      expect(
        recommendTrainingDuration(
          packageId: 'moro',
          hadIsometricWithTrainer: false,
        ).weeks,
        8,
      );
    });
  });
}
