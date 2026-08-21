import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/features/assessment/domain/adult_questionnaire_visibility.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/adult_safety_notice.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';

void main() {
  group('Phase 6 default flags', () {
    test('questionnaire stays off until Phase 7 result UI', () {
      expect(kAdultReflexQuestionnaireEnabled, isFalse);
    });

    test('movement and hard-gate stay off by default', () {
      expect(kAdultMovementChecksEnabled, isFalse);
      expect(kAdultSafetyHardGateEnabled, isFalse);
    });
  });

  group('AdultSafetyNotice', () {
    test('message_version is expert draft v0', () {
      expect(AdultSafetyNotice.messageVersion, 'adult_safety_expertdraft_v0');
      expect(AdultSafetyNotice.contentApprovalStatus, 'expertPending');
    });

    test('DE body matches expert draft and omits movement appendix by default',
        () {
      final body = AdultSafetyNotice.body(
        languageCode: 'de',
        movementChecksEnabled: false,
      );
      expect(
        body,
        'Deine Angabe kann bedeuten, dass einzelne Bewegungen oder '
        'Trainingsübungen angepasst oder vorher fachlich besprochen werden '
        'sollten. Dieses Ergebnis bewertet deine Diagnose nicht.',
      );
      expect(body.contains('gekennzeichneten Übungen'), isFalse);
    });

    test('movement appendix is appended only when movement flag is on', () {
      final body = AdultSafetyNotice.body(
        languageCode: 'de',
        movementChecksEnabled: true,
      );
      expect(
        body.endsWith(
          'Führe die gekennzeichneten Übungen nicht ohne die hier empfohlene '
          'Rücksprache durch.',
        ),
        isTrue,
      );
    });
  });

  group('movement unreachable with default flags', () {
    test('s005/s006 are not visible when movementChecksEnabled is false', () {
      final visibility = AdultQuestionnaireVisibility(
        definition: adultSelfQuestionnaireV3,
        answers: const {},
        movementChecksEnabled: kAdultMovementChecksEnabled,
      );
      expect(kAdultMovementChecksEnabled, isFalse);
      final movementIds = visibility.visibleQuestions
          .where((q) => q.role == ReflexQuestionRole.movement)
          .map((q) => q.id)
          .toList();
      expect(movementIds, isEmpty);
      expect(
        adultSelfQuestionnaireV3.questions
            .where((q) => q.id == 's005' || q.id == 's006')
            .every((q) => !visibility.isVisible(q)),
        isTrue,
      );
      expect(
        visibility.visibleQuestions
            .any((q) => q.adultModule == AdultQuestionModule.movementOptional),
        isFalse,
      );
    });
  });
}
