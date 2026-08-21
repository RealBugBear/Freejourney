import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/invite/domain/invite_impulse_i1_evaluator.dart';
import 'package:corejourney/features/invite/domain/invite_prompt_policy.dart';

void main() {
  final now = DateTime.utc(2026, 8, 21, 12);

  InvitePromptInput base({
    bool sourceEnabled = true,
    bool isEligibleContext = true,
    bool isTrainingSessionActive = false,
    bool hasLowMoodInLast24Hours = false,
    bool permanentlySilent = false,
    int ignoredShowCount = 0,
    DateTime? lastShownAt,
    int showsInFirstYear = 0,
    DateTime? firstYearStartedAt,
  }) {
    return InvitePromptInput(
      now: now,
      sourceEnabled: sourceEnabled,
      isEligibleContext: isEligibleContext,
      isTrainingSessionActive: isTrainingSessionActive,
      hasLowMoodInLast24Hours: hasLowMoodInLast24Hours,
      permanentlySilent: permanentlySilent,
      ignoredShowCount: ignoredShowCount,
      lastShownAt: lastShownAt,
      showsInFirstYear: showsInFirstYear,
      firstYearStartedAt: firstYearStartedAt,
    );
  }

  test('shows when all gates pass', () {
    expect(decideInvitePrompt(base()), InvitePromptDecision.show);
  });

  test('suppresses when source disabled (I2)', () {
    expect(
      decideInvitePrompt(base(sourceEnabled: false)),
      InvitePromptDecision.suppress,
    );
  });

  test('suppresses outside eligible context', () {
    expect(
      decideInvitePrompt(base(isEligibleContext: false)),
      InvitePromptDecision.suppress,
    );
  });

  test('suppresses during training session', () {
    expect(
      decideInvitePrompt(base(isTrainingSessionActive: true)),
      InvitePromptDecision.suppress,
    );
  });

  test('suppresses on low mood in last 24h', () {
    expect(
      decideInvitePrompt(base(hasLowMoodInLast24Hours: true)),
      InvitePromptDecision.suppress,
    );
  });

  test('suppresses when permanently silent', () {
    expect(
      decideInvitePrompt(base(permanentlySilent: true)),
      InvitePromptDecision.suppress,
    );
  });

  test('suppresses after two settled ignored shows', () {
    expect(
      decideInvitePrompt(base(ignoredShowCount: 2)),
      InvitePromptDecision.suppress,
    );
  });

  test('enforces 30-day cooldown', () {
    expect(
      decideInvitePrompt(
        base(lastShownAt: now.subtract(const Duration(days: 10))),
      ),
      InvitePromptDecision.suppress,
    );
    expect(
      decideInvitePrompt(
        base(lastShownAt: now.subtract(const Duration(days: 30))),
      ),
      InvitePromptDecision.show,
    );
  });

  test('enforces max three shows in first year', () {
    expect(
      decideInvitePrompt(
        base(
          showsInFirstYear: 3,
          firstYearStartedAt: now.subtract(const Duration(days: 10)),
          lastShownAt: now.subtract(const Duration(days: 40)),
        ),
      ),
      InvitePromptDecision.suppress,
    );
    expect(
      decideInvitePrompt(
        base(
          showsInFirstYear: 3,
          firstYearStartedAt: now.subtract(const Duration(days: 400)),
          lastShownAt: now.subtract(const Duration(days: 40)),
        ),
      ),
      InvitePromptDecision.show,
    );
  });

  test('afterShow marks unanswered without incrementing ignore', () {
    final shown = invitePromptStateAfterShow(
      now: now,
      previous: const InvitePromptPersistState(),
    );
    expect(shown.lastShowUnanswered, isTrue);
    expect(shown.ignoredShowCount, 0);
    expect(shown.permanentlySilent, isFalse);
    expect(shown.showsInFirstYear, 1);
  });

  test('settle counts unanswered; second settle can become permanent', () {
    final afterFirstShow = invitePromptStateAfterShow(
      now: now,
      previous: const InvitePromptPersistState(),
    );
    final settledOnce = invitePromptStateAfterSettleUnanswered(afterFirstShow);
    expect(settledOnce.lastShowUnanswered, isFalse);
    expect(settledOnce.ignoredShowCount, 1);
    expect(settledOnce.permanentlySilent, isFalse);

    final afterSecondShow = invitePromptStateAfterShow(
      now: now.add(const Duration(days: 31)),
      previous: settledOnce,
    );
    final settledTwice =
        invitePromptStateAfterSettleUnanswered(afterSecondShow);
    expect(settledTwice.ignoredShowCount, 2);
    expect(settledTwice.permanentlySilent, isTrue);
  });

  test('first ignored then second tapped is not permanently silent', () {
    final afterFirstShow = invitePromptStateAfterShow(
      now: now,
      previous: const InvitePromptPersistState(),
    );
    final afterIgnore = invitePromptStateAfterSettleUnanswered(afterFirstShow);
    expect(afterIgnore.ignoredShowCount, 1);

    final afterSecondShow = invitePromptStateAfterShow(
      now: now.add(const Duration(days: 31)),
      previous: afterIgnore,
    );
    expect(afterSecondShow.permanentlySilent, isFalse);
    expect(afterSecondShow.lastShowUnanswered, isTrue);

    final afterTap = invitePromptStateAfterTap(afterSecondShow);
    expect(afterTap.ignoredShowCount, 0);
    expect(afterTap.lastShowUnanswered, isFalse);
    expect(afterTap.permanentlySilent, isFalse);
  });

  test('tap on first show clears unanswered; cooldown still applies', () {
    final shown = invitePromptStateAfterShow(
      now: now,
      previous: const InvitePromptPersistState(),
    );
    final tapped = invitePromptStateAfterTap(shown);
    expect(tapped.ignoredShowCount, 0);
    expect(tapped.lastShowUnanswered, isFalse);
    expect(tapped.lastShownAt, now);

    expect(
      decideInvitePrompt(
        InvitePromptInput(
          now: now.add(const Duration(days: 10)),
          sourceEnabled: true,
          isEligibleContext: true,
          isTrainingSessionActive: false,
          hasLowMoodInLast24Hours: false,
          permanentlySilent: tapped.permanentlySilent,
          ignoredShowCount: tapped.ignoredShowCount,
          lastShownAt: tapped.lastShownAt,
          showsInFirstYear: tapped.showsInFirstYear,
          firstYearStartedAt: tapped.firstYearStartedAt,
        ),
      ),
      InvitePromptDecision.suppress,
    );
    expect(
      decideInvitePrompt(
        InvitePromptInput(
          now: now.add(const Duration(days: 30)),
          sourceEnabled: true,
          isEligibleContext: true,
          isTrainingSessionActive: false,
          hasLowMoodInLast24Hours: false,
          permanentlySilent: tapped.permanentlySilent,
          ignoredShowCount: tapped.ignoredShowCount,
          lastShownAt: tapped.lastShownAt,
          showsInFirstYear: tapped.showsInFirstYear,
          firstYearStartedAt: tapped.firstYearStartedAt,
        ),
      ),
      InvitePromptDecision.show,
    );
  });

  group('evaluateInviteImpulseI1', () {
    test('flag off skips mood/store and does not record', () async {
      var moodCalls = 0;
      var settleCalls = 0;
      var showCalls = 0;
      final result = await evaluateInviteImpulseI1(
        inviteEnabled: false,
        isFirstResultDisplay: true,
        userId: 'u1',
        now: now,
        isTrainingSessionActive: false,
        readLowMood: () async {
          moodCalls++;
          return false;
        },
        settleUnanswered: (_) async {
          settleCalls++;
          return const InvitePromptPersistState();
        },
        recordShown: (_, __) async {
          showCalls++;
        },
      );
      expect(result.shouldShow, isFalse);
      expect(result.didRecordShow, isFalse);
      expect(result.didQueryDependencies, isFalse);
      expect(moodCalls, 0);
      expect(settleCalls, 0);
      expect(showCalls, 0);
    });

    test('mood or store failure suppresses without recording show', () async {
      final moodFail = await evaluateInviteImpulseI1(
        inviteEnabled: true,
        isFirstResultDisplay: true,
        userId: 'u1',
        now: now,
        isTrainingSessionActive: false,
        readLowMood: () async => throw StateError('mood'),
        settleUnanswered: (_) async => const InvitePromptPersistState(),
        recordShown: (_, __) async {},
      );
      expect(moodFail.shouldShow, isFalse);
      expect(moodFail.didRecordShow, isFalse);

      var recorded = false;
      final storeFail = await evaluateInviteImpulseI1(
        inviteEnabled: true,
        isFirstResultDisplay: true,
        userId: 'u1',
        now: now,
        isTrainingSessionActive: false,
        readLowMood: () async => false,
        settleUnanswered: (_) async => throw StateError('store'),
        recordShown: (_, __) async {
          recorded = true;
        },
      );
      expect(storeFail.shouldShow, isFalse);
      expect(storeFail.didRecordShow, isFalse);
      expect(recorded, isFalse);
    });
  });
}
