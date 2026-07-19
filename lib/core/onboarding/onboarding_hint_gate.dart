import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'onboarding_hint_provider.dart';

class OnboardingHintGate extends ConsumerStatefulWidget {
  const OnboardingHintGate({
    super.key,
    required this.hint,
    required this.child,
  });

  final AppOnboardingHint hint;
  final Widget child;

  @override
  ConsumerState<OnboardingHintGate> createState() => _OnboardingHintGateState();
}

class _OnboardingHintGateState extends ConsumerState<OnboardingHintGate> {
  bool _queued = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(onboardingHintControllerProvider);
    final controller = ref.read(onboardingHintControllerProvider.notifier);

    if (!_queued && controller.shouldShow(widget.hint)) {
      _queued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _showHintSheet(context, ref, widget.hint);
        if (mounted) _queued = false;
      });
    }

    return widget.child;
  }
}

Future<void> _showHintSheet(
  BuildContext context,
  WidgetRef ref,
  AppOnboardingHint hint,
) async {
  final controller = ref.read(onboardingHintControllerProvider.notifier);
  if (!controller.shouldShow(hint)) return;

  final dismissPermanently = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _OnboardingHintSheet(hint: hint),
  );

  if (dismissPermanently == true) {
    await controller.hidePermanently(hint);
  } else {
    controller.dismissForSession(hint);
  }
}

class _OnboardingHintSheet extends StatefulWidget {
  const _OnboardingHintSheet({required this.hint});

  final AppOnboardingHint hint;

  @override
  State<_OnboardingHintSheet> createState() => _OnboardingHintSheetState();
}

class _OnboardingHintSheetState extends State<_OnboardingHintSheet> {
  bool _dontShowAgain = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final content = widget.hint.content(l10n);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(_iconFor(widget.hint), color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        content.body,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...content.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _itemIcon(item.iconName),
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.text,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              value: _dontShowAgain,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.hintDontShowAgain),
              onChanged: (value) =>
                  setState(() => _dontShowAgain = value ?? false),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Navigator.pop(context, _dontShowAgain),
              child: Text(l10n.hintGotIt),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.hintShowLater),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppOnboardingHint hint) => switch (hint) {
        AppOnboardingHint.dashboard => Icons.home_outlined,
        AppOnboardingHint.progress => Icons.insights_outlined,
        AppOnboardingHint.accompaniment => Icons.handshake_outlined,
        AppOnboardingHint.profile => Icons.person_outline,
      };

  IconData _itemIcon(String name) => switch (name) {
        'account' => Icons.manage_accounts_outlined,
        'book' => Icons.menu_book_outlined,
        'calendar' => Icons.event_available_outlined,
        'chart' => Icons.insights_outlined,
        'chat' => Icons.chat_bubble_outline,
        'check' => Icons.check_circle_outline,
        'note' => Icons.edit_note_outlined,
        'play' => Icons.play_arrow_rounded,
        'settings' => Icons.settings_outlined,
        'trainer' => Icons.person_search_outlined,
        'work' => Icons.work_outline,
        _ => Icons.info_outline,
      };
}
