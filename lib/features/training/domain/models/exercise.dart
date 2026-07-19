import 'dart:convert';

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

  String label(String locale) => locale == 'de' ? labelDe : labelEn;
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

  String title(String locale) => locale == 'de' ? titleDe : titleEn;
  List<String> positionInstructions(String locale) =>
      locale == 'de' ? positionInstructionsDe : positionInstructionsEn;
  List<String> movementInstructions(String locale) =>
      locale == 'de' ? movementInstructionsDe : movementInstructionsEn;
  List<String> positionInstructionsFor(String locale, {bool duo = false}) {
    if (duo) {
      final instructions = locale == 'de'
          ? positionInstructionsDuoDe
          : positionInstructionsDuoEn;
      if (instructions != null && instructions.isNotEmpty) return instructions;
    }
    return positionInstructions(locale);
  }

  List<String> movementInstructionsFor(String locale, {bool duo = false}) {
    if (duo) {
      final instructions = locale == 'de'
          ? movementInstructionsDuoDe
          : movementInstructionsDuoEn;
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

  /// Returns the remote Supabase Storage URL for this exercise's image.
  /// Prefers duo URL when [duo] is true and one is available.
  String? imageUrlFor({bool duo = false}) {
    if (duo && duoImageUrl != null && duoImageUrl!.isNotEmpty) {
      return duoImageUrl;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    return null;
  }

  List<String>? hints(String locale) => locale == 'de' ? hintsDe : hintsEn;
  String executionGuide(String locale) =>
      locale == 'de' ? executionGuideDe : executionGuideEn;

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

  static String? _normalizeUrl(dynamic v) {
    if (v == null) return null;
    final s = (v as String).trim();
    return s.isEmpty ? null : s;
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
      durationSeconds: row['duration_seconds'] as int,
      repetitions: row['repetitions'] as int,
      imagePath: _preferredBundledImagePath(id, rawImagePath),
      duoImagePath: row['duo_image_path'] as String?,
      videoPath: row['video_path'] as String?,
      audioCuePath: row['audio_cue_path'] as String?,
      imageUrl: _normalizeUrl(row['image_url']),
      duoImageUrl: _normalizeUrl(row['duo_image_url']),
      videoUrl: _normalizeUrl(row['video_url']),
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

String _preferredBundledImagePath(String exerciseId, String backendImagePath) {
  switch (exerciseId) {
    case 'moro_ex2':
      return 'assets/images/trainings/moro/moro1.3.jpeg';
    case 'moro_ex4':
      return 'assets/images/trainings/moro/moro1.1.jpeg';
    case 'moro_ex5':
      return 'assets/images/trainings/moro/moro1.2.jpeg';
    default:
      return backendImagePath;
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
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Nur ein Bein bewegt sich',
      'Dieses Bein langsam in ca. drei Sekunden anheben und auf dem Schienbein des anderen Beins ablegen',
      'Kurz halten',
      'In drei Sekunden wieder zurück',
      'Seitenwechsel',
    ],
    movementInstructionsEn: [
      'Only one leg moves',
      'Slowly raise this leg over about three seconds and rest it on the shin of the other leg',
      'Hold briefly',
      'Return in three seconds',
      'Switch sides',
    ],
    hintsDe: [
      'Das nicht bewegte Bein bleibt komplett ruhig und unverändert liegen'
    ],
    hintsEn: ['The non-moving leg remains completely still'],
    executionGuideDe:
        'Bein anheben und auf dem Schienbein des anderen Beins ablegen.',
    executionGuideEn: 'Raise leg and rest it on the shin of the other leg.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro5.png',
    videoPath: 'assets/videos/moro/moro_5.mov',
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
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Neutrale Ausgangsposition',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Neutral starting position',
    ],
    movementInstructionsDe: [
      'Ein Bein bewegt sich:',
      'Fußsohle gleitet an der Innenseite des anderen Beins nach oben zum Körper, ca. drei Sekunden',
      'Dann in drei Sekunden wieder vollständig zurück in die neutrale Position',
      'Danach Seitenwechsel',
    ],
    movementInstructionsEn: [
      'One leg moves:',
      'The sole of the foot slides along the inside of the other leg upward toward the body, about three seconds',
      'Then slide back down to neutral over three seconds',
      'Switch sides',
    ],
    hintsDe: [
      'Fußsohle bleibt während der gesamten Bewegung am anderen Bein anliegend',
      'Bewegungsweite richtet sich nach diesem Kontakt',
    ],
    hintsEn: [
      'The sole of the foot remains in contact with the other leg throughout',
      'Range of motion is guided by this contact',
    ],
    executionGuideDe: 'Fußsohle gleitet am anderen Bein entlang nach oben.',
    executionGuideEn: 'Sole of foot slides up along the other leg.',
    durationSeconds: 40,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro1.3.jpeg',
    videoPath: 'assets/videos/moro/moro_3.mov',
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
      'Rückenlage',
      'Beide Beine ausgestreckt',
      'Fußsohlen zusammenführen',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Both legs extended',
      'Bring the soles of the feet together',
    ],
    movementInstructionsDe: [
      'Füße langsam drei Sekunden Richtung Körper führen',
      'Knie gehen dabei nach außen',
      'Füße anschließend drei Sekunden zurückführen',
    ],
    movementInstructionsEn: [
      'Slowly bring feet toward the body over three seconds',
      'Knees open outward',
      'Return feet over three seconds',
    ],
    hintsDe: [
      'Range of Motion nur so weit, wie die Fußsohlen während der gesamten Bewegung eng aneinander bleiben'
    ],
    hintsEn: [
      'Only move as far as the soles of the feet can remain together throughout'
    ],
    executionGuideDe: 'Füße zum Körper führen, Knie gehen nach außen.',
    executionGuideEn: 'Bring feet toward the body, knees open outward.',
    durationSeconds: 35,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro4.png',
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
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs together and bent, feet on the floor',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Knie langsam drei Sekunden nach rechts führen',
      'Drei Sekunden zurück zur Mitte',
      'Knie drei Sekunden nach links führen',
      'Zurück zur Mitte',
      'Drei Durchgänge',
    ],
    movementInstructionsEn: [
      'Slowly lower knees to the right over three seconds',
      'Return to center over three seconds',
      'Lower knees to the left over three seconds',
      'Return to center',
      'Three rounds',
    ],
    hintsDe: [
      'Hüfte bleibt stabil am Boden, ohne sich abzuheben oder mitzudrehen',
      'Bewegung nur so weit, wie die Hüfte neutral bleibt',
    ],
    hintsEn: [
      'Hips remain stable on the floor, not lifting or rotating',
      'Only move as far as the hips stay neutral',
    ],
    executionGuideDe:
        'Knie langsam zur Seite führen. Hüfte bleibt stabil am Boden.',
    executionGuideEn:
        'Slowly lower knees to the side. Hips stay stable on the floor.',
    durationSeconds: 45,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro1.1.jpeg',
    videoPath: 'assets/videos/moro/moro_1.mov',
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
      'Rückenlage',
      'Beine zusammen und angewinkelt, Füße am Boden',
      'Arme ausgestreckt neben dem Körper, Handflächen am Boden',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs together and bent, feet on the floor',
      'Arms extended alongside the body, palms on the floor',
    ],
    movementInstructionsDe: [
      'Mit dem Ausatmen Kopf und Oberkörper langsam in ca. drei Sekunden anheben',
      'Stirn bewegt sich Richtung Knie',
      'Kurz halten',
      'Langsam wieder ablegen',
    ],
    movementInstructionsEn: [
      'While exhaling, slowly raise the head and upper body over about three seconds',
      'Forehead moves toward the knees',
      'Hold briefly',
      'Slowly lower back down',
    ],
    hintsDe: [
      'Wenn die Rumpfkraft nicht ausreicht: Hände an die Schienbeine legen, Handflächen offen lassen',
      'Arme unterstützen nur leicht, nicht ziehen',
    ],
    hintsEn: [
      'If core strength is insufficient: place hands on the shins, palms open',
      'Arms only support lightly, do not pull',
    ],
    executionGuideDe:
        'Kopf und Oberkörper langsam anheben, Stirn Richtung Knie.',
    executionGuideEn:
        'Slowly raise head and upper body, forehead toward knees.',
    durationSeconds: 30,
    repetitions: 3,
    imagePath: 'assets/images/trainings/moro/moro1.2.jpeg',
    videoPath: 'assets/videos/moro/moro_2.mov',
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
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf den Knien oder Schienbeinen',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs bent',
      'Hands crossed on the knees or shins',
    ],
    movementInstructionsDe: [
      'Leichter Gegendruck: Beine ziehen Richtung Körper, Hände halten dagegen',
      'Kopf leicht anheben',
      'Sieben Sekunden durch den Mund ausatmen',
      'Drei Sekunden Pause',
      'Drei Wiederholungen',
      'Armkreuz wechseln',
      'Drei weitere Wiederholungen',
    ],
    movementInstructionsEn: [
      'Light counterpressure: legs pull toward body, hands push against',
      'Slightly lift the head',
      'Exhale through the mouth for seven seconds',
      'Three seconds rest',
      'Three repetitions',
      'Switch arm cross',
      'Three more repetitions',
    ],
    hintsDe: ['Spannung gleichmäßig halten, nicht ruckartig'],
    hintsEn: ['Maintain even tension, no jerking'],
    executionGuideDe: 'Gegendruck aufbauen. Sieben Sekunden ausatmen.',
    executionGuideEn: 'Build counterpressure. Exhale for seven seconds.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: 'assets/images/trainings/moro/moro6.png',
    videoPath: 'assets/videos/moro/moro_6.mov',
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
      'Rückenlage',
      'Beine angewinkelt',
      'Hände überkreuz auf Oberschenkeln oder Knien',
    ],
    positionInstructionsEn: [
      'Lie on your back',
      'Legs bent',
      'Hands crossed on the thighs or knees',
    ],
    movementInstructionsDe: [
      'Beine Richtung Körper ziehen',
      'Hände arbeiten dagegen',
      'Kopf leicht zur Brust anheben',
      'Sieben Sekunden ausatmen',
      'Drei Sekunden Pause',
      'Sechs Wiederholungen',
      'Nach drei Wiederholungen Armkreuz wechseln',
    ],
    movementInstructionsEn: [
      'Pull legs toward the body',
      'Hands work against it',
      'Slightly raise head toward chest',
      'Exhale for seven seconds',
      'Three seconds rest',
      'Six repetitions',
      'Switch arm cross after three repetitions',
    ],
    hintsDe: ['Bewegung bleibt klein; Fokus auf kontrollierter Spannung'],
    hintsEn: ['Movement stays small; focus on controlled tension'],
    executionGuideDe:
        'Beine und Hände arbeiten gegeneinander. Sieben Sekunden ausatmen.',
    executionGuideEn:
        'Legs and hands work against each other. Exhale for seven seconds.',
    durationSeconds: 90,
    repetitions: 6,
    imagePath: 'assets/images/trainings/moro/moro7.png',
    videoPath: 'assets/videos/moro/moro_7.mov',
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
    imagePath: 'assets/images/trainings/spinal_galant/1spin.jpeg',
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
    imagePath: 'assets/images/trainings/spinal_galant/2spin.jpeg',
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
    imagePath: 'assets/images/trainings/spinal_galant/3spin.jpeg',
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
    imagePath: 'assets/images/trainings/spinal_galant/4spin.jpeg',
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
    imagePath: 'assets/images/trainings/tlr/tlr1.jpeg',
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
    imagePath: 'assets/images/trainings/tlr/tlr2.jpeg',
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
    imagePath: 'assets/images/trainings/tlr/tlr3.jpeg',
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
    executionGuideEn:
        'Inhale: gently lift your head. Exhale: gently lower it.',
    durationSeconds: 7,
    repetitions: 6,
    imagePath: 'assets/images/trainings/tlr/tlr4.jpeg',
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
    imagePath: 'assets/images/trainings/tlr/tlr5.jpeg',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_01.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_01.png',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_02.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_02.png',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_03.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_03.png',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_04.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_04.png',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_05.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_05.png',
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
    imagePath: 'assets/images/trainings/vorrunde/Vorbereitung_solo_06.png',
    duoImagePath: 'assets/images/trainings/vorrunde/Vorbereitung_duo_06.png',
    rhythmType: RhythmType.holdRest,
    holdSeconds: 7,
    restSeconds: 3,
    hasRepSwitch: false,
    halfwaySwitch: false,
  ),
];
