import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../providers/chat_providers.dart';

class TypingIndicator extends ConsumerStatefulWidget {
  const TypingIndicator({super.key, required this.channelId});
  final String channelId;

  @override
  ConsumerState<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends ConsumerState<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typingAsync = ref.watch(typingUsersProvider(widget.channelId));
    final users = typingAsync.valueOrNull ?? {};
    if (users.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 4, top: 2),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _dots,
            builder: (_, __) {
              final phase = (_dots.value * 3).floor();
              return Row(
                children: List.generate(
                    3,
                    (i) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: i == phase ? 0.7 : 0.25),
                          ),
                        )),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            l10n.chatTyping(users.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }
}
