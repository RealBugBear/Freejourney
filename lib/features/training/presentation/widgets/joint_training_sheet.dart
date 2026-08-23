import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';

/// One profile that could join today's session.
class JointTrainingCandidate {
  const JointTrainingCandidate({required this.profile});

  final ReflexSubjectProfile profile;
}

/// Which candidates start ticked (spec §7.2, D14).
///
/// The remembered selection wins, minus anyone who is no longer a candidate.
/// If nothing survives, everyone is ticked — the same behaviour as a first run.
List<String> defaultJointSelection({
  required List<JointTrainingCandidate> candidates,
  required List<String> remembered,
}) {
  final ids = candidates.map((candidate) => candidate.profile.id).toList();
  if (remembered.isEmpty) return ids;

  final survivors = ids.where(remembered.contains).toList();
  return survivors.isEmpty ? ids : survivors;
}

/// Asks who is training. Returns null when the user backs out.
Future<List<String>?> showJointTrainingSheet(
  BuildContext context, {
  required List<JointTrainingCandidate> candidates,
  required Set<String> preselected,
  required String confirmLabel,
}) {
  final selected = {...preselected};
  final l10n = AppLocalizations.of(context);

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.dashboardJointTrainingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboardJointTrainingBody),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              CheckboxListTile(
                key: ValueKey('joint-${candidate.profile.id}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(candidate.profile.id),
                title: Text(candidate.profile.displayName),
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    selected.add(candidate.profile.id);
                  } else {
                    selected.remove(candidate.profile.id);
                  }
                }),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}
