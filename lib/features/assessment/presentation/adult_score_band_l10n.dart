import '../../../l10n/app_localizations.dart';
import '../domain/reflex_questionnaire.dart';

String adultHintBandLabel(AppLocalizations l10n, AdultHintBand band) =>
    switch (band) {
      AdultHintBand.fewMatching => l10n.adultHintBandFewMatching,
      AdultHintBand.someMatching => l10n.adultHintBandSomeMatching,
      AdultHintBand.clusteredPattern => l10n.adultHintBandClusteredPattern,
      AdultHintBand.stronglyClustered => l10n.adultHintBandStronglyClustered,
      AdultHintBand.insufficientData => l10n.adultHintBandInsufficientData,
    };

String amphibianDisplayLabel(
  AppLocalizations l10n,
  AmphibianDisplay display,
) =>
    switch (display) {
      AmphibianDisplay.insufficientData =>
        l10n.adultAmphibianInsufficientData,
      AmphibianDisplay.noneMatching => l10n.adultAmphibianNoneMatching,
      AmphibianDisplay.singleHint => l10n.adultAmphibianSingleHint,
      AmphibianDisplay.clearSingleHint => l10n.adultAmphibianClearSingleHint,
    };
