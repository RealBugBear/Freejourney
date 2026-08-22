import '../../../l10n/app_localizations.dart';
import '../domain/services/reflex_profile_pdf_service.dart';

/// Builds PDF copy from the active ARB catalog.
ReflexProfilePdfCopy reflexProfilePdfCopyFromL10n(AppLocalizations l10n) {
  return ReflexProfilePdfCopy(
    title: l10n.reflexPdfTitle,
    author: l10n.appTitle,
    headerMeta: l10n.reflexPdfHeaderMeta,
    summaryNotice: l10n.reflexPdfSummaryNotice,
    safetyNotice: l10n.reflexPdfSafetyNotice,
    reflexListTitle: l10n.reflexPdfOverviewTitle,
    bandStrong: l10n.scoreBandStrong,
    bandElevated: l10n.scoreBandElevated,
    bandIndication: l10n.scoreBandIndication,
    bandInconspicuous: l10n.scoreBandInconspicuous,
    bandInsufficientData: l10n.scoreBandInsufficientData,
    adultBandFewMatching: l10n.adultHintBandFewMatching,
    adultBandSomeMatching: l10n.adultHintBandSomeMatching,
    adultBandClusteredPattern: l10n.adultHintBandClusteredPattern,
    adultBandStronglyClustered: l10n.adultHintBandStronglyClustered,
    adultBandInsufficientData: l10n.adultHintBandInsufficientData,
    amphibianInsufficientData: l10n.adultAmphibianInsufficientData,
    amphibianNoneMatching: l10n.adultAmphibianNoneMatching,
    amphibianSingleHint: l10n.adultAmphibianSingleHint,
    amphibianClearSingleHint: l10n.adultAmphibianClearSingleHint,
    childDataBasis: l10n.reflexResultYesOfAnswered,
    adultDataBasis: l10n.adultResultFeaturesAnswered,
    fileNameStem: l10n.reflexPdfFileNameStem,
  );
}
