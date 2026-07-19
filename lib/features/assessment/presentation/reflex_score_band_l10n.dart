import '../../../l10n/app_localizations.dart';
import '../domain/reflex_questionnaire.dart';

String scoreBandLabel(AppLocalizations l10n, ReflexScoreBand band) =>
    switch (band) {
      ReflexScoreBand.strong => l10n.scoreBandStrong,
      ReflexScoreBand.elevated => l10n.scoreBandElevated,
      ReflexScoreBand.indication => l10n.scoreBandIndication,
      ReflexScoreBand.inconspicuous => l10n.scoreBandInconspicuous,
      ReflexScoreBand.insufficientData => l10n.scoreBandInsufficientData,
    };
