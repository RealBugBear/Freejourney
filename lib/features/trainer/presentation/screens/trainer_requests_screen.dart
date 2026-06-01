import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/trainer_discovery_request.dart';
import '../providers/trainer_provider.dart';
import '../providers/trainer_discovery_provider.dart';

class TrainerRequestsScreen extends ConsumerWidget {
  const TrainerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncRequests = ref.watch(incomingRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.trainerRequestsTitle)),
      body: asyncRequests.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(child: Text(l10n.trainerRequestNoRequests));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _RequestCard(request: requests[i]),
          );
        },
      ),
    );
  }
}

class _RequestCard extends ConsumerStatefulWidget {
  const _RequestCard({required this.request});

  final TrainerDiscoveryRequest request;

  @override
  ConsumerState<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<_RequestCard> {
  bool _isResponding = false;

  Future<void> _respond({required bool accept}) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    try {
      await ref
          .read(incomingRequestsProvider.notifier)
          .respond(widget.request.relationshipId, accept: accept);
      ref.invalidate(trainerClientsProvider);
      ref.invalidate(trainerRecentObservationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              accept
                  ? 'Anfrage angenommen. Der Klient erscheint jetzt in deiner Übersicht.'
                  : 'Anfrage abgelehnt.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.request.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.request.createdAt.toLocal().toString().substring(0, 10),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed:
                        _isResponding ? null : () => _respond(accept: true),
                    child: Text(l10n.trainerRequestAccept),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isResponding ? null : () => _respond(accept: false),
                    child: Text(l10n.trainerRequestDecline),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
