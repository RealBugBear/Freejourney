import 'dart:convert';

import '../../../../core/l10n/localized_content.dart';
import '../content/moro_media_manifest.dart';

const defaultExerciseSafetyNoteDe =
    'Stoppe bei Schmerzen, Schwindel, Übelkeit oder deutlichem Unwohlsein. '
    'Lass anhaltende Beschwerden fachlich abklären.';
const defaultExerciseSafetyNoteEn =
    'Stop if you feel pain, dizziness, nausea, or significant discomfort. '
    'Seek professional advice if symptoms persist.';

/// Accepts only secure, absolute remote media URLs.
///
/// Remote media is an optional overlay. Invalid values resolve to null so the
/// bundled content remains the dependable offline source.
String? validatedRemoteMediaUrl(Object? value) {
  if (value is! String) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
  return normalized;
}

// ── Rhythm types ──────────────────────────────────────────────────────────────

enum RhythmType {
  /// Counted phases (e.g. 3 s up, 1 s hold, 3 s down). Used for Moro 1–5.
  phased,

  /// Hold N seconds with countdown, then rest M seconds. Used for Moro 6–7,
  /// Spinal Galant and TLR exercises.
  holdRest,
}

/// One timed phase within a phased exercise.
class ExercisePhase {
  final String labelDe;
  final String labelEn;
  final int durationSeconds;

  const ExercisePhase({
    required this.labelDe,
    required this.labelEn,
    required this.durationSeconds,
  });

  String label(String locale) =>
      pickLocalized(locale, de: labelDe, en: labelEn);
}

// ── Exercise model ────────────────────────────────────────────────────────────

class Exercise {
  final String id;
  final String packageId;
  final int sequenceNumber;
  final String titleDe;
  final String titleEn;
  final List<String> positionInstructionsDe;
  final List<String> positionInstructionsEn;
  final List<String> movementInstructionsDe;
  final List<String> movementInstructionsEn;
  final List<String>? hintsDe;
  final List<String>? hintsEn;
  final List<String>? positionInstructionsDuoDe;
  final List<String>? positionInstructionsDuoEn;
  final List<String>? movementInstructionsDuoDe;
  final List<String>? movementInstructionsDuoEn;
  final String executionGuideDe;
  final String executionGuideEn;
  final String orientationDe;
  final String orientationEn;
  final String? breathingDe;
  final String? breathingEn;
  final String routineCueDe;
  final String routineCueEn;
  final String safetyNoteDe;
  final String safetyNoteEn;
  final int durationSeconds;
  final int repetitions;
  final String imagePath;
  final String? duoImagePath;
  final String? videoPath;
  final String? audioCuePath;
  final String? imageUrl;
  final String? duoImageUrl;
  final String? videoUrl;

  // ── Rhythm config ──────────────────────────────────────────────────────────
  final RhythmType rhythmType;

  /// Phase sequence for [RhythmType.phased].
  final List<ExercisePhase> phases;

  /// Whether to announce "Wechsel" / "Switch" between reps (side-switching).
  final bool hasRepSwitch;

  /// Action word spoken at the start of each hold (e.g. "Spannung", "Halten").
  final String holdCueDe;
  final String holdCueEn;

  /// Seconds to hold per rep for [RhythmType.holdRest].
  final int holdSeconds;

  /// Seconds to rest between reps for [RhythmType.holdRest].
  final int restSeconds;

  /// Announce "Armkreuz wechseln" at the midpoint rep (e.g. Moro 6 + 7).
  final bool halfwaySwitch;

  const Exercise({
    required this.id,
    required this.packageId,
    required this.sequenceNumber,
    required this.titleDe,
    required this.titleEn,
    required this.positionInstructionsDe,
    required this.positionInstructionsEn,
    required this.movementInstructionsDe,
    required this.movementInstructionsEn,
    this.hintsDe,
    this.hintsEn,
    this.positionInstructionsDuoDe,
    this.positionInstructionsDuoEn,
    this.movementInstructionsDuoDe,
    this.movementInstructionsDuoEn,
    required this.executionGuideDe,
    required this.executionGuideEn,
    this.orientationDe = '',
    this.orientationEn = '',
    this.breathingDe,
    this.breathingEn,
    this.routineCueDe = '',
    this.routineCueEn = '',
    this.safetyNoteDe = defaultExerciseSafetyNoteDe,
    this.safetyNoteEn = defaultExerciseSafetyNoteEn,
    required this.durationSeconds,
    required this.repetitions,
    required this.imagePath,
    this.duoImagePath,
    this.videoPath,
    this.audioCuePath,
    this.imageUrl,
    this.duoImageUrl,
    this.videoUrl,
    // Rhythm defaults — works for all holdRest exercises without explicit config
    this.rhythmType = RhythmType.holdRest,
    this.phases = const [],
    this.hasRepSwitch = false,
    this.holdCueDe = 'Halten',
    this.holdCueEn = 'Hold',
    this.holdSeconds = 7,
    this.restSeconds = 3,
    this.halfwaySwitch = false,
  });

  int get exerciseNumber => sequenceNumber;

  String title(String locale) =>
      pickLocalized(locale, de: titleDe, en: titleEn);
  List<String> positionInstructions(String locale) => pickLocalized(locale,
      de: positionInstructionsDe, en: positionInstructionsEn);
  List<String> movementInstructions(String locale) => pickLocalized(locale,
      de: movementInstructionsDe, en: movementInstructionsEn);
  List<String> positionInstructionsFor(String locale, {bool duo = false}) {
    if (duo) {
      final instructions = pickLocalized(locale,
          de: positionInstructionsDuoDe, en: positionInstructionsDuoEn);
      if (instructions != null && instructions.isNotEmpty) return instructions;
    }
    return positionInstructions(locale);
  }

  List<String> movementInstructionsFor(String locale, {bool duo = false}) {
    if (duo) {
      final instructions = pickLocalized(locale,
          de: movementInstructionsDuoDe, en: movementInstructionsDuoEn);
      if (instructions != null && instructions.isNotEmpty) return instructions;
    }
    return movementInstructions(locale);
  }

  String imagePathFor({bool duo = false}) {
    if (duo && duoImagePath != null && duoImagePath!.isNotEmpty) {
      return duoImagePath!;
    }
    return imagePath;
  }

  bool get hasBundledImage => imagePath.trim().isNotEmpty;

  /// Returns the remote Supabase Storage URL for this exercise's image.
  /// Prefers duo URL when [duo] is true and one is available.
  String? imageUrlFor({bool duo = false}) {
    if (duo && duoImageUrl != null && duoImageUrl!.isNotEmpty) {
      return duoImageUrl;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    return null;
  }

  List<String>? hints(String locale) =>
      pickLocalized(locale, de: hintsDe, en: hintsEn);
  String executionGuide(String locale) =>
      pickLocalized(locale, de: executionGuideDe, en: executionGuideEn);
  String orientation(String locale) {
    final value =
        pickLocalized(locale, de: orientationDe, en: orientationEn).trim();
    return value.isEmpty ? executionGuide(locale) : value;
  }

  String? breathing(String locale) {
    final value = pickLocalized(locale, de: breathingDe, en: breathingEn);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }

  String routineCue(String locale) {
    final value =
        pickLocalized(locale, de: routineCueDe, en: routineCueEn).trim();
    return value.isEmpty ? executionGuide(locale) : value;
  }

  String safetyNote(String locale) =>
      pickLocalized(locale, de: safetyNoteDe, en: safetyNoteEn);

  Exercise withRemoteMedia({
    String? imageUrl,
    String? duoImageUrl,
    String? videoUrl,
  }) {
    return Exercise(
      id: id,
      packageId: packageId,
      sequenceNumber: sequenceNumber,
      titleDe: titleDe,
      titleEn: titleEn,
      positionInstructionsDe: positionInstructionsDe,
      positionInstructionsEn: positionInstructionsEn,
      movementInstructionsDe: movementInstructionsDe,
      movementInstructionsEn: movementInstructionsEn,
      hintsDe: hintsDe,
      hintsEn: hintsEn,
      positionInstructionsDuoDe: positionInstructionsDuoDe,
      positionInstructionsDuoEn: positionInstructionsDuoEn,
      movementInstructionsDuoDe: movementInstructionsDuoDe,
      movementInstructionsDuoEn: movementInstructionsDuoEn,
      executionGuideDe: executionGuideDe,
      executionGuideEn: executionGuideEn,
      orientationDe: orientationDe,
      orientationEn: orientationEn,
      breathingDe: breathingDe,
      breathingEn: breathingEn,
      routineCueDe: routineCueDe,
      routineCueEn: routineCueEn,
      safetyNoteDe: safetyNoteDe,
      safetyNoteEn: safetyNoteEn,
      durationSeconds: durationSeconds,
      repetitions: repetitions,
      imagePath: imagePath,
      duoImagePath: duoImagePath,
      videoPath: videoPath,
      audioCuePath: audioCuePath,
      imageUrl: validatedRemoteMediaUrl(imageUrl),
      duoImageUrl: validatedRemoteMediaUrl(duoImageUrl),
      videoUrl: validatedRemoteMediaUrl(videoUrl),
      rhythmType: rhythmType,
      phases: phases,
      hasRepSwitch: hasRepSwitch,
      holdCueDe: holdCueDe,
      holdCueEn: holdCueEn,
      holdSeconds: holdSeconds,
      restSeconds: restSeconds,
      halfwaySwitch: halfwaySwitch,
    );
  }

  // ── Deserialisation from Supabase row ───────────────────────────────────────

  static List<String> _decodeStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>();
    // Stored as JSON string in Drift
    final decoded = jsonDecode(value as String);
    return (decoded as List).cast<String>();
  }

  static List<String>? _decodeNullableStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      final list = value.cast<String>();
      return list.isEmpty ? null : list;
    }
    final decoded = jsonDecode(value as String);
    final list = (decoded as List).cast<String>();
    return list.isEmpty ? null : list;
  }

  static List<ExercisePhase> _decodePhases(dynamic value) {
    if (value == null) return [];
    final List<dynamic> raw =
        value is String ? jsonDecode(value) : value as List;
    return raw.map((e) {
      final m = e as Map<String, dynamic>;
      return ExercisePhase(
        labelDe: m['labelDe'] as String,
        labelEn: m['labelEn'] as String,
        durationSeconds: m['durationSeconds'] as int,
      );
    }).toList();
  }

  /// Create an [Exercise] from a Supabase REST response row or a Drift DB row.
  /// Both sources are Map<String, dynamic>; Supabase returns Postgres arrays as
  /// List<dynamic>, Drift stores them as JSON strings.
  factory Exercise.fromRow(Map<String, dynamic> row) {
    final rhythmStr = row['rhythm_type'] as String? ?? 'holdRest';
    final rhythm =
        rhythmStr == 'phased' ? RhythmType.phased : RhythmType.holdRest;
    final id = row['id'] as String;
    final rawImagePath = row['image_path'] as String;

    return Exercise(
      id: id,
      packageId: row['package_id'] as String,
      sequenceNumber: row['sequence_number'] as int,
      titleDe: row['title_de'] as String,
      titleEn: row['title_en'] as String,
      positionInstructionsDe:
          _decodeStringList(row['position_instructions_de']),
      positionInstructionsEn:
          _decodeStringList(row['position_instructions_en']),
      movementInstructionsDe:
          _decodeStringList(row['movement_instructions_de']),
      movementInstructionsEn:
          _decodeStringList(row['movement_instructions_en']),
      hintsDe: _decodeNullableStringList(row['hints_de']),
      hintsEn: _decodeNullableStringList(row['hints_en']),
      executionGuideDe: row['execution_guide_de'] as String,
      executionGuideEn: row['execution_guide_en'] as String,
      orientationDe: row['orientation_de'] as String? ?? '',
      orientationEn: row['orientation_en'] as String? ?? '',
      breathingDe: row['breathing_de'] as String?,
      breathingEn: row['breathing_en'] as String?,
      routineCueDe: row['routine_cue_de'] as String? ?? '',
      routineCueEn: row['routine_cue_en'] as String? ?? '',
      safetyNoteDe:
          row['safety_note_de'] as String? ?? defaultExerciseSafetyNoteDe,
      safetyNoteEn:
          row['safety_note_en'] as String? ?? defaultExerciseSafetyNoteEn,
      durationSeconds: row['duration_seconds'] as int,
      repetitions: row['repetitions'] as int,
      imagePath: rawImagePath,
      duoImagePath: row['duo_image_path'] as String?,
      videoPath: row['video_path'] as String?,
      audioCuePath: row['audio_cue_path'] as String?,
      imageUrl: validatedRemoteMediaUrl(row['image_url']),
      duoImageUrl: validatedRemoteMediaUrl(row['duo_image_url']),
      videoUrl: validatedRemoteMediaUrl(row['video_url']),
      rhythmType: rhythm,
      phases: _decodePhases(row['phases_json']),
      hasRepSwitch: row['has_rep_switch'] as bool? ?? false,
      holdCueDe: row['hold_cue_de'] as String? ?? 'Halten',
      holdCueEn: row['hold_cue_en'] as String? ?? 'Hold',
      holdSeconds: row['hold_seconds'] as int? ?? 7,
      restSeconds: row['rest_seconds'] as int? ?? 3,
      halfwaySwitch: row['halfway_switch'] as bool? ?? false,
    );
  }
}

// ── Shared phase sets ─────────────────────────────────────────────────────────

/// Standard 3-3 lift: up 3 s, hold 1 s, down 3 s  (Moro 3, 5)
const _phasesUpHoldDown = [
  ExercisePhase(labelDe: 'Hoch', labelEn: 'Up', durationSeconds: 3),
  ExercisePhase(labelDe: 'Halten', labelEn: 'Hold', durationSeconds: 1),
  ExercisePhase(labelDe: 'Runter', labelEn: 'Down', durationSeconds: 3),
];

/// 3-3 slide: up 3 s, down 3 s  (Moro 3 – same visual but no explicit hold)
const _phasesUpDown = [
  ExercisePhase(labelDe: 'Hoch', labelEn: 'Up', durationSeconds: 3),
  ExercisePhase(labelDe: 'Runter', labelEn: 'Down', durationSeconds: 3),
];

/// 3-3 frog: in 3 s, out 3 s  (Moro 4)
const _phasesInOut = [
  ExercisePhase(labelDe: 'Ran', labelEn: 'In', durationSeconds: 3),
  ExercisePhase(labelDe: 'Zurück', labelEn: 'Back', durationSeconds: 3),
];

/// 4-phase knees: right 3 s, centre 3 s, left 3 s, centre 3 s  (Moro 1)
const _phasesKnees = [
  ExercisePhase(labelDe: 'Rechts', labelEn: 'Right', durationSeconds: 3),
  ExercisePhase(labelDe: 'Mitte', labelEn: 'Centre', durationSeconds: 3),
  ExercisePhase(labelDe: 'Links', labelEn: 'Left', durationSeconds: 3),
  ExercisePhase(labelDe: 'Mitte', labelEn: 'Centre', durationSeconds: 3),
];

/// Roll-up: exhale cue 1 s, roll up 3 s, hold 1 s, lower 2 s  (Moro 2)
const _phasesRollUp = [
  ExercisePhase(labelDe: 'Ausatmen', labelEn: 'Exhale', durationSeconds: 1),
  ExercisePhase(labelDe: 'Hochrollen', labelEn: 'Roll up', durationSeconds: 3),
  ExercisePhase(labelDe: 'Halten', labelEn: 'Hold', durationSeconds: 1),
  ExercisePhase(labelDe: 'Ablegen', labelEn: 'Lower', durationSeconds: 2),
];

/// Breathing: inhale 3 s, exhale 4 s  (TLR 4)
const _phasesBreathing = [
  ExercisePhase(labelDe: 'Einatmen', labelEn: 'Inhale', durationSeconds: 3),
  ExercisePhase(labelDe: 'Ausatmen', labelEn: 'Exhale', durationSeconds: 4),
];

// ============================================================================
// MORO PACKAGE — 7 exercises
// ============================================================================

const List<Exercise> moroExercises = [
  // Exercise 1 of 7 — Moro 5
  Exercise(
    id: 'moro_ex1',
    packageId: 'moro',
    sequenceNumber: 1,
    titleDe: 'Moro 5',
    titleEn: 'Moro 5',
    positionInstructionsDe: [
      'Lege dich auf den Rücken und strecke beide Beine aus.',
      'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.',
    ],
    positionInstructionsEn: [
      'Lie on your back with both legs extended.',
      'Rest your arms alongside your body with your palms facing down.',
    ],
    movementInstructionsDe: [
      'Hebe ein Bein in 3 Sekunden an. Lege es auf dem Schienbein des ruhenden Beins ab.',
      'Halte 1 Sekunde.',
      'Führe das Bein in 3 Sekunden zurück.',
      'Wechsle für die nächste Wiederholung die Seite.',
    ],
    movementInstructionsEn: [
      'Raise one leg for 3 seconds. Rest it on the shin of the still leg.',
      'Hold for 1 second.',
      'Return the leg for 3 seconds.',
      'Switch sides before the next repetition.',
    ],
    hintsDe: [
      'Halte das ruhende Bein und dein Becken stabil am Boden.',
    ],
    hintsEn: [
      'Keep the resting leg and your pelvis steady on the floor.',
    ],
    executionGuideDe:
        'Hebe ein Bein an, halte kurz und führe es kontrolliert zurück.',
    executionGuideEn:
        'Raise one leg, hold briefly, and return it with control.',
    orientationDe:
        'Du hebst abwechselnd ein Bein an und legst es auf dem anderen Schienbein ab.',
    orientationEn:
        'You alternately raise one leg and rest it on the opposite shin.',
    breathingDe: 'Atme ruhig und gleichmäßig weiter.',
    breathingEn: 'Keep breathing calmly and evenly.',
    routineCueDe: 'Bein hoch – halten – zurück – Seite wechseln.',
    routineCueEn: 'Leg up – hold – return – switch sides.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: moroExercise1ImagePath,
    rhythmType: RhythmType.phased,
    phases: _phasesUpHoldDown,
    hasRepSwitch: true,
  ),

  // Exercise 2 of 7 — Moro 3 – Halber Frosch
  Exercise(
    id: 'moro_ex2',
    packageId: 'moro',
    sequenceNumber: 2,
    titleDe: 'Moro 3 – Halber Frosch',
    titleEn: 'Moro 3 – Half Frog',
    positionInstructionsDe: [
      'Lege dich auf den Rücken und strecke beide Beine aus.',
      'Lass beide Beine gerade und entspannt nebeneinander liegen.',
    ],
    positionInstructionsEn: [
      'Lie on your back with both legs extended.',
      'Let both legs rest straight and relaxed beside each other.',
    ],
    movementInstructionsDe: [
      'Lass eine Fußsohle in 3 Sekunden an der Innenseite des anderen Beins zum Körper gleiten.',
      'Führe den Fuß in 3 Sekunden zurück, bis das Bein wieder gestreckt ist.',
      'Wechsle für die nächste Wiederholung die Seite.',
    ],
    movementInstructionsEn: [
      'Slide one sole along the inside of the other leg toward your body for 3 seconds.',
      'Slide the foot back for 3 seconds until the leg is straight again.',
      'Switch sides before the next repetition.',
    ],
    hintsDe: [
      'Halte die Fußsohle während der gesamten Bewegung am anderen Bein.',
      'Beende den Bewegungsumfang, bevor der Kontakt verloren geht.',
    ],
    hintsEn: [
      'Keep the sole in contact with the other leg throughout the movement.',
      'End the movement before you lose that contact.',
    ],
    executionGuideDe:
        'Lass eine Fußsohle am anderen Bein hoch- und zurückgleiten.',
    executionGuideEn: 'Slide one sole up and back along the other leg.',
    orientationDe:
        'Du lässt abwechselnd einen Fuß am anderen Bein entlanggleiten.',
    orientationEn: 'You alternately slide one foot along the opposite leg.',
    breathingDe: 'Atme ruhig und gleichmäßig weiter.',
    breathingEn: 'Keep breathing calmly and evenly.',
    routineCueDe: 'Fuß hochgleiten – zurück – Seite wechseln.',
    routineCueEn: 'Slide foot up – return – switch sides.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: moroExercise2ImagePath,
    rhythmType: RhythmType.phased,
    phases: _phasesUpDown,
    hasRepSwitch: true,
  ),

  // Exercise 3 of 7 — Moro 4 – Frosch
  Exercise(
    id: 'moro_ex3',
    packageId: 'moro',
    sequenceNumber: 3,
    titleDe: 'Moro 4 – Frosch',
    titleEn: 'Moro 4 – Frog',
    positionInstructionsDe: [
      'Lege dich auf den Rücken und strecke beide Beine aus.',
      'Führe die Fußsohlen zusammen.',
    ],
    positionInstructionsEn: [
      'Lie on your back with both legs extended.',
      'Bring the soles of your feet together.',
    ],
    movementInstructionsDe: [
      'Führe beide Füße in 3 Sekunden zum Körper. Lass die Knie nach außen sinken.',
      'Führe die Füße in 3 Sekunden zurück.',
    ],
    movementInstructionsEn: [
      'Bring both feet toward your body for 3 seconds. Let your knees open outward.',
      'Return your feet for 3 seconds.',
    ],
    hintsDe: [
      'Halte die Fußsohlen während der gesamten Bewegung aneinander.',
      'Wähle nur einen Bewegungsumfang, bei dem der Kontakt bestehen bleibt.',
    ],
    hintsEn: [
      'Keep the soles together throughout the movement.',
      'Move only as far as you can maintain that contact.',
    ],
    executionGuideDe:
        'Führe die Füße zum Körper und kontrolliert wieder zurück.',
    executionGuideEn:
        'Bring your feet toward your body and return with control.',
    orientationDe: 'Du führst beide Füße gemeinsam in einer Froschbewegung.',
    orientationEn: 'You move both feet together in a frog movement.',
    breathingDe: 'Atme ruhig und gleichmäßig weiter.',
    breathingEn: 'Keep breathing calmly and evenly.',
    routineCueDe: 'Füße heran – Knie öffnen – Füße zurück.',
    routineCueEn: 'Feet in – knees open – feet back.',
    durationSeconds: 35,
    repetitions: 3,
    imagePath: moroExercise3ImagePath,
    rhythmType: RhythmType.phased,
    phases: _phasesInOut,
    hasRepSwitch: false,
  ),

  // Exercise 4 of 7 — Moro 1
  Exercise(
    id: 'moro_ex4',
    packageId: 'moro',
    sequenceNumber: 4,
    titleDe: 'Moro 1',
    titleEn: 'Moro 1',
    positionInstructionsDe: [
      'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.',
      'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.',
    ],
    positionInstructionsEn: [
      'Lie on your back. Place your feet on the floor and keep your knees together.',
      'Rest your arms alongside your body with your palms facing down.',
    ],
    movementInstructionsDe: [
      'Führe beide Knie in 3 Sekunden nach rechts.',
      'Führe sie in 3 Sekunden zur Mitte zurück.',
      'Führe beide Knie in 3 Sekunden nach links.',
      'Führe sie in 3 Sekunden zur Mitte zurück.',
    ],
    movementInstructionsEn: [
      'Lower both knees to the right for 3 seconds.',
      'Return them to the centre for 3 seconds.',
      'Lower both knees to the left for 3 seconds.',
      'Return them to the centre for 3 seconds.',
    ],
    hintsDe: [
      'Halte dein Becken stabil am Boden.',
      'Bewege die Knie nur so weit, wie das Becken ruhig bleibt.',
    ],
    hintsEn: [
      'Keep your pelvis steady on the floor.',
      'Move your knees only as far as your pelvis stays still.',
    ],
    executionGuideDe:
        'Führe beide Knie kontrolliert nach rechts, zur Mitte, nach links und zurück.',
    executionGuideEn:
        'Move both knees with control to the right, centre, left, and back.',
    orientationDe:
        'Du bewegst beide Knie kontrolliert von der Mitte zu jeder Seite.',
    orientationEn:
        'You move both knees with control from the centre to each side.',
    breathingDe: 'Atme ruhig weiter und halte die Luft nicht an.',
    breathingEn: 'Keep breathing calmly without holding your breath.',
    routineCueDe: 'Rechts – Mitte – links – Mitte.',
    routineCueEn: 'Right – centre – left – centre.',
    durationSeconds: 45,
    repetitions: 3,
    imagePath: moroExercise4ImagePath,
    rhythmType: RhythmType.phased,
    phases: _phasesKnees,
    hasRepSwitch: false,
  ),

  // Exercise 5 of 7 — Moro 2
  Exercise(
    id: 'moro_ex5',
    packageId: 'moro',
    sequenceNumber: 5,
    titleDe: 'Moro 2',
    titleEn: 'Moro 2',
    positionInstructionsDe: [
      'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.',
      'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.',
    ],
    positionInstructionsEn: [
      'Lie on your back. Place your feet on the floor and keep your knees together.',
      'Rest your arms alongside your body with your palms facing down.',
    ],
    movementInstructionsDe: [
      'Beginne auszuatmen.',
      'Rolle Kopf und Oberkörper in 3 Sekunden an. Bewege die Stirn Richtung Knie.',
      'Halte 1 Sekunde.',
      'Lege Kopf und Oberkörper in 2 Sekunden ab.',
    ],
    movementInstructionsEn: [
      'Begin to exhale.',
      'Curl your head and upper body up for 3 seconds. Move your forehead toward your knees.',
      'Hold for 1 second.',
      'Lower your head and upper body for 2 seconds.',
    ],
    hintsDe: [
      'Lege bei Bedarf die offenen Hände an die Schienbeine.',
      'Unterstütze dich nur leicht. Ziehe nicht mit den Armen.',
    ],
    hintsEn: [
      'If needed, place your open hands on your shins.',
      'Use only light support. Do not pull with your arms.',
    ],
    executionGuideDe:
        'Atme aus, rolle den Oberkörper an und lege ihn kontrolliert ab.',
    executionGuideEn:
        'Exhale, curl your upper body up, and lower with control.',
    orientationDe: 'Du rollst Kopf und Oberkörper mit der Ausatmung an.',
    orientationEn: 'You curl your head and upper body up as you exhale.',
    breathingDe: 'Atme beim Anrollen aus. Atme danach ruhig weiter.',
    breathingEn: 'Exhale as you curl up. Then continue breathing calmly.',
    routineCueDe: 'Ausatmen – hochrollen – halten – ablegen.',
    routineCueEn: 'Exhale – curl up – hold – lower.',
    durationSeconds: 30,
    repetitions: 3,
    imagePath: moroExercise5ImagePath,
    rhythmType: RhythmType.phased,
    phases: _phasesRollUp,
    hasRepSwitch: false,
  ),

  // Exercise 6 of 7 — Moro 6 – Isometrischer Gegendruck
  Exercise(
    id: 'moro_ex6',
    packageId: 'moro',
    sequenceNumber: 6,
    titleDe: 'Moro 6 – Isometrischer Gegendruck',
    titleEn: 'Moro 6 – Isometric Counterpressure',
    positionInstructionsDe: [
      'Lege dich auf den Rücken und winkle beide Beine an.',
      'Lege die überkreuzten Hände auf Knie oder Schienbeine.',
    ],
    positionInstructionsEn: [
      'Lie on your back with both legs bent.',
      'Place your crossed hands on your knees or shins.',
    ],
    movementInstructionsDe: [
      'Ziehe die Beine leicht zum Körper. Halte mit den Händen kontrolliert dagegen und hebe den Kopf etwas an.',
      'Halte den Gegendruck 7 Sekunden.',
      'Löse die Spannung für 3 Sekunden.',
      'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.',
    ],
    movementInstructionsEn: [
      'Draw your legs gently toward your body. Resist with your hands and lift your head slightly.',
      'Hold the counterpressure for 7 seconds.',
      'Release the tension for 3 seconds.',
      'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.',
    ],
    hintsDe: [
      'Baue die Spannung gleichmäßig auf. Vermeide ruckartige Bewegungen.',
    ],
    hintsEn: [
      'Build the tension evenly. Avoid sudden or jerky movement.',
    ],
    executionGuideDe:
        'Baue leichten Gegendruck auf, halte und löse kontrolliert.',
    executionGuideEn:
        'Build gentle counterpressure, hold, and release with control.',
    orientationDe:
        'Du hältst einen gleichmäßigen Gegendruck zwischen Beinen und gekreuzten Händen.',
    orientationEn:
        'You maintain even counterpressure between your legs and crossed hands.',
    breathingDe: 'Atme während der 7 Sekunden durch den Mund aus.',
    breathingEn: 'Exhale through your mouth during the 7-second hold.',
    routineCueDe: 'Spannung und ausatmen – lösen – Armkreuz wechseln.',
    routineCueEn: 'Tension and exhale – release – switch arm cross.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: moroExercise6ImagePath,
    rhythmType: RhythmType.holdRest,
    holdCueDe: 'Spannung',
    holdCueEn: 'Tension',
    holdSeconds: 7,
    restSeconds: 3,
    halfwaySwitch: true,
  ),

  // Exercise 7 of 7 — Moro 7 – Überkreuzter Gegendruck
  Exercise(
    id: 'moro_ex7',
    packageId: 'moro',
    sequenceNumber: 7,
    titleDe: 'Moro 7 – Überkreuzter Gegendruck',
    titleEn: 'Moro 7 – Crossed Counterpressure',
    positionInstructionsDe: [
      'Lege dich auf den Rücken und winkle beide Beine an.',
      'Lege die überkreuzten Hände auf Oberschenkel oder Knie.',
    ],
    positionInstructionsEn: [
      'Lie on your back with both legs bent.',
      'Place your crossed hands on your thighs or knees.',
    ],
    movementInstructionsDe: [
      'Ziehe beide Beine zum Körper. Drücke mit den Händen kontrolliert dagegen und hebe den Kopf leicht Richtung Brust.',
      'Halte den Gegendruck 7 Sekunden.',
      'Löse die Spannung für 3 Sekunden.',
      'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.',
    ],
    movementInstructionsEn: [
      'Draw both legs toward your body. Resist with your hands and lift your head slightly toward your chest.',
      'Hold the counterpressure for 7 seconds.',
      'Release the tension for 3 seconds.',
      'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.',
    ],
    hintsDe: [
      'Halte die Bewegung klein und die Spannung gleichmäßig.',
    ],
    hintsEn: [
      'Keep the movement small and the tension even.',
    ],
    executionGuideDe:
        'Lass Beine und Hände kontrolliert gegeneinander arbeiten.',
    executionGuideEn:
        'Let your legs and hands work against each other with control.',
    orientationDe:
        'Du arbeitest mit überkreuzten Händen gegen den Zug beider Beine.',
    orientationEn: 'You use crossed hands to resist the pull of both legs.',
    breathingDe: 'Atme während der 7 Sekunden aus.',
    breathingEn: 'Exhale during the 7-second hold.',
    routineCueDe: 'Ziehen und ausatmen – lösen – Armkreuz wechseln.',
    routineCueEn: 'Pull and exhale – release – switch arm cross.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: moroExercise7ImagePath,
    rhythmType: RhythmType.holdRest,
    holdCueDe: 'Spannung',
    holdCueEn: 'Tension',
    holdSeconds: 7,
    restSeconds: 3,
    halfwaySwitch: true,
  ),
];

// ============================================================================
// SPINALER GALANT + AMPHIBIEN — 4 Übungen  (all holdRest 7-3)
// ============================================================================

const List<Exercise> spinalGalantExercises = [
  Exercise(
    id: 'sg_ex1',
    packageId: 'spinal_galant',
    sequenceNumber: 1,
    titleDe: 'Körperschaukeln',
    titleEn: 'Body Rocking',
    positionInstructionsDe: [
      'Rückenlage',
      'Füße aufstellen, Knie gebeugt',
      'Arme locker neben dem Körper',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Feet placed, knees bent',
      'Arms relaxed alongside the body',
    ],
    movementInstructionsDe: [
      'Mit den Füßen abstemmen und den Körper sanft vor und zurück schaukeln',
      'Der Kopf rollt dabei entspannt mit',
      '7 Sekunden halten, 3 Sekunden Pause',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Push gently with the feet and rock the body forward and back',
      'The head rolls along relaxed',
      'Hold 7 seconds, 3 seconds rest',
      '6 repetitions',
    ],
    executionGuideDe: 'Körper sanft schaukeln, Kopf rollt mit.',
    executionGuideEn: 'Rock body gently, head rolls along.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_01.png',
    holdCueDe: 'Schaukeln',
    holdCueEn: 'Rock',
  ),
  Exercise(
    id: 'sg_ex2',
    packageId: 'spinal_galant',
    sequenceNumber: 2,
    titleDe: 'Hüftschaukeln',
    titleEn: 'Hip Rocking',
    positionInstructionsDe: [
      'Rückenlage oder auf dem Boden sitzend',
      'Finger nicht verschränken',
    ],
    positionInstructionsEn: [
      'Lie on your back or sit on the floor',
      'Do not interlace fingers',
    ],
    movementInstructionsDe: [
      'Den Po langsam hin und her schaukeln',
      'Finger dabei nicht verschränken',
      '7 Sekunden pro Seite halten, 3 Sekunden Pause',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Gently rock the hips side to side',
      'Do not interlace fingers',
      'Hold 7 seconds per side, 3 seconds rest',
      '6 repetitions',
    ],
    executionGuideDe: 'Po sanft hin und her schaukeln.',
    executionGuideEn: 'Gently rock hips side to side.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_02.png',
    holdCueDe: 'Schaukeln',
    holdCueEn: 'Rock',
  ),
  Exercise(
    id: 'sg_ex3',
    packageId: 'spinal_galant',
    sequenceNumber: 3,
    titleDe: 'Einseitiger Frosch (Bauchlage)',
    titleEn: 'One-Legged Frog (Prone)',
    positionInstructionsDe: [
      'Bauchlage',
      'Ein Bein in Froschposition seitlich anwinkeln',
      'Finger nicht verschränken',
    ],
    positionInstructionsEn: [
      'Lie on your stomach',
      'One leg bent to the side in frog position',
      'Do not interlace fingers',
    ],
    movementInstructionsDe: [
      'Position halten',
      'Finger nicht verschränken',
      '7 Sekunden halten, 3 Sekunden Pause',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Hold the position',
      'Do not interlace fingers',
      'Hold 7 seconds, 3 seconds rest',
      '6 repetitions',
    ],
    executionGuideDe: 'Position halten. Finger nicht verschränken.',
    executionGuideEn: 'Hold position. Do not interlace fingers.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_03.png',
    holdCueDe: 'Halten',
    holdCueEn: 'Hold',
  ),
  Exercise(
    id: 'sg_ex4',
    packageId: 'spinal_galant',
    sequenceNumber: 4,
    titleDe: 'Hüftrotation (Bauchlage)',
    titleEn: 'Hip Rotation (Prone)',
    positionInstructionsDe: [
      'Bauchlage',
      'Arme im rechten Winkel neben dem Kopf, in Linie mit dem Körper',
      'Bei Bedarf ein Kissen unter den Po legen',
    ],
    positionInstructionsEn: [
      'Lie on your stomach',
      'Arms at right angles beside the head, in line with the body',
      'Place a pillow under the hips if needed',
    ],
    movementInstructionsDe: [
      'Hüfte langsam rotieren',
      'Arme bleiben im rechten Winkel neben dem Kopf',
      'Die Hüftrotation ist wichtig — auf die Qualität achten',
      '7 Sekunden halten, 3 Sekunden Pause',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Slowly rotate the hips',
      'Arms stay at right angles beside the head',
      'Hip rotation is key — focus on quality',
      'Hold 7 seconds, 3 seconds rest',
      '6 repetitions',
    ],
    hintsDe: [
      'Wenn die Übung zu schwer ist oder Schmerzen auftreten: Kissen unter den Po legen'
    ],
    hintsEn: [
      'If you feel pain, stop the exercise. If the movement only feels too difficult, place a pillow under your hips to reduce the range.'
    ],
    executionGuideDe: 'Hüfte rotieren. Arme im rechten Winkel.',
    executionGuideEn: 'Rotate hips. Arms at right angles.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_04.png',
    holdCueDe: 'Drehen',
    holdCueEn: 'Rotate',
  ),
];

// ============================================================================
// TLR — TONISCHER LABIRINTH REFLEX — 5 Übungen
// ============================================================================

const List<Exercise> tlrExercises = [
  Exercise(
    id: 'tlr_ex1',
    packageId: 'tlr',
    sequenceNumber: 1,
    titleDe: 'Kopf mitschaukeln',
    titleEn: 'Head Rolling',
    positionInstructionsDe: [
      'Rückenlage',
      'Basisposition einnehmen',
      'Arme locker neben dem Körper',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Take basic position',
      'Arms relaxed alongside the body',
    ],
    movementInstructionsDe: [
      'Körper sanft schaukeln',
      'Kopf rollt beim Schaukeln entspannt mit',
      '7 Sekunden halten, 3 Sekunden Pause',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Gently rock the body',
      'Head rolls along relaxed during rocking',
      'Hold 7 seconds, 3 seconds rest',
      '6 repetitions',
    ],
    executionGuideDe: 'Körper schaukeln, Kopf rollt entspannt mit.',
    executionGuideEn: 'Rock body, head rolls along relaxed.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath: 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_01.png',
    holdCueDe: 'Schaukeln',
    holdCueEn: 'Rock',
  ),

  Exercise(
    id: 'tlr_ex2',
    packageId: 'tlr',
    sequenceNumber: 2,
    titleDe: 'Über-Kopf-Rollen',
    titleEn: 'Over-Head Roll',
    positionInstructionsDe: [
      'Vierfüßlerstand oder Kniestand',
      'Meistes Gewicht auf den Händen',
      'Kopf hängt locker',
    ],
    positionInstructionsEn: [
      'All-fours or kneeling position',
      'Most weight on the hands',
      'Head hangs loose',
    ],
    movementInstructionsDe: [
      'Nasenspitze beginnt die Bewegung',
      'Langsam vorschieben bis das Kinn auf der Brust ist',
      'Das ist ein Über-den-Kopf-Rollen',
      'Langsame Ausführung, etwa 2 Wiederholungen pro Durchgang',
      '7 Sekunden, 3 Sekunden Pause, 6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Nose tip initiates the movement',
      'Slowly roll forward until chin is on chest',
      'This is a rolling-over-the-head movement',
      'Slow execution, about 2 rolls per set',
      '7 seconds, 3 seconds rest, 6 repetitions',
    ],
    hintsDe: [
      'Meistes Gewicht auf den Händen lassen, um den Kopf zu schonen',
      'Bei Nackenproblemen: diese Übung nicht durchführen',
    ],
    hintsEn: [
      'Keep most of your weight through your hands to reduce pressure on your neck.',
      'If you have neck pain or another neck concern, skip this exercise and ask a qualified professional whether it is appropriate for you.',
    ],
    executionGuideDe: 'Nasenspitze führt. Langsam über den Kopf rollen.',
    executionGuideEn: 'Nose leads. Slowly roll over the head.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath: 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_02.png',
    holdCueDe: 'Rollen',
    holdCueEn: 'Roll',
  ),

  Exercise(
    id: 'tlr_ex3',
    packageId: 'tlr',
    sequenceNumber: 3,
    titleDe: 'Situp-Position halten',
    titleEn: 'Hold Sit-Up Position',
    positionInstructionsDe: [
      'Rückenlage',
      'Beine angewinkelt, Füße am Boden',
      'Arme zur Unterstützung bereit',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs bent, feet on floor',
      'Arms ready to support',
    ],
    movementInstructionsDe: [
      'Kleinmachen: Oberkörper hochrollen wie bei einem Situp',
      'Die Situp-Position halten',
      'Rumpfmuskulatur aktiv einsetzen',
      'Arme nur zur leichten Unterstützung nutzen',
      '7 Sekunden halten, 3 Sekunden Pause, 6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Curl up: roll upper body up as in a sit-up',
      'Hold the sit-up position',
      'Actively engage core muscles',
      'Use arms only for light support',
      'Hold 7 seconds, 3 seconds rest, 6 repetitions',
    ],
    executionGuideDe: 'Hochrollen und Position halten. Rumpf aktiv.',
    executionGuideEn: 'Roll up and hold position. Core active.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath: 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_03.png',
    holdCueDe: 'Halten',
    holdCueEn: 'Hold',
  ),

  // TLR 4 — breathing rhythm (inhale 3 s / exhale 4 s)
  Exercise(
    id: 'tlr_ex4',
    packageId: 'tlr',
    sequenceNumber: 4,
    titleDe: 'Kopf heben und fallen lassen',
    titleEn: 'Head Lift and Lower',
    positionInstructionsDe: [
      'Rückenlage',
      'Weiches flaches Kissen oder gefaltete Decke unter den Kopf legen',
      'Auf einem Bett wird kein Kissen benötigt',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Place a soft flat pillow or folded blanket under the head',
      'No pillow needed when lying on a bed',
    ],
    movementInstructionsDe: [
      'Beim Einatmen den Kopf leicht anheben',
      'Beim Ausatmen den Kopf fallen lassen',
      'Nicht das Kinn auf die Brust — Abstand halten, Kopf nach oben',
      'Bewegung im Nacken ist wichtig',
      '7 Sekunden, 3 Sekunden Pause, 6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'While inhaling, gently lift the head',
      'As you exhale, gently lower your head.',
      'Keep space between your chin and chest.',
      'Keep the neck movement small and controlled.',
      '7 seconds, 3 seconds rest, 6 repetitions',
    ],
    hintsDe: [
      'Kinn nicht auf die Brust legen — Abstand zwischen Kinn und Körper halten',
      'Bewegung soll im Nacken spürbar sein',
    ],
    hintsEn: [
      'Do not press chin to chest — maintain distance',
      'Stop if you feel pain or discomfort in your neck.',
    ],
    executionGuideDe: 'Einatmen: Kopf heben. Ausatmen: fallen lassen.',
    executionGuideEn: 'Inhale: gently lift your head. Exhale: gently lower it.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle1_04.png',
    rhythmType: RhythmType.phased,
    phases: _phasesBreathing,
    hasRepSwitch: false,
  ),

  Exercise(
    id: 'tlr_ex5',
    packageId: 'tlr',
    sequenceNumber: 5,
    titleDe: 'Bein-Fahrradfahren',
    titleEn: 'Leg Cycling',
    positionInstructionsDe: [
      'Rückenlage',
      'Basisposition einnehmen — auf die Grundposition achten',
      'Beine in der Luft',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Take basic position — pay attention to fundamentals',
      'Legs in the air',
    ],
    movementInstructionsDe: [
      'Mit den Füßen in der Luft Fahrrad fahren',
      'Große, langsame Bewegungen',
      '7 Sekunden aktiv fahren, 3 Sekunden Pause',
      'In der Pause: Beine einfach still in der Luft halten',
      '6 Wiederholungen',
    ],
    movementInstructionsEn: [
      'Cycle with feet in the air',
      'Large, slow movements',
      '7 seconds active cycling, 3 seconds rest',
      'During rest: simply hold legs still in the air',
      '6 repetitions',
    ],
    executionGuideDe: 'Langsam Fahrradfahren in der Luft. Große Bewegungen.',
    executionGuideEn: 'Slowly cycle in the air. Large movements.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath: 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_05.png',
    holdCueDe: 'Fahren',
    holdCueEn: 'Cycle',
  ),
];

// ============================================================================
// VORRUNDE — 6 exercises  (all holdRest 7-3)
// ============================================================================

const List<Exercise> vorrundeExercises = [
  // ── VORRUNDE ─────────────────────────────────────────────
  Exercise(
    id: 'vorrunde_ex1',
    packageId: 'vorrunde',
    sequenceNumber: 1,
    titleDe: 'Schaukeln 1',
    titleEn: 'Rocking 1',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_01.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_01.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
  Exercise(
    id: 'vorrunde_ex2',
    packageId: 'vorrunde',
    sequenceNumber: 2,
    titleDe: 'Schaukeln 2',
    titleEn: 'Rocking 2',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_02.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_02.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
  Exercise(
    id: 'vorrunde_ex3',
    packageId: 'vorrunde',
    sequenceNumber: 3,
    titleDe: 'Schaukeln 3',
    titleEn: 'Rocking 3',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_03.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_03.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
  Exercise(
    id: 'vorrunde_ex4',
    packageId: 'vorrunde',
    sequenceNumber: 4,
    titleDe: 'Schaukeln 4',
    titleEn: 'Rocking 4',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_04.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_04.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
  Exercise(
    id: 'vorrunde_ex5',
    packageId: 'vorrunde',
    sequenceNumber: 5,
    titleDe: 'Schaukeln 5',
    titleEn: 'Rocking 5',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_05.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_05.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
  Exercise(
    id: 'vorrunde_ex6',
    packageId: 'vorrunde',
    sequenceNumber: 6,
    titleDe: 'Schaukeln 6',
    titleEn: 'Rocking 6',
    positionInstructionsDe: ['TBD — solo Ausgangsposition'],
    positionInstructionsEn: ['TBD — solo starting position'],
    movementInstructionsDe: ['TBD — solo Bewegung'],
    movementInstructionsEn: ['TBD — solo movement'],
    positionInstructionsDuoDe: ['TBD — Duo Ausgangsposition'],
    positionInstructionsDuoEn: null,
    movementInstructionsDuoDe: ['TBD — Duo Bewegung'],
    movementInstructionsDuoEn: null,
    executionGuideDe: 'TBD',
    executionGuideEn: 'TBD',
    durationSeconds: 7,
    repetitions: 6,
    imagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_06.png',
    duoImagePath:
        'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_06.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
];
