import '../../../core/l10n/localized_content.dart';
import 'reflex_questionnaire.dart';

/// Per-reflex explanation copy for the adult result detail tiles.
///
/// Where approved specialist wording is not yet available, entries use a
/// neutral placeholder and [ReflexContentApprovalStatus.expertPending].
/// Do not invent diagnostic, causal or treatment-effect language.
class AdultReflexResultCopy {
  const AdultReflexResultCopy({
    required this.reflex,
    required this.shortDescriptionDe,
    required this.shortDescriptionEn,
    required this.alternativeExplanationsDe,
    required this.alternativeExplanationsEn,
    required this.limitsDe,
    required this.limitsEn,
    required this.optionalPhysicalCheckHintDe,
    required this.optionalPhysicalCheckHintEn,
    this.approvalStatus = ReflexContentApprovalStatus.expertPending,
  });

  final PrimitiveReflex reflex;
  final String shortDescriptionDe;
  final String shortDescriptionEn;
  final String alternativeExplanationsDe;
  final String alternativeExplanationsEn;
  final String limitsDe;
  final String limitsEn;
  final String optionalPhysicalCheckHintDe;
  final String optionalPhysicalCheckHintEn;
  final ReflexContentApprovalStatus approvalStatus;

  String shortDescription(String locale) =>
      pickLocalized(locale, de: shortDescriptionDe, en: shortDescriptionEn);

  String alternativeExplanations(String locale) => pickLocalized(
        locale,
        de: alternativeExplanationsDe,
        en: alternativeExplanationsEn,
      );

  String limits(String locale) =>
      pickLocalized(locale, de: limitsDe, en: limitsEn);

  String optionalPhysicalCheckHint(String locale) => pickLocalized(
        locale,
        de: optionalPhysicalCheckHintDe,
        en: optionalPhysicalCheckHintEn,
      );
}

const _pendingShortDe =
    'Kurze Beschreibung folgt nach fachlicher Freigabe.';
const _pendingShortEn =
    'A short description will follow after specialist review.';
const _pendingAltDe =
    'Mögliche Alternativerklärungen folgen nach fachlicher Freigabe.';
const _pendingAltEn =
    'Possible alternative explanations will follow after specialist review.';
const _pendingLimitsDe =
    'Dieses Ergebnis zeigt nur dein Antwortmuster. Es stellt keinen '
    'Reflexnachweis fest und ersetzt keine persönliche Einschätzung.';
const _pendingLimitsEn =
    'This result only shows your answer pattern. It does not establish a '
    'reflex finding and does not replace a personal assessment.';
const _pendingCheckDe =
    'Eine persönliche körperliche Überprüfung durch eine entsprechend '
    'qualifizierte Person kann zusätzliche Orientierung geben.';
const _pendingCheckEn =
    'A personal physical check by an appropriately qualified person can '
    'provide additional orientation.';

AdultReflexResultCopy _pending(PrimitiveReflex reflex) {
  return AdultReflexResultCopy(
    reflex: reflex,
    shortDescriptionDe: _pendingShortDe,
    shortDescriptionEn: _pendingShortEn,
    alternativeExplanationsDe: _pendingAltDe,
    alternativeExplanationsEn: _pendingAltEn,
    limitsDe: _pendingLimitsDe,
    limitsEn: _pendingLimitsEn,
    optionalPhysicalCheckHintDe: _pendingCheckDe,
    optionalPhysicalCheckHintEn: _pendingCheckEn,
  );
}

/// Adult-relevant reflexes only (no child-only [PrimitiveReflex.delay]).
final Map<PrimitiveReflex, AdultReflexResultCopy> adultReflexResultCopyByReflex =
    {
  for (final reflex in const [
    PrimitiveReflex.flr,
    PrimitiveReflex.moro,
    PrimitiveReflex.spinalGalant,
    PrimitiveReflex.tlr,
    PrimitiveReflex.atnr,
    PrimitiveReflex.stnr,
    PrimitiveReflex.landau,
    PrimitiveReflex.babinski,
    PrimitiveReflex.babkin,
    PrimitiveReflex.plantar,
    PrimitiveReflex.palmar,
    PrimitiveReflex.righting,
    PrimitiveReflex.rootingSucking,
    PrimitiveReflex.amphibian,
  ])
    reflex: _pending(reflex),
};

AdultReflexResultCopy? adultReflexResultCopyFor(PrimitiveReflex reflex) =>
    adultReflexResultCopyByReflex[reflex];
