import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/storage/pending_invite_store.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../mood/presentation/providers/mood_provider.dart';
import '../../domain/invite_impulse_i1_evaluator.dart';
import '../../domain/invite_prompt_policy.dart';
import 'invite_impulse_card.dart';

/// I1 placement: first reflex-result display (not history reopen).
class InviteImpulseI1Slot extends ConsumerStatefulWidget {
  const InviteImpulseI1Slot({
    super.key,
    required this.isFirstResultDisplay,
  });

  /// True when opening the primary result after completion (no history extra).
  final bool isFirstResultDisplay;

  @override
  ConsumerState<InviteImpulseI1Slot> createState() =>
      _InviteImpulseI1SlotState();
}

class _InviteImpulseI1SlotState extends ConsumerState<InviteImpulseI1Slot> {
  bool? _shouldShow;
  bool _recordedShow = false;

  @override
  void initState() {
    super.initState();
    unawaited(_evaluate());
  }

  @override
  void didUpdateWidget(covariant InviteImpulseI1Slot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isFirstResultDisplay != widget.isFirstResultDisplay) {
      unawaited(_evaluate());
    }
  }

  Future<void> _evaluate() async {
    final result = await evaluateInviteImpulseI1(
      inviteEnabled: kInviteEnabled,
      isFirstResultDisplay: widget.isFirstResultDisplay,
      userId: ref.read(currentUserProvider)?.id,
      now: DateTime.now().toUtc(),
      isTrainingSessionActive: false,
      readLowMood: () => ref.read(moodRepositoryProvider).hasLowMoodInWindow(
            window: const Duration(hours: 24),
            maxMood: InvitePromptInput.lowMoodThreshold,
          ),
      settleUnanswered: (userId) async {
        final settled =
            await pendingInviteStore.settleUnansweredImpulse(userId);
        return settled.toPersist();
      },
      recordShown: (userId, now) async {
        if (_recordedShow) return;
        await pendingInviteStore.recordImpulseShown(
          userId: userId,
          now: now,
        );
        _recordedShow = true;
      },
    );

    if (!mounted) return;
    setState(() => _shouldShow = result.shouldShow);
  }

  Future<void> _onOpen() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null) {
      try {
        await pendingInviteStore.recordImpulseTapped(userId: userId);
      } catch (_) {
        // Navigation still proceeds; streak may retry next open.
      }
    }
    if (!mounted) return;
    setState(() => _shouldShow = false);
    context.push(Routes.invite);
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldShow != true) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: InviteImpulseCard(onOpen: () => unawaited(_onOpen())),
    );
  }
}
