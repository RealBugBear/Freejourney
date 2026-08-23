// test/features/training/presentation/joint_training_sheet_test.dart
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/training/presentation/widgets/joint_training_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

ReflexSubjectProfile _profile(String id, String name) => ReflexSubjectProfile(
      id: id,
      displayName: name,
      profileType: 'child',
    );

void main() {
  test('without a remembered selection every candidate is preselected', () {
    final candidates = [
      JointTrainingCandidate(profile: _profile('a', 'Lena')),
      JointTrainingCandidate(profile: _profile('b', 'Noah')),
    ];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const []),
      ['a', 'b'],
    );
  });

  test('the remembered selection wins when it still applies', () {
    final candidates = [
      JointTrainingCandidate(profile: _profile('a', 'Lena')),
      JointTrainingCandidate(profile: _profile('b', 'Noah')),
    ];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const ['b']),
      ['b'],
    );
  });

  test('remembered profiles that are gone drop out', () {
    final candidates = [JointTrainingCandidate(profile: _profile('a', 'Lena'))];
    expect(
      defaultJointSelection(
        candidates: candidates,
        remembered: const ['b', 'a'],
      ),
      ['a'],
    );
  });

  test('an empty remembered result falls back to everyone', () {
    final candidates = [JointTrainingCandidate(profile: _profile('a', 'Lena'))];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const ['gone']),
      ['a'],
    );
  });
}
