import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';

/// Secondary row under a training profile: view result or start questionnaire.
class SubjectProfileReflexActionTile extends StatelessWidget {
  const SubjectProfileReflexActionTile({
    super.key,
    required this.summary,
    required this.onPressed,
  });

  final ReflexProfileSummary summary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAssessment = summary.latestAssessment != null;
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 56, right: 16),
      leading: Icon(
        hasAssessment ? Icons.assignment_outlined : Icons.note_add_outlined,
        size: 22,
      ),
      title: Text(
        hasAssessment
            ? l10n.profileViewReflexProfile
            : l10n.profileStartReflexProfile,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onPressed,
    );
  }
}
