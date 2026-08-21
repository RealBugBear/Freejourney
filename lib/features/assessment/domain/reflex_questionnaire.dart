import '../../../core/l10n/localized_content.dart';

enum ReflexQuestionnaireType {
  childParentReport,
  adultSelfReport,
  demoChildShort,
}

enum ReflexQuestionModule {
  pregnancyBirth,
  posturePerception,
  motorSkills,
  behaviorEmotion,
  speech,
  drawingWriting,
  school,
  other,
}

enum ReflexAnswerType {
  yesNoUnknown,
  /// Adult main items: Ja / Nein / ? / n. z.
  yesNoUnknownNotApplicable,
  multiSelectWithText,
  monthsNumber,
  freeText,
}

enum ReflexQuestionRole {
  score,
  context,
  safety,
  movement,
}

/// Adult item polarity for scoring. Child items leave the default [direct].
enum ReflexItemPolarity {
  direct,
  inverse,
}

/// Canonical four-way adult answer choice (serialization in Phase 3).
enum ReflexAnswerChoice {
  yes,
  no,
  unknown,
  notApplicable,
}

/// Adult questionnaire modules including the app-owned filter module.
enum AdultQuestionModule {
  /// Filter module "Deine Lebenssituation" — seven `f_*` items only.
  lifeContext,
  sensory,
  postureSitting,
  motorCoordination,
  workScreenFocus,
  drivingOrientationTravel,
  sportBalanceFeet,
  speechMouthJaw,
  writingFineMotor,
  readingLearningOrientation,
  behaviorStressEmotion,
  sleepDigestionBody,
  safety,
  movementOptional,
}

/// Adult hint-strength bands (product rules, not diagnostic cut-offs).
enum AdultHintBand {
  fewMatching, // 0–29
  someMatching, // 30–59
  clusteredPattern, // 60–79
  stronglyClustered, // 80–100
  insufficientData,
}

/// Amphibian reflex special display (0/1/2 of 2), not a percent bar.
enum AmphibianDisplay {
  noneMatching,
  singleHint,
  clearSingleHint,
}

/// Life-situation filters that gate conditional adult items.
enum ApplicabilityFilter {
  swims,
  screenWork,
  deskWork,
  drives,
  ridesAsPassenger,
  handwriting,
  toolUse,
  afterSafetyCleared,
}

/// Internal content-approval marker. Does not change scoring by itself.
enum ReflexContentApprovalStatus {
  draft,
  expertPending,
  approved,
}

enum ReflexWarningRule {
  none,
  professionalClearanceRequired,
}

enum ReflexScoreBand {
  strong,
  elevated,
  indication,
  inconspicuous,
  insufficientData,
}

enum PrimitiveReflex {
  delay,
  flr,
  moro,
  spinalGalant,
  tlr,
  atnr,
  stnr,
  landau,
  babinski,
  babkin,
  plantar,
  palmar,
  righting,
  rootingSucking,
  amphibian,
}

class PrimitiveReflexCopy {
  const PrimitiveReflexCopy({
    required this.labelDe,
    required this.labelEn,
    required this.shortLabelDe,
    required this.shortLabelEn,
  });

  final String labelDe;
  final String labelEn;
  final String shortLabelDe;
  final String shortLabelEn;

  String label(String locale) =>
      pickLocalized(locale, de: labelDe, en: labelEn);
  String shortLabel(String locale) =>
      pickLocalized(locale, de: shortLabelDe, en: shortLabelEn);
}

extension PrimitiveReflexLocalization on PrimitiveReflex {
  PrimitiveReflexCopy get copy => switch (this) {
        PrimitiveReflex.delay => const PrimitiveReflexCopy(
            labelDe: 'Entwicklungsverzögerung',
            labelEn: 'Early Development',
            shortLabelDe: 'Verzög.',
            shortLabelEn: 'Development',
          ),
        PrimitiveReflex.flr => const PrimitiveReflexCopy(
            labelDe: 'FLR',
            labelEn: 'Fear Paralysis Reflex (FPR)',
            shortLabelDe: 'FLR',
            shortLabelEn: 'FPR',
          ),
        PrimitiveReflex.moro => const PrimitiveReflexCopy(
            labelDe: 'Moro',
            labelEn: 'Moro Reflex',
            shortLabelDe: 'Moro',
            shortLabelEn: 'Moro',
          ),
        PrimitiveReflex.spinalGalant => const PrimitiveReflexCopy(
            labelDe: 'Spinaler Galant',
            labelEn: 'Spinal Galant Reflex',
            shortLabelDe: 'Galant',
            shortLabelEn: 'Galant',
          ),
        PrimitiveReflex.tlr => const PrimitiveReflexCopy(
            labelDe: 'TLR',
            labelEn: 'Tonic Labyrinthine Reflex (TLR)',
            shortLabelDe: 'TLR',
            shortLabelEn: 'TLR',
          ),
        PrimitiveReflex.atnr => const PrimitiveReflexCopy(
            labelDe: 'ATNR',
            labelEn: 'Asymmetrical Tonic Neck Reflex (ATNR)',
            shortLabelDe: 'ATNR',
            shortLabelEn: 'ATNR',
          ),
        PrimitiveReflex.stnr => const PrimitiveReflexCopy(
            labelDe: 'STNR',
            labelEn: 'Symmetrical Tonic Neck Reflex (STNR)',
            shortLabelDe: 'STNR',
            shortLabelEn: 'STNR',
          ),
        PrimitiveReflex.landau => const PrimitiveReflexCopy(
            labelDe: 'Landau',
            labelEn: 'Landau Reflex',
            shortLabelDe: 'Landau',
            shortLabelEn: 'Landau',
          ),
        PrimitiveReflex.babinski => const PrimitiveReflexCopy(
            labelDe: 'Babinski',
            labelEn: 'Babinski Reflex',
            shortLabelDe: 'Babinski',
            shortLabelEn: 'Babinski',
          ),
        PrimitiveReflex.babkin => const PrimitiveReflexCopy(
            labelDe: 'Babkin',
            labelEn: 'Babkin Reflex',
            shortLabelDe: 'Babkin',
            shortLabelEn: 'Babkin',
          ),
        PrimitiveReflex.plantar => const PrimitiveReflexCopy(
            labelDe: 'Plantar',
            labelEn: 'Plantar Reflex',
            shortLabelDe: 'Plantar',
            shortLabelEn: 'Plantar',
          ),
        PrimitiveReflex.palmar => const PrimitiveReflexCopy(
            labelDe: 'Palmar',
            labelEn: 'Palmar Reflex',
            shortLabelDe: 'Palmar',
            shortLabelEn: 'Palmar',
          ),
        PrimitiveReflex.righting => const PrimitiveReflexCopy(
            labelDe: 'Aufricht',
            labelEn: 'Righting Reflexes',
            shortLabelDe: 'Aufr.',
            shortLabelEn: 'Righting',
          ),
        PrimitiveReflex.rootingSucking => const PrimitiveReflexCopy(
            labelDe: 'Such-Saug',
            labelEn: 'Rooting-Sucking Reflex',
            shortLabelDe: 'Such',
            shortLabelEn: 'Root/Suck',
          ),
        PrimitiveReflex.amphibian => const PrimitiveReflexCopy(
            labelDe: 'Amphibienreflex',
            labelEn: 'Amphibian Reflex',
            shortLabelDe: 'Amphib.',
            shortLabelEn: 'Amphib.',
          ),
      };

  String label(String locale) => copy.label(locale);
  String shortLabel(String locale) => copy.shortLabel(locale);
}

class ReflexQuestionnaireDefinition {
  const ReflexQuestionnaireDefinition({
    required this.id,
    required this.version,
    required this.type,
    required this.titleDe,
    required this.titleEn,
    required this.screenTitleDe,
    required this.screenTitleEn,
    required this.questions,
    required this.scoring,
  });

  final String id;
  final String version;
  final ReflexQuestionnaireType type;
  final String titleDe;
  final String titleEn;
  final String screenTitleDe;
  final String screenTitleEn;
  final List<ReflexQuestion> questions;
  final ReflexScoringDefinition scoring;

  String title(String locale) =>
      pickLocalized(locale, de: titleDe, en: titleEn);
  String screenTitle(String locale) =>
      pickLocalized(locale, de: screenTitleDe, en: screenTitleEn);
}

class ReflexQuestion {
  const ReflexQuestion({
    required this.id,
    required this.number,
    required this.module,
    required this.textDe,
    required this.textEn,
    required this.answerType,
    this.role = ReflexQuestionRole.score,
    this.reflexes = const [],
    this.warningRule = ReflexWarningRule.none,
    this.helpTextDe,
    this.helpTextEn,
    this.followUpOf,
    this.options = const [],
    this.excludeFromAdminScience = false,
    this.trainerFlagLabelDe,
    this.trainerFlagLabelEn,
    this.polarity = ReflexItemPolarity.direct,
    this.adultModule,
    this.requiresFilters = const {},
    this.providesFilter,
    this.approvalStatus = ReflexContentApprovalStatus.approved,
  });

  final String id;
  final int number;

  /// Child module. Adult items that set [adultModule] use
  /// [ReflexQuestionModule.other] here as an unused placeholder.
  final ReflexQuestionModule module;
  final String textDe;
  final String textEn;
  final ReflexAnswerType answerType;
  final ReflexQuestionRole role;
  final List<PrimitiveReflex> reflexes;
  final ReflexWarningRule warningRule;
  final String? helpTextDe;
  final String? helpTextEn;
  final String? followUpOf;
  final List<ReflexQuestionOption> options;
  final bool excludeFromAdminScience;

  /// Short label shown to trainers when this question is answered "yes".
  /// Set on both clearance-required questions and other clinically relevant ones.
  final String? trainerFlagLabelDe;
  final String? trainerFlagLabelEn;

  /// Scoring polarity. Child catalog leaves the default [direct].
  final ReflexItemPolarity polarity;

  /// Adult module grouping. Null for child/demo catalogs.
  final AdultQuestionModule? adultModule;

  /// All listed filters must not be answered "no" for the item to be visible.
  final Set<ApplicabilityFilter> requiresFilters;

  /// When set, answering this context item drives the named filter.
  final ApplicabilityFilter? providesFilter;

  final ReflexContentApprovalStatus approvalStatus;

  String text(String locale) =>
      pickLocalized(locale, de: textDe, en: textEn);
  String? helpText(String locale) =>
      pickLocalized(locale, de: helpTextDe, en: helpTextEn);
  String? trainerFlagLabel(String locale) =>
      pickLocalized(locale, de: trainerFlagLabelDe, en: trainerFlagLabelEn);

  bool get contributesToScore =>
      role == ReflexQuestionRole.score && reflexes.isNotEmpty;
}

class ReflexQuestionModuleCopy {
  const ReflexQuestionModuleCopy({
    required this.titleDe,
    required this.titleEn,
    required this.resultLabelDe,
    required this.resultLabelEn,
  });

  final String titleDe;
  final String titleEn;
  final String resultLabelDe;
  final String resultLabelEn;

  String title(String locale) =>
      pickLocalized(locale, de: titleDe, en: titleEn);
  String resultLabel(String locale) =>
      pickLocalized(locale, de: resultLabelDe, en: resultLabelEn);
}

extension ReflexQuestionModuleLocalization on ReflexQuestionModule {
  ReflexQuestionModuleCopy get copy => switch (this) {
        ReflexQuestionModule.pregnancyBirth => const ReflexQuestionModuleCopy(
            titleDe: 'Schwangerschaft und Geburt',
            titleEn: 'Pregnancy and Birth',
            resultLabelDe: 'Schwangerschaft & Geburt',
            resultLabelEn: 'Pregnancy & Birth',
          ),
        ReflexQuestionModule.posturePerception =>
          const ReflexQuestionModuleCopy(
            titleDe: 'Körperhaltung und Wahrnehmung',
            titleEn: 'Posture and Perception',
            resultLabelDe: 'Haltung & Wahrnehmung',
            resultLabelEn: 'Posture & Perception',
          ),
        ReflexQuestionModule.motorSkills => const ReflexQuestionModuleCopy(
            titleDe: 'Motorik',
            titleEn: 'Motor Skills',
            resultLabelDe: 'Motorik',
            resultLabelEn: 'Motor Skills',
          ),
        ReflexQuestionModule.behaviorEmotion => const ReflexQuestionModuleCopy(
            titleDe: 'Verhalten und Gefühle',
            titleEn: 'Behavior and Emotions',
            resultLabelDe: 'Verhalten & Emotionen',
            resultLabelEn: 'Behavior & Emotions',
          ),
        ReflexQuestionModule.speech => const ReflexQuestionModuleCopy(
            titleDe: 'Sprache und Sprechen',
            titleEn: 'Speech and Language',
            resultLabelDe: 'Sprache',
            resultLabelEn: 'Speech',
          ),
        ReflexQuestionModule.drawingWriting => const ReflexQuestionModuleCopy(
            titleDe: 'Malen und Schreiben',
            titleEn: 'Drawing and Writing',
            resultLabelDe: 'Zeichnen & Schreiben',
            resultLabelEn: 'Drawing & Writing',
          ),
        ReflexQuestionModule.school => const ReflexQuestionModuleCopy(
            titleDe: 'Schule',
            titleEn: 'School',
            resultLabelDe: 'Schule & Konzentration',
            resultLabelEn: 'School & Concentration',
          ),
        ReflexQuestionModule.other => const ReflexQuestionModuleCopy(
            titleDe: 'Sonstiges',
            titleEn: 'Other',
            resultLabelDe: 'Weitere Beobachtungen',
            resultLabelEn: 'Other Observations',
          ),
      };

  String title(String locale) => copy.title(locale);
  String resultLabel(String locale) => copy.resultLabel(locale);
}

class AdultQuestionModuleCopy {
  const AdultQuestionModuleCopy({
    required this.titleDe,
    required this.titleEn,
  });

  final String titleDe;
  final String titleEn;

  String title(String locale) =>
      pickLocalized(locale, de: titleDe, en: titleEn);
}

extension AdultQuestionModuleLocalization on AdultQuestionModule {
  AdultQuestionModuleCopy get copy => switch (this) {
        AdultQuestionModule.lifeContext => const AdultQuestionModuleCopy(
            titleDe: 'Deine Lebenssituation',
            titleEn: 'Your life situation',
          ),
        AdultQuestionModule.sensory => const AdultQuestionModuleCopy(
            titleDe: 'Sinneswahrnehmung und Reizverarbeitung',
            titleEn: 'Sensory perception and stimulus processing',
          ),
        AdultQuestionModule.postureSitting => const AdultQuestionModuleCopy(
            titleDe: 'Körperhaltung und Sitzen',
            titleEn: 'Posture and sitting',
          ),
        AdultQuestionModule.motorCoordination => const AdultQuestionModuleCopy(
            titleDe: 'Motorik und Koordination',
            titleEn: 'Motor skills and coordination',
          ),
        AdultQuestionModule.workScreenFocus => const AdultQuestionModuleCopy(
            titleDe: 'Arbeit, Bildschirm und Konzentration',
            titleEn: 'Work, screen and concentration',
          ),
        AdultQuestionModule.drivingOrientationTravel =>
          const AdultQuestionModuleCopy(
            titleDe: 'Autofahren, Orientierung und Reisen',
            titleEn: 'Driving, orientation and travel',
          ),
        AdultQuestionModule.sportBalanceFeet => const AdultQuestionModuleCopy(
            titleDe: 'Sport, Gleichgewicht und Füße',
            titleEn: 'Sport, balance and feet',
          ),
        AdultQuestionModule.speechMouthJaw => const AdultQuestionModuleCopy(
            titleDe: 'Sprache, Mund und Kiefer',
            titleEn: 'Speech, mouth and jaw',
          ),
        AdultQuestionModule.writingFineMotor => const AdultQuestionModuleCopy(
            titleDe: 'Schreiben und Feinmotorik',
            titleEn: 'Writing and fine motor skills',
          ),
        AdultQuestionModule.readingLearningOrientation =>
          const AdultQuestionModuleCopy(
            titleDe: 'Lesen, Lernen und Orientierung',
            titleEn: 'Reading, learning and orientation',
          ),
        AdultQuestionModule.behaviorStressEmotion =>
          const AdultQuestionModuleCopy(
            titleDe: 'Verhalten, Stress und Gefühle',
            titleEn: 'Behaviour, stress and feelings',
          ),
        AdultQuestionModule.sleepDigestionBody => const AdultQuestionModuleCopy(
            titleDe: 'Schlaf, Verdauung und Körper',
            titleEn: 'Sleep, digestion and body',
          ),
        AdultQuestionModule.safety => const AdultQuestionModuleCopy(
            titleDe: 'Sicherheitsfragen',
            titleEn: 'Safety questions',
          ),
        AdultQuestionModule.movementOptional => const AdultQuestionModuleCopy(
            titleDe: 'Freiwillige Bewegungsprüfungen',
            titleEn: 'Optional movement checks',
          ),
      };

  String title(String locale) => copy.title(locale);
}

class ReflexQuestionOption {
  const ReflexQuestionOption({
    required this.id,
    required this.label,
    this.adminMetricId,
  });

  final String id;
  final String label;
  final String? adminMetricId;
}

class ReflexScoringDefinition {
  const ReflexScoringDefinition({
    required this.strongPercent,
    required this.elevatedPercent,
    required this.indicationPercent,
  });

  final int strongPercent;
  final int elevatedPercent;
  final int indicationPercent;

  ReflexScoreBand bandFor({
    required double percent,
    required int answeredCount,
  }) {
    if (answeredCount == 0) return ReflexScoreBand.insufficientData;
    if (percent >= strongPercent) return ReflexScoreBand.strong;
    if (percent >= elevatedPercent) return ReflexScoreBand.elevated;
    if (percent >= indicationPercent) return ReflexScoreBand.indication;
    return ReflexScoreBand.inconspicuous;
  }
}

class ReflexAnswerValue {
  const ReflexAnswerValue({
    this.yesNoUnknown,
    this.isUnknown = false,
    this.isNotApplicable = false,
    this.selectedOptionIds = const [],
    this.text,
    this.months,
  });

  final bool? yesNoUnknown;
  final bool isUnknown;

  /// Adult-only: "trifft auf meine Lebenssituation nicht zu".
  /// Child serialization must never set this.
  final bool isNotApplicable;
  final List<String> selectedOptionIds;
  final String? text;
  final int? months;

  bool get isAnswered =>
      yesNoUnknown != null ||
      isUnknown ||
      isNotApplicable ||
      selectedOptionIds.isNotEmpty ||
      (text != null && text!.trim().isNotEmpty) ||
      months != null;

  bool get isAffirmative => yesNoUnknown == true;

  /// Unified adult/child choice view. Null when the value is free-text/months/etc.
  ReflexAnswerChoice? get choice {
    if (isNotApplicable) return ReflexAnswerChoice.notApplicable;
    if (isUnknown) return ReflexAnswerChoice.unknown;
    if (yesNoUnknown == true) return ReflexAnswerChoice.yes;
    if (yesNoUnknown == false) return ReflexAnswerChoice.no;
    return null;
  }

  factory ReflexAnswerValue.fromChoice(ReflexAnswerChoice choice) {
    return switch (choice) {
      ReflexAnswerChoice.yes =>
        const ReflexAnswerValue(yesNoUnknown: true),
      ReflexAnswerChoice.no =>
        const ReflexAnswerValue(yesNoUnknown: false),
      ReflexAnswerChoice.unknown =>
        const ReflexAnswerValue(isUnknown: true),
      ReflexAnswerChoice.notApplicable =>
        const ReflexAnswerValue(isNotApplicable: true),
    };
  }
}

class ReflexWarningConfirmation {
  const ReflexWarningConfirmation({
    required this.questionId,
    required this.confirmedAt,
    required this.messageVersion,
  });

  final String questionId;
  final DateTime confirmedAt;
  final String messageVersion;
}
