import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Asks the client to confirm ending the accompaniment.
///
/// Returns `true` only on an explicit confirmation. Every consequence is named
/// in the body: the dialog is the only place the client learns that reflex
/// profile access, messaging and open appointments all end at once.
Future<bool?> showEndAccompanimentDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(l10n.accompanimentEndDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Consequence(text: l10n.accompanimentEndConsequenceProfiles),
            _Consequence(text: l10n.accompanimentEndConsequenceChat),
            _Consequence(text: l10n.accompanimentEndConsequenceAppointments),
            const SizedBox(height: 12),
            Text(
              l10n.accompanimentEndTrainerNotice,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.accompanimentEndReconnectHint,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('end_accompaniment_confirm'),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accompanimentEndConfirm),
          ),
        ],
      );
    },
  );
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.remove_circle_outline, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
