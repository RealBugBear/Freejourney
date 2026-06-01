import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/navigation/app_router.dart';
import '../providers/chat_providers.dart';

class DirectMessagesAction extends ConsumerWidget {
  const DirectMessagesAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSignedIn = _isSignedIn();
    if (!isSignedIn) {
      return const SizedBox.shrink();
    }

    final unread = ref.watch(totalUnreadCountProvider);

    return IconButton(
      tooltip: 'Nachrichten',
      onPressed: () => context.push(Routes.dm),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: unread > 99 ? const Text('99+') : Text('$unread'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }

  bool _isSignedIn() {
    try {
      return Supabase.instance.client.auth.currentUser != null;
    } on AssertionError {
      return false;
    }
  }
}
