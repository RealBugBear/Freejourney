-- Repairs a drift between the repository and the live database.
--
-- 2026072301_moro_content_snapshot_v1.sql UPDATEs seven Moro exercise rows and
-- writes eight `exercises` columns. No migration ever creates either the
-- columns or the rows. They exist on the live database because they were
-- added there directly, outside the migration history. The consequence: the
-- chain has not replayed from scratch since that file landed (2026-08-10), so
-- `supabase db reset --local` cannot prove any later migration.
--
-- This is CLAUDE.md mistake #11 ("The SQL-Editor Drift"). The rule there is:
-- the live database is the fact, so the repository is corrected to match it.
--
-- Why the timestamp is EARLIER than the file it repairs: migrations run in
-- filename order, and these columns must exist before 2026072301 writes to
-- them. On the live database this file is a no-op — every column is already
-- there and every statement is IF NOT EXISTS — it only ever does work on a
-- database built from scratch.
--
-- Types and defaults are taken from the app's own contract with the server:
-- lib/core/database/tables/exercises_table.dart and the row mapping in
-- lib/core/sync/exercises_sync_service.dart (phases_json is read as jsonb).
--
-- The seven rows below are GENERATED from `moroExercises` in
-- lib/features/training/domain/models/exercise.dart, not transcribed. That
-- constant is a safe source: ExercisesSyncService.validateRemoteSnapshotForCache
-- compares every Moro row the server returns against it and refuses the sync on
-- any mismatch, so live content that differed from this would already break the
-- app. ON CONFLICT DO NOTHING keeps the statements a no-op where the rows exist.

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS rhythm_type text NOT NULL DEFAULT 'holdRest';

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS phases_json jsonb NOT NULL DEFAULT '[]'::jsonb;

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS has_rep_switch boolean NOT NULL DEFAULT false;

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS halfway_switch boolean NOT NULL DEFAULT false;

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS hold_cue_de text NOT NULL DEFAULT 'Halten';

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS hold_cue_en text NOT NULL DEFAULT 'Hold';

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS hold_seconds int NOT NULL DEFAULT 7;

ALTER TABLE public.exercises
  ADD COLUMN IF NOT EXISTS rest_seconds int NOT NULL DEFAULT 3;

-- ── Moro exercise rows (generated, see header) ──────────────────────────────

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex1', 'moro', 1,
  'Moro 5', 'Moro 5',
  array['Lege dich auf den Rücken und strecke beide Beine aus.', 'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.']::text[],
  array['Lie on your back with both legs extended.', 'Rest your arms alongside your body with your palms facing down.']::text[],
  array['Hebe ein Bein in 3 Sekunden an. Lege es auf dem Schienbein des ruhenden Beins ab.', 'Halte 1 Sekunde.', 'Führe das Bein in 3 Sekunden zurück.', 'Wechsle für die nächste Wiederholung die Seite.']::text[],
  array['Raise one leg for 3 seconds. Rest it on the shin of the still leg.', 'Hold for 1 second.', 'Return the leg for 3 seconds.', 'Switch sides before the next repetition.']::text[],
  array['Halte das ruhende Bein und dein Becken stabil am Boden.']::text[],
  array['Keep the resting leg and your pelvis steady on the floor.']::text[],
  'Hebe ein Bein an, halte kurz und führe es kontrolliert zurück.',
  'Raise one leg, hold briefly, and return it with control.',
  40, 3,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_05.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'phased', '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]'::jsonb, true,
  'Halten', 'Hold', 7, 3,
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex2', 'moro', 2,
  'Moro 3 – Halber Frosch', 'Moro 3 – Half Frog',
  array['Lege dich auf den Rücken und strecke beide Beine aus.', 'Lass beide Beine gerade und entspannt nebeneinander liegen.']::text[],
  array['Lie on your back with both legs extended.', 'Let both legs rest straight and relaxed beside each other.']::text[],
  array['Lass eine Fußsohle in 3 Sekunden an der Innenseite des anderen Beins zum Körper gleiten.', 'Führe den Fuß in 3 Sekunden zurück, bis das Bein wieder gestreckt ist.', 'Wechsle für die nächste Wiederholung die Seite.']::text[],
  array['Slide one sole along the inside of the other leg toward your body for 3 seconds.', 'Slide the foot back for 3 seconds until the leg is straight again.', 'Switch sides before the next repetition.']::text[],
  array['Halte die Fußsohle während der gesamten Bewegung am anderen Bein.', 'Beende den Bewegungsumfang, bevor der Kontakt verloren geht.']::text[],
  array['Keep the sole in contact with the other leg throughout the movement.', 'End the movement before you lose that contact.']::text[],
  'Lass eine Fußsohle am anderen Bein hoch- und zurückgleiten.',
  'Slide one sole up and back along the other leg.',
  40, 3,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_03.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'phased', '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]'::jsonb, true,
  'Halten', 'Hold', 7, 3,
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex3', 'moro', 3,
  'Moro 4 – Frosch', 'Moro 4 – Frog',
  array['Lege dich auf den Rücken und strecke beide Beine aus.', 'Führe die Fußsohlen zusammen.']::text[],
  array['Lie on your back with both legs extended.', 'Bring the soles of your feet together.']::text[],
  array['Führe beide Füße in 3 Sekunden zum Körper. Lass die Knie nach außen sinken.', 'Führe die Füße in 3 Sekunden zurück.']::text[],
  array['Bring both feet toward your body for 3 seconds. Let your knees open outward.', 'Return your feet for 3 seconds.']::text[],
  array['Halte die Fußsohlen während der gesamten Bewegung aneinander.', 'Wähle nur einen Bewegungsumfang, bei dem der Kontakt bestehen bleibt.']::text[],
  array['Keep the soles together throughout the movement.', 'Move only as far as you can maintain that contact.']::text[],
  'Führe die Füße zum Körper und kontrolliert wieder zurück.',
  'Bring your feet toward your body and return with control.',
  35, 3,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_04.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'phased', '[{"labelDe":"Ran","labelEn":"In","durationSeconds":3},{"labelDe":"Zurück","labelEn":"Back","durationSeconds":3}]'::jsonb, false,
  'Halten', 'Hold', 7, 3,
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex4', 'moro', 4,
  'Moro 1', 'Moro 1',
  array['Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.', 'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.']::text[],
  array['Lie on your back. Place your feet on the floor and keep your knees together.', 'Rest your arms alongside your body with your palms facing down.']::text[],
  array['Führe beide Knie in 3 Sekunden nach rechts.', 'Führe sie in 3 Sekunden zur Mitte zurück.', 'Führe beide Knie in 3 Sekunden nach links.', 'Führe sie in 3 Sekunden zur Mitte zurück.']::text[],
  array['Lower both knees to the right for 3 seconds.', 'Return them to the centre for 3 seconds.', 'Lower both knees to the left for 3 seconds.', 'Return them to the centre for 3 seconds.']::text[],
  array['Halte dein Becken stabil am Boden.', 'Bewege die Knie nur so weit, wie das Becken ruhig bleibt.']::text[],
  array['Keep your pelvis steady on the floor.', 'Move your knees only as far as your pelvis stays still.']::text[],
  'Führe beide Knie kontrolliert nach rechts, zur Mitte, nach links und zurück.',
  'Move both knees with control to the right, centre, left, and back.',
  45, 3,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_01.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'phased', '[{"labelDe":"Rechts","labelEn":"Right","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3},{"labelDe":"Links","labelEn":"Left","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3}]'::jsonb, false,
  'Halten', 'Hold', 7, 3,
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex5', 'moro', 5,
  'Moro 2', 'Moro 2',
  array['Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.', 'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.']::text[],
  array['Lie on your back. Place your feet on the floor and keep your knees together.', 'Rest your arms alongside your body with your palms facing down.']::text[],
  array['Beginne auszuatmen.', 'Rolle Kopf und Oberkörper in 3 Sekunden an. Bewege die Stirn Richtung Knie.', 'Halte 1 Sekunde.', 'Lege Kopf und Oberkörper in 2 Sekunden ab.']::text[],
  array['Begin to exhale.', 'Curl your head and upper body up for 3 seconds. Move your forehead toward your knees.', 'Hold for 1 second.', 'Lower your head and upper body for 2 seconds.']::text[],
  array['Lege bei Bedarf die offenen Hände an die Schienbeine.', 'Unterstütze dich nur leicht. Ziehe nicht mit den Armen.']::text[],
  array['If needed, place your open hands on your shins.', 'Use only light support. Do not pull with your arms.']::text[],
  'Atme aus, rolle den Oberkörper an und lege ihn kontrolliert ab.',
  'Exhale, curl your upper body up, and lower with control.',
  30, 3,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_02.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'phased', '[{"labelDe":"Ausatmen","labelEn":"Exhale","durationSeconds":1},{"labelDe":"Hochrollen","labelEn":"Roll up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Ablegen","labelEn":"Lower","durationSeconds":2}]'::jsonb, false,
  'Halten', 'Hold', 7, 3,
  false
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex6', 'moro', 6,
  'Moro 6 – Isometrischer Gegendruck', 'Moro 6 – Isometric Counterpressure',
  array['Lege dich auf den Rücken und winkle beide Beine an.', 'Lege die überkreuzten Hände auf Knie oder Schienbeine.']::text[],
  array['Lie on your back with both legs bent.', 'Place your crossed hands on your knees or shins.']::text[],
  array['Ziehe die Beine leicht zum Körper. Halte mit den Händen kontrolliert dagegen und hebe den Kopf etwas an.', 'Halte den Gegendruck 7 Sekunden.', 'Löse die Spannung für 3 Sekunden.', 'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.']::text[],
  array['Draw your legs gently toward your body. Resist with your hands and lift your head slightly.', 'Hold the counterpressure for 7 seconds.', 'Release the tension for 3 seconds.', 'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.']::text[],
  array['Baue die Spannung gleichmäßig auf. Vermeide ruckartige Bewegungen.']::text[],
  array['Build the tension evenly. Avoid sudden or jerky movement.']::text[],
  'Baue leichten Gegendruck auf, halte und löse kontrolliert.',
  'Build gentle counterpressure, hold, and release with control.',
  90, 6,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_06.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'holdRest', '[]'::jsonb, false,
  'Spannung', 'Tension', 7, 3,
  true
) ON CONFLICT (id) DO NOTHING;

INSERT INTO public.exercises (
  id, package_id, sequence_number,
  title_de, title_en,
  position_instructions_de, position_instructions_en,
  movement_instructions_de, movement_instructions_en,
  hints_de, hints_en,
  execution_guide_de, execution_guide_en,
  duration_seconds, repetitions,
  image_path, video_path, duo_image_path, audio_cue_path,
  image_url, duo_image_url, video_url,
  rhythm_type, phases_json, has_rep_switch,
  hold_cue_de, hold_cue_en, hold_seconds, rest_seconds,
  halfway_switch
) VALUES (
  'moro_ex7', 'moro', 7,
  'Moro 7 – Überkreuzter Gegendruck', 'Moro 7 – Crossed Counterpressure',
  array['Lege dich auf den Rücken und winkle beide Beine an.', 'Lege die überkreuzten Hände auf Oberschenkel oder Knie.']::text[],
  array['Lie on your back with both legs bent.', 'Place your crossed hands on your thighs or knees.']::text[],
  array['Ziehe beide Beine zum Körper. Drücke mit den Händen kontrolliert dagegen und hebe den Kopf leicht Richtung Brust.', 'Halte den Gegendruck 7 Sekunden.', 'Löse die Spannung für 3 Sekunden.', 'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.']::text[],
  array['Draw both legs toward your body. Resist with your hands and lift your head slightly toward your chest.', 'Hold the counterpressure for 7 seconds.', 'Release the tension for 3 seconds.', 'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.']::text[],
  array['Halte die Bewegung klein und die Spannung gleichmäßig.']::text[],
  array['Keep the movement small and the tension even.']::text[],
  'Lass Beine und Hände kontrolliert gegeneinander arbeiten.',
  'Let your legs and hands work against each other with control.',
  90, 6,
  'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_07.png', NULL, NULL, NULL,
  NULL, NULL, NULL,
  'holdRest', '[]'::jsonb, false,
  'Spannung', 'Tension', 7, 3,
  true
) ON CONFLICT (id) DO NOTHING;

