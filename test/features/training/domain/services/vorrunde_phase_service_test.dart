import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/training/domain/services/vorrunde_phase_service.dart';

void main() {
  group('VorrundePhase', () {
    test('start stores firstStartedAt', () {
      final now = DateTime(2026, 5, 22);
      final phase = VorrundePhase(
        id: 'phase-1',
        userId: 'user-1',
        subjectProfileId: 'subject-1',
        status: VorrundePhaseStatus.started,
        firstStartedAt: now,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(phase.firstStartedAt, now);
      expect(phase.status, VorrundePhaseStatus.started);
    });

    test('4 calendar weeks derives completed phase', () {
      final start = DateTime(2026, 5, 1);
      final phase = VorrundePhase(
        id: 'phase-1',
        userId: 'user-1',
        subjectProfileId: 'subject-1',
        status: VorrundePhaseStatus.started,
        firstStartedAt: start,
        completedAt: null,
        createdAt: start,
        updatedAt: start,
      );

      final derived = phase.deriveCompletion(DateTime(2026, 5, 29));

      expect(derived.status, VorrundePhaseStatus.completed);
      expect(derived.completedAt, DateTime(2026, 5, 29));
    });

    test('Moro start before 4 weeks keeps status started', () {
      final start = DateTime(2026, 5, 1);
      final phase = VorrundePhase(
        id: 'phase-1',
        userId: 'user-1',
        subjectProfileId: 'subject-1',
        status: VorrundePhaseStatus.started,
        firstStartedAt: start,
        completedAt: null,
        createdAt: start,
        updatedAt: start,
      );

      expect(
        phase.deriveCompletion(DateTime(2026, 5, 28)).status,
        VorrundePhaseStatus.started,
      );
    });

    test('skipped plus free Vorrunde remains skipped', () {
      final now = DateTime(2026, 5, 22);
      final skipped = VorrundePhase(
        id: 'phase-1',
        userId: 'user-1',
        subjectProfileId: 'subject-1',
        status: VorrundePhaseStatus.skipped,
        firstStartedAt: null,
        completedAt: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        skipped.deriveCompletion(DateTime(2026, 6, 30)).status,
        VorrundePhaseStatus.skipped,
      );
    });
  });
}
