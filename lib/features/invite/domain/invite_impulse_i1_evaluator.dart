import 'invite_prompt_policy.dart';

/// Result of deciding whether I1 may appear and whether a show was recorded.
class InviteImpulseI1Evaluation {
  const InviteImpulseI1Evaluation({
    required this.shouldShow,
    required this.didRecordShow,
    this.didQueryDependencies = false,
  });

  final bool shouldShow;
  final bool didRecordShow;

  /// True when mood/store were contacted (false when flag/context short-circuits).
  final bool didQueryDependencies;
}

/// Testable I1 gate: settle unanswered → decide → optionally record show.
Future<InviteImpulseI1Evaluation> evaluateInviteImpulseI1({
  required bool inviteEnabled,
  required bool isFirstResultDisplay,
  required String? userId,
  required DateTime now,
  required bool isTrainingSessionActive,
  required Future<bool> Function() readLowMood,
  required Future<InvitePromptPersistState> Function(String userId)
      settleUnanswered,
  required Future<void> Function(String userId, DateTime now) recordShown,
}) async {
  if (!inviteEnabled || !isFirstResultDisplay || userId == null) {
    return const InviteImpulseI1Evaluation(
      shouldShow: false,
      didRecordShow: false,
    );
  }

  try {
    final lowMood = await readLowMood();
    final state = await settleUnanswered(userId);
    final decision = decideInvitePrompt(
      InvitePromptInput(
        now: now,
        sourceEnabled: true,
        isEligibleContext: isFirstResultDisplay,
        isTrainingSessionActive: isTrainingSessionActive,
        hasLowMoodInLast24Hours: lowMood,
        permanentlySilent: state.permanentlySilent,
        ignoredShowCount: state.ignoredShowCount,
        lastShownAt: state.lastShownAt,
        showsInFirstYear: state.showsInFirstYear,
        firstYearStartedAt: state.firstYearStartedAt,
      ),
    );
    if (decision != InvitePromptDecision.show) {
      return const InviteImpulseI1Evaluation(
        shouldShow: false,
        didRecordShow: false,
        didQueryDependencies: true,
      );
    }
    await recordShown(userId, now);
    return const InviteImpulseI1Evaluation(
      shouldShow: true,
      didRecordShow: true,
      didQueryDependencies: true,
    );
  } catch (_) {
    // Sensitivity / storage failure → fail closed, never record a show.
    return const InviteImpulseI1Evaluation(
      shouldShow: false,
      didRecordShow: false,
      didQueryDependencies: true,
    );
  }
}
