import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
import '../../domain/models/trainer_client.dart';
import '../providers/trainer_provider.dart';

const _packageNames = {
  'moro': 'Moro',
  'spinal_galant': 'Spinal Galant',
  'tlr': 'TLR',
  'babkin': 'Babkin',
  'such_saug': 'Such-Saug',
  'atnr': 'ATNR',
  'stnr': 'STNR',
  'babinski': 'Babinski',
  'landau': 'Landau',
};

class TrainerClientsScreen extends ConsumerWidget {
  const TrainerClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final clientsAsync = ref.watch(trainerClientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainerClients),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(trainerClientsProvider.notifier).refresh(),
          ),
        ],
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (clients) => clients.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        l10n.trainerNoClients,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.trainerNoClientsHint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 24),
                        const _TrainerClientsDebugPanel(),
                      ],
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(trainerClientsProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: clients.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, i) => _ClientTile(client: clients[i]),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context, ref, l10n),
        label: Text(l10n.trainerGenerateCode),
        icon: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  Future<void> _showInviteDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    // Show loading while generating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final code =
          await ref.read(trainerClientsProvider.notifier).generateInviteCode();
      if (!context.mounted) return;
      Navigator.pop(context); // close loading dialog

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.trainerInviteCode),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.trainerInviteCodeHint,
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(l10n.trainerCopyCode),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.trainerCodeCopied)),
                );
              },
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric)),
      );
    }
  }
}

class _TrainerClientsDebugPanel extends ConsumerWidget {
  const _TrainerClientsDebugPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugAsync = ref.watch(trainerClientsDebugProvider);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.35,
        );

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Diagnose Trainer-Verknüpfung',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Diagnose aktualisieren',
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: () {
                      ref.invalidate(trainerClientsDebugProvider);
                      ref.invalidate(trainerClientsProvider);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              debugAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Diagnose Fehler: $e', style: textStyle),
                data: (debug) => Text(debug, style: textStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientTile extends ConsumerWidget {
  final TrainerClient client;
  const _ClientTile({required this.client});

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);
    final packageName =
        _packageNames[client.packageId] ?? client.packageId ?? '—';
    final daysSince = client.lastActivityDate != null
        ? DateTime.now().difference(client.lastActivityDate!).inDays
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: client.isAtRisk
            ? AppColors.warning.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.1),
        child: Text(
          client.displayName[0].toUpperCase(),
          style: TextStyle(
            color: client.isAtRisk ? AppColors.warning : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              client.displayName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (client.isAtRisk)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                l10n.trainerAtRisk,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.warning,
                ),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            client.packageId != null
                ? '$packageName · ${l10n.dayNumber(client.currentDay)} · ${client.dailyStreak} Tage regelmäßig'
                : l10n.packageLocked,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13),
          ),
          if (daysSince != null)
            Text(
              l10n.trainerLastActive(daysSince),
              style: TextStyle(
                fontSize: 12,
                color: client.isAtRisk
                    ? AppColors.warning
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      trailing: SizedBox(
        width: 88,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              tooltip: 'Chat öffnen',
              onPressed: () => _openClientChat(context, ref, client.clientId),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
      onTap: () => context.push(
        Routes.trainerClientDetail.replaceFirst(':clientId', client.clientId),
        extra: client,
      ),
    );
  }

  Future<void> _openClientChat(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    await openDirectChatWithUser(context, ref, clientId);
  }
}
