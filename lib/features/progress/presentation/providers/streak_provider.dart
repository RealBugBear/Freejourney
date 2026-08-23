import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../data/repositories/streak_credits_repository.dart';
import '../../domain/streak/streak_credits.dart';
import '../../domain/streak/streak_math.dart';

/// How far back the series and the rescued-day list are considered.
const int kStreakLookbackDays = 400;

/// Runs one evaluation: earn, spend, mirror (spec §4.3).
class StreakService {
  StreakService({required this.repository, required this.now});

  final StreakCreditsRepository repository;
  final DateTime Function() now;

  Future<StreakEvaluation> evaluate({
    required String userId,
    required String subjectProfileId,
  }) async {
    final today = dateOnly(now());
    final since = DateTime(
      today.year,
      today.month,
      today.day - kStreakLookbackDays,
    );

    final trainingDays = await repository.trainingDaysFor(
      subjectProfileId: subjectProfileId,
      since: since,
    );
    final credits = await repository.loadCredits(
      userId: userId,
      subjectProfileId: subjectProfileId,
    );

    final evaluation = evaluateStreak(
      trainingDays: trainingDays,
      credits: credits,
      today: today,
      lookbackDays: kStreakLookbackDays,
    );

    await repository.saveCredits(
      userId: userId,
      subjectProfileId: subjectProfileId,
      credits: evaluation.credits,
    );
    await repository.mirrorStreak(
      subjectProfileId: subjectProfileId,
      length: evaluation.length,
    );

    return evaluation;
  }
}

final streakCreditsRepositoryProvider =
    Provider<StreakCreditsRepository>((ref) {
  return StreakCreditsRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final streakServiceProvider = Provider<StreakService>((ref) {
  final clock = ref.watch(appClockProvider);
  return StreakService(
    repository: ref.watch(streakCreditsRepositoryProvider),
    now: clock.now,
  );
});

/// Everything the dashboard row needs.
class StreakView {
  const StreakView({
    required this.length,
    required this.credits,
    required this.trainingDays,
    required this.rescuedDays,
    required this.newlyRescued,
  });

  final int length;
  final int credits;
  final Set<DateTime> trainingDays;
  final Set<DateTime> rescuedDays;
  final Set<DateTime> newlyRescued;
}

final streakViewProvider = FutureProvider<StreakView?>((ref) async {
  final profile = ref.watch(selectedSubjectProfileProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (profile == null || userId == null) return null;

  final service = ref.watch(streakServiceProvider);
  final evaluation = await service.evaluate(
    userId: userId,
    subjectProfileId: profile.id,
  );

  final today = dateOnly(ref.watch(appClockProvider).now());
  final since = DateTime(
    today.year,
    today.month,
    today.day - kStreakLookbackDays,
  );
  final trainingDays = await ref
      .watch(streakCreditsRepositoryProvider)
      .trainingDaysFor(subjectProfileId: profile.id, since: since);

  return StreakView(
    length: evaluation.length,
    credits: evaluation.credits.available,
    trainingDays: trainingDays,
    rescuedDays: evaluation.credits.rescuedDays,
    newlyRescued: evaluation.newlyRescued,
  );
});
