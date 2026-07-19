import '../../../l10n/app_localizations.dart';
import '../domain/services/reflex_profile_pdf_service.dart';

/// Builds PDF copy from the active ARB catalog.
ReflexProfilePdfCopy reflexProfilePdfCopyFromL10n(AppLocalizations l10n) {
  return ReflexProfilePdfCopy(
    title: l10n.reflexPdfTitle,
    author: l10n.appTitle,
    generatedOn: l10n.reflexPdfGeneratedOn,
    summaryNotice: l10n.reflexPdfSummaryNotice,
    safetyNotice: l10n.reflexPdfSafetyNotice,
    reflexOverviewTitle: l10n.reflexPdfOverviewTitle,
    reflexAreaHeader: l10n.reflexPdfAreaHeader,
    percentHeader: l10n.reflexPdfPercentHeader,
    classificationHeader: l10n.reflexPdfClassificationHeader,
    yesAnsweredHeader: l10n.reflexPdfYesAnsweredHeader,
    answerOverviewTitle: l10n.reflexPdfAnswersTitle,
    questionHeader: l10n.reflexPdfQuestionHeader,
    answerHeader: l10n.reflexPdfAnswerHeader,
    bandStrong: l10n.scoreBandStrong,
    bandElevated: l10n.scoreBandElevated,
    bandIndication: l10n.scoreBandIndication,
    bandInconspicuous: l10n.scoreBandInconspicuous,
    bandInsufficientData: l10n.scoreBandInsufficientData,
    answerYes: l10n.yes,
    answerNo: l10n.no,
    answerUnknown: l10n.answerUnknown,
    months: l10n.monthsCount,
    emptyAnswer: l10n.reflexPdfEmptyAnswer,
    fileNameStem: l10n.reflexPdfFileNameStem,
  );
}
