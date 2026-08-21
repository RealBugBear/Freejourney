import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/storage/pending_invite_store.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/models/invite_overview.dart';
import '../providers/invite_providers.dart';
import '../widgets/impact_tree_card.dart';

/// Inviter home: impact tree, share action, personal code.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  static const _inviteLandingBase = 'https://reflexjourney.app/einladung';

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  int? _previousActivatedCount;
  bool _previousLoaded = false;
  bool _didPersistCurrent = false;
  String? _loadedForUserId;

  Future<void> _loadPreviousCount(String userId) async {
    final previous = await pendingInviteStore.readLastActivatedCount(userId);
    if (!mounted) return;
    setState(() {
      _previousActivatedCount = previous;
      _previousLoaded = true;
      _loadedForUserId = userId;
      _didPersistCurrent = false;
    });
  }

  Future<void> _rememberCount(String userId, int count) async {
    await pendingInviteStore.saveLastActivatedCount(
      userId: userId,
      count: count,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overview = ref.watch(inviteOverviewProvider);
    final userId = ref.watch(currentUserProvider)?.id;

    if (userId != null && userId != _loadedForUserId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (ref.read(currentUserProvider)?.id != userId) return;
        unawaited(_loadPreviousCount(userId));
      });
    }

    final previousForUser =
        userId != null && _loadedForUserId == userId && _previousLoaded
            ? _previousActivatedCount
            : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inviteTitle)),
      body: SafeArea(
        child: overview.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _InviteBody(
            overview: null,
            loadFailed: true,
            previousActivatedCount: previousForUser,
            onRetry: () => ref.invalidate(inviteOverviewProvider),
          ),
          data: (data) {
            if (userId != null &&
                _previousLoaded &&
                _loadedForUserId == userId &&
                !_didPersistCurrent) {
              _didPersistCurrent = true;
              unawaited(_rememberCount(userId, data.activatedCount));
            }
            return _InviteBody(
              overview: data,
              loadFailed: false,
              previousActivatedCount: previousForUser,
              onRetry: () => ref.invalidate(inviteOverviewProvider),
            );
          },
        ),
      ),
    );
  }
}

class _InviteBody extends ConsumerWidget {
  const _InviteBody({
    required this.overview,
    required this.loadFailed,
    required this.previousActivatedCount,
    required this.onRetry,
  });

  final InviteOverview? overview;
  final bool loadFailed;
  final int? previousActivatedCount;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final code = overview?.code;
    final count = overview?.activatedCount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ImpactTreeCard(
          activatedCount: count ?? 0,
          previousActivatedCount: previousActivatedCount,
        ),
        if (loadFailed) ...[
          const SizedBox(height: 12),
          Text(l10n.inviteErrorOffline, style: theme.textTheme.bodyMedium),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              tooltip: l10n.inviteErrorOffline,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(l10n.inviteWhy, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 20),
        FilledButton(
          onPressed:
              code == null ? null : () => _share(context, ref, l10n, code),
          child: Text(l10n.inviteShareAction),
        ),
        const SizedBox(height: 20),
        Text(l10n.inviteCodeLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        if (code != null)
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  code,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.inviteCodeCopied,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: code));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.inviteCodeCopied)),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          )
        else
          Text(l10n.inviteErrorOffline, style: theme.textTheme.bodyMedium),
        const SizedBox(height: 24),
        Text(
          l10n.invitePrivacyFootnote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _share(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String code,
  ) async {
    final link = '${InviteScreen._inviteLandingBase}?c=$code';
    final message = l10n.inviteShareMessage(link);
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? const Rect.fromLTWH(1, 1, 1, 1)
        : box.localToGlobal(Offset.zero) & box.size;
    try {
      await ref.read(inviteActionsProvider.notifier).logShareActionTapped();
    } catch (_) {
      // Measurement must not block sharing.
    }
    await Share.share(message, sharePositionOrigin: origin);
  }
}
