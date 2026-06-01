import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../chat/domain/models/chat_channel.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../domain/models/experience_share.dart';
import '../providers/experience_providers.dart';
import '../widgets/experience_card.dart';

class ExperienceFeedScreen extends ConsumerWidget {
  const ExperienceFeedScreen({
    super.key,
    required this.channel,
  });

  final ChatChannel channel;

  String get _packageId => channel.packageId ?? '';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final sharesAsync = ref.watch(experienceSharesProvider(_packageId));
    final isModerator = channel.isModerator;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(channel.channelDisplayName()),
      ),
      floatingActionButton: isModerator
          ? FloatingActionButton(
              onPressed: () => _showModeratorPostSheet(context, ref),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              child: const Icon(Icons.add),
            )
          : null,
      body: sharesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Fehler: $e'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(experienceSharesProvider(_packageId)),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (shares) {
          if (shares.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_stories_outlined,
                      size: 56, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Noch keine Erfahrungen geteilt.',
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Schließe ein Training ab und teile dein Erleben.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(experienceSharesProvider(_packageId)),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
              itemCount: shares.length,
              itemBuilder: (ctx, i) {
                final share = shares[i];
                final canDelete = isModerator || share.userId == currentUserId;
                return ExperienceCard(
                  share: share,
                  isModerator: isModerator,
                  onDelete: canDelete
                      ? () => _confirmDelete(ctx, ref, share.id, isModerator)
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String shareId,
    bool isModerator,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Beitrag löschen?'),
        content: const Text('Dieser Beitrag wird unwiderruflich entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    if (isModerator) {
      await ref
          .read(deleteShareProvider.notifier)
          .deleteModerator(shareId, _packageId);
    } else {
      await ref
          .read(deleteShareProvider.notifier)
          .deleteOwn(shareId, _packageId);
    }
  }

  Future<void> _showModeratorPostSheet(
      BuildContext context, WidgetRef ref) async {
    final profile = ref.read(profileProvider).valueOrNull;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final noteController = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nachricht an die Community',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              minLines: 3,
              maxLines: 8,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Schreib eine Nachricht...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final text = noteController.text.trim();
                  if (text.isEmpty) return;
                  await ref
                      .read(experienceRepositoryProvider)
                      .createShare(ExperienceShareInsert(
                        packageId: _packageId,
                        userId: userId,
                        displayName: profile?.effectiveDisplayName ?? 'Trainer',
                        isAnonymous: false,
                        content: text,
                      ));
                  ref.invalidate(experienceSharesProvider(_packageId));
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Posten'),
              ),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
  }
}
