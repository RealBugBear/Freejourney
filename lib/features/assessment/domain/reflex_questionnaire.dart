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
  multiSelectWithText,
  monthsNumber,
  freeText,
}

enum ReflexQuestionRole {
  score,
  context,
  safety,
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

  String label(String locale) => locale == 'de' ? labelDe : labelEn;
  String shortLabel(String locale) =>
      locale == 'de' ? shortLabelDe : shortLabelEn;
}

extension PrimitiveReflexLocalization on PrimitiveReflex {
  PrimitiveReflexCopy get copy => switch (this) {
        PrimitiveReflex.delay => const PrimitiveReflexCopy(
            labelDe: 'Entwicklungsverzögerung',
            labelEn: 'Developmental Delay',
            shortLabelDe: 'Verzög.',
            shortLabelEn: 'Delay',
          ),
        PrimitiveReflex.flr => const PrimitiveReflexCopy(
            labelDe: 'FLR',
            labelEn: 'FPR',
            shortLabelDe: 'FLR',
            shortLabelEn: 'FPR',
          ),
        PrimitiveReflex.moro => const PrimitiveReflexCopy(
            labelDe: 'Moro',
            labelEn: 'Moro',
            shortLabelDe: 'Moro',
            shortLabelEn: 'Moro',
          ),
        PrimitiveReflex.spinalGalant => const PrimitiveReflexCopy(
            labelDe: 'Spinaler Galant',
            labelEn: 'Spinal Galant',
            shortLabelDe: 'Galant',
            shortLabelEn: 'Galant',
          ),
        PrimitiveReflex.tlr => const PrimitiveReflexCopy(
            labelDe: 'TLR',
            labelEn: 'TLR',
            shortLabelDe: 'TLR',
            shortLabelEn: 'TLR',
          ),
        PrimitiveReflex.atnr => const PrimitiveReflexCopy(
            labelDe: 'ATNR',
            labelEn: 'ATNR',
            shortLabelDe: 'ATNR',
            shortLabelEn: 'ATNR',
          ),
        PrimitiveReflex.stnr => const PrimitiveReflexCopy(
            labelDe: 'STNR',
            labelEn: 'STNR',
            shortLabelDe: 'STNR',
            shortLabelEn: 'STNR',
          ),
        PrimitiveReflex.landau => const PrimitiveReflexCopy(
            labelDe: 'Landau',
            labelEn: 'Landau',
            shortLabelDe: 'Landau',
            shortLabelEn: 'Landau',
          ),
        PrimitiveReflex.babinski => const PrimitiveReflexCopy(
            labelDe: 'Babinski',
            labelEn: 'Babinski',
            shortLabelDe: 'Babinski',
            shortLabelEn: 'Babinski',
          ),
        PrimitiveReflex.babkin => const PrimitiveReflexCopy(
            labelDe: 'Babkin',
            labelEn: 'Babkin',
            shortLabelDe: 'Babkin',
            shortLabelEn: 'Babkin',
          ),
        PrimitiveReflex.plantar => const PrimitiveReflexCopy(
            labelDe: 'Plantar',
            labelEn: 'Plantar',
            shortLabelDe: 'Plantar',
            shortLabelEn: 'Plantar',
          ),
        PrimitiveReflex.palmar => const PrimitiveReflexCopy(
            labelDe: 'Palmar',
            labelEn: 'Palmar',
            shortLabelDe: 'Palmar',
            shortLabelEn: 'Palmar',
          ),
        PrimitiveReflex.righting => const PrimitiveReflexCopy(
            labelDe: 'Aufricht',
            labelEn: 'Righting',
            shortLabelDe: 'Aufr.',
            shortLabelEn: 'Righting',
          ),
        PrimitiveReflex.rootingSucking => const PrimitiveReflexCopy(
            labelDe: 'Such-Saug',
            labelEn: 'Rooting/Sucking',
            shortLabelDe: 'Such',
            shortLabelEn: 'Root/Suck',
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

  String title(String locale) => locale == 'de' ? titleDe : titleEn;
  String screenTitle(String locale) =>
      locale == 'de' ? screenTitleDe : screenTitleEn;
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
  });

  final String id;
  final int number;
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

  String text(String locale) => locale == 'de' ? textDe : textEn;
  String? helpText(String locale) => locale == 'de' ? helpTextDe : helpTextEn;
  String? trainerFlagLabel(String locale) =>
      locale == 'de' ? trainerFlagLabelDe : trainerFlagLabelEn;

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

  String title(String locale) => locale == 'de' ? titleDe : titleEn;
  String resultLabel(String locale) =>
      locale == 'de' ? resultLabelDe : resultLabelEn;
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
    this.selectedOptionIds = const [],
    this.text,
    this.months,
  });

  final bool? yesNoUnknown;
  final bool isUnknown;
  final List<String> selectedOptionIds;
  final String? text;
  final int? months;

  bool get isAnswered =>
      yesNoUnknown != null ||
      isUnknown ||
      selectedOptionIds.isNotEmpty ||
      (text != null && text!.trim().isNotEmpty) ||
      months != null;

  bool get isAffirmative => yesNoUnknown == true;
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
