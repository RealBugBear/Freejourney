-- PREPARED ONLY — do not apply without content-owner approval.
-- Aligns Supabase's Moro rows with app snapshot moro-2026.07.23-v1.
-- IDs, order, timing, repetitions and movement semantics remain unchanged.
-- Remote image_url / duo_image_url / video_url values remain optional overlays.

begin;

update public.exercises
set
  sequence_number = 1,
  title_de = 'Moro 5',
  title_en = 'Moro 5',
  position_instructions_de = array[
    'Lege dich auf den Rücken und strecke beide Beine aus.',
    'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.'
  ],
  position_instructions_en = array[
    'Lie on your back with both legs extended.',
    'Rest your arms alongside your body with your palms facing down.'
  ],
  movement_instructions_de = array[
    'Hebe ein Bein in 3 Sekunden an. Lege es auf dem Schienbein des ruhenden Beins ab.',
    'Halte 1 Sekunde.',
    'Führe das Bein in 3 Sekunden zurück.',
    'Wechsle für die nächste Wiederholung die Seite.'
  ],
  movement_instructions_en = array[
    'Raise one leg for 3 seconds. Rest it on the shin of the still leg.',
    'Hold for 1 second.',
    'Return the leg for 3 seconds.',
    'Switch sides before the next repetition.'
  ],
  hints_de = array['Halte das ruhende Bein und dein Becken stabil am Boden.'],
  hints_en = array['Keep the resting leg and your pelvis steady on the floor.'],
  execution_guide_de = 'Hebe ein Bein an, halte kurz und führe es kontrolliert zurück.',
  execution_guide_en = 'Raise one leg, hold briefly, and return it with control.',
  duration_seconds = 40,
  repetitions = 3,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_5.png',
  video_path = null,
  rhythm_type = 'phased',
  phases_json = '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]'::jsonb,
  has_rep_switch = true,
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = false
where id = 'moro_ex1' and package_id = 'moro';

update public.exercises
set
  sequence_number = 2,
  title_de = 'Moro 3 – Halber Frosch',
  title_en = 'Moro 3 – Half Frog',
  position_instructions_de = array[
    'Lege dich auf den Rücken und strecke beide Beine aus.',
    'Lass beide Beine gerade und entspannt nebeneinander liegen.'
  ],
  position_instructions_en = array[
    'Lie on your back with both legs extended.',
    'Let both legs rest straight and relaxed beside each other.'
  ],
  movement_instructions_de = array[
    'Lass eine Fußsohle in 3 Sekunden an der Innenseite des anderen Beins zum Körper gleiten.',
    'Führe den Fuß in 3 Sekunden zurück, bis das Bein wieder gestreckt ist.',
    'Wechsle für die nächste Wiederholung die Seite.'
  ],
  movement_instructions_en = array[
    'Slide one sole along the inside of the other leg toward your body for 3 seconds.',
    'Slide the foot back for 3 seconds until the leg is straight again.',
    'Switch sides before the next repetition.'
  ],
  hints_de = array[
    'Halte die Fußsohle während der gesamten Bewegung am anderen Bein.',
    'Beende den Bewegungsumfang, bevor der Kontakt verloren geht.'
  ],
  hints_en = array[
    'Keep the sole in contact with the other leg throughout the movement.',
    'End the movement before you lose that contact.'
  ],
  execution_guide_de = 'Lass eine Fußsohle am anderen Bein hoch- und zurückgleiten.',
  execution_guide_en = 'Slide one sole up and back along the other leg.',
  duration_seconds = 40,
  repetitions = 3,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_3.png',
  video_path = null,
  rhythm_type = 'phased',
  phases_json = '[{"labelDe":"Hoch","labelEn":"Up","durationSeconds":3},{"labelDe":"Runter","labelEn":"Down","durationSeconds":3}]'::jsonb,
  has_rep_switch = true,
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = false
where id = 'moro_ex2' and package_id = 'moro';

update public.exercises
set
  sequence_number = 3,
  title_de = 'Moro 4 – Frosch',
  title_en = 'Moro 4 – Frog',
  position_instructions_de = array[
    'Lege dich auf den Rücken und strecke beide Beine aus.',
    'Führe die Fußsohlen zusammen.'
  ],
  position_instructions_en = array[
    'Lie on your back with both legs extended.',
    'Bring the soles of your feet together.'
  ],
  movement_instructions_de = array[
    'Führe beide Füße in 3 Sekunden zum Körper. Lass die Knie nach außen sinken.',
    'Führe die Füße in 3 Sekunden zurück.'
  ],
  movement_instructions_en = array[
    'Bring both feet toward your body for 3 seconds. Let your knees open outward.',
    'Return your feet for 3 seconds.'
  ],
  hints_de = array[
    'Halte die Fußsohlen während der gesamten Bewegung aneinander.',
    'Wähle nur einen Bewegungsumfang, bei dem der Kontakt bestehen bleibt.'
  ],
  hints_en = array[
    'Keep the soles together throughout the movement.',
    'Move only as far as you can maintain that contact.'
  ],
  execution_guide_de = 'Führe die Füße zum Körper und kontrolliert wieder zurück.',
  execution_guide_en = 'Bring your feet toward your body and return with control.',
  duration_seconds = 35,
  repetitions = 3,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_4.png',
  video_path = null,
  rhythm_type = 'phased',
  phases_json = '[{"labelDe":"Ran","labelEn":"In","durationSeconds":3},{"labelDe":"Zurück","labelEn":"Back","durationSeconds":3}]'::jsonb,
  has_rep_switch = false,
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = false
where id = 'moro_ex3' and package_id = 'moro';

update public.exercises
set
  sequence_number = 4,
  title_de = 'Moro 1',
  title_en = 'Moro 1',
  position_instructions_de = array[
    'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.',
    'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.'
  ],
  position_instructions_en = array[
    'Lie on your back. Place your feet on the floor and keep your knees together.',
    'Rest your arms alongside your body with your palms facing down.'
  ],
  movement_instructions_de = array[
    'Führe beide Knie in 3 Sekunden nach rechts.',
    'Führe sie in 3 Sekunden zur Mitte zurück.',
    'Führe beide Knie in 3 Sekunden nach links.',
    'Führe sie in 3 Sekunden zur Mitte zurück.'
  ],
  movement_instructions_en = array[
    'Lower both knees to the right for 3 seconds.',
    'Return them to the centre for 3 seconds.',
    'Lower both knees to the left for 3 seconds.',
    'Return them to the centre for 3 seconds.'
  ],
  hints_de = array[
    'Halte dein Becken stabil am Boden.',
    'Bewege die Knie nur so weit, wie das Becken ruhig bleibt.'
  ],
  hints_en = array[
    'Keep your pelvis steady on the floor.',
    'Move your knees only as far as your pelvis stays still.'
  ],
  execution_guide_de = 'Führe beide Knie kontrolliert nach rechts, zur Mitte, nach links und zurück.',
  execution_guide_en = 'Move both knees with control to the right, centre, left, and back.',
  duration_seconds = 45,
  repetitions = 3,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_1.png',
  video_path = null,
  rhythm_type = 'phased',
  phases_json = '[{"labelDe":"Rechts","labelEn":"Right","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3},{"labelDe":"Links","labelEn":"Left","durationSeconds":3},{"labelDe":"Mitte","labelEn":"Centre","durationSeconds":3}]'::jsonb,
  has_rep_switch = false,
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = false
where id = 'moro_ex4' and package_id = 'moro';

update public.exercises
set
  sequence_number = 5,
  title_de = 'Moro 2',
  title_en = 'Moro 2',
  position_instructions_de = array[
    'Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen.',
    'Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden.'
  ],
  position_instructions_en = array[
    'Lie on your back. Place your feet on the floor and keep your knees together.',
    'Rest your arms alongside your body with your palms facing down.'
  ],
  movement_instructions_de = array[
    'Beginne auszuatmen.',
    'Rolle Kopf und Oberkörper in 3 Sekunden an. Bewege die Stirn Richtung Knie.',
    'Halte 1 Sekunde.',
    'Lege Kopf und Oberkörper in 2 Sekunden ab.'
  ],
  movement_instructions_en = array[
    'Begin to exhale.',
    'Curl your head and upper body up for 3 seconds. Move your forehead toward your knees.',
    'Hold for 1 second.',
    'Lower your head and upper body for 2 seconds.'
  ],
  hints_de = array[
    'Lege bei Bedarf die offenen Hände an die Schienbeine.',
    'Unterstütze dich nur leicht. Ziehe nicht mit den Armen.'
  ],
  hints_en = array[
    'If needed, place your open hands on your shins.',
    'Use only light support. Do not pull with your arms.'
  ],
  execution_guide_de = 'Atme aus, rolle den Oberkörper an und lege ihn kontrolliert ab.',
  execution_guide_en = 'Exhale, curl your upper body up, and lower with control.',
  duration_seconds = 30,
  repetitions = 3,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_2.png',
  video_path = null,
  rhythm_type = 'phased',
  phases_json = '[{"labelDe":"Ausatmen","labelEn":"Exhale","durationSeconds":1},{"labelDe":"Hochrollen","labelEn":"Roll up","durationSeconds":3},{"labelDe":"Halten","labelEn":"Hold","durationSeconds":1},{"labelDe":"Ablegen","labelEn":"Lower","durationSeconds":2}]'::jsonb,
  has_rep_switch = false,
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = false
where id = 'moro_ex5' and package_id = 'moro';

update public.exercises
set
  sequence_number = 6,
  title_de = 'Moro 6 – Isometrischer Gegendruck',
  title_en = 'Moro 6 – Isometric Counterpressure',
  position_instructions_de = array[
    'Lege dich auf den Rücken und winkle beide Beine an.',
    'Lege die überkreuzten Hände auf Knie oder Schienbeine.'
  ],
  position_instructions_en = array[
    'Lie on your back with both legs bent.',
    'Place your crossed hands on your knees or shins.'
  ],
  movement_instructions_de = array[
    'Ziehe die Beine leicht zum Körper. Halte mit den Händen kontrolliert dagegen und hebe den Kopf etwas an.',
    'Halte den Gegendruck 7 Sekunden.',
    'Löse die Spannung für 3 Sekunden.',
    'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.'
  ],
  movement_instructions_en = array[
    'Draw your legs gently toward your body. Resist with your hands and lift your head slightly.',
    'Hold the counterpressure for 7 seconds.',
    'Release the tension for 3 seconds.',
    'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.'
  ],
  hints_de = array['Baue die Spannung gleichmäßig auf. Vermeide ruckartige Bewegungen.'],
  hints_en = array['Build the tension evenly. Avoid sudden or jerky movement.'],
  execution_guide_de = 'Baue leichten Gegendruck auf, halte und löse kontrolliert.',
  execution_guide_en = 'Build gentle counterpressure, hold, and release with control.',
  duration_seconds = 90,
  repetitions = 6,
  image_path = 'assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_06.png',
  video_path = null,
  rhythm_type = 'holdRest',
  phases_json = '[]'::jsonb,
  has_rep_switch = false,
  hold_cue_de = 'Spannung',
  hold_cue_en = 'Tension',
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = true
where id = 'moro_ex6' and package_id = 'moro';

update public.exercises
set
  sequence_number = 7,
  title_de = 'Moro 7 – Überkreuzter Gegendruck',
  title_en = 'Moro 7 – Crossed Counterpressure',
  position_instructions_de = array[
    'Lege dich auf den Rücken und winkle beide Beine an.',
    'Lege die überkreuzten Hände auf Oberschenkel oder Knie.'
  ],
  position_instructions_en = array[
    'Lie on your back with both legs bent.',
    'Place your crossed hands on your thighs or knees.'
  ],
  movement_instructions_de = array[
    'Ziehe beide Beine zum Körper. Drücke mit den Händen kontrolliert dagegen und hebe den Kopf leicht Richtung Brust.',
    'Halte den Gegendruck 7 Sekunden.',
    'Löse die Spannung für 3 Sekunden.',
    'Wechsle nach 3 Wiederholungen das Armkreuz. Führe 3 weitere Wiederholungen aus.'
  ],
  movement_instructions_en = array[
    'Draw both legs toward your body. Resist with your hands and lift your head slightly toward your chest.',
    'Hold the counterpressure for 7 seconds.',
    'Release the tension for 3 seconds.',
    'Switch the arm cross after 3 repetitions. Complete 3 more repetitions.'
  ],
  hints_de = array['Halte die Bewegung klein und die Spannung gleichmäßig.'],
  hints_en = array['Keep the movement small and the tension even.'],
  execution_guide_de = 'Lass Beine und Hände kontrolliert gegeneinander arbeiten.',
  execution_guide_en = 'Let your legs and hands work against each other with control.',
  duration_seconds = 90,
  repetitions = 6,
  image_path = '',
  video_path = null,
  rhythm_type = 'holdRest',
  phases_json = '[]'::jsonb,
  has_rep_switch = false,
  hold_cue_de = 'Spannung',
  hold_cue_en = 'Tension',
  hold_seconds = 7,
  rest_seconds = 3,
  halfway_switch = true
where id = 'moro_ex7' and package_id = 'moro';

do $$
declare
  actual_ids text[];
begin
  select array_agg(id order by sequence_number)
  into actual_ids
  from public.exercises
  where package_id = 'moro';

  if actual_ids is distinct from array[
    'moro_ex1',
    'moro_ex2',
    'moro_ex3',
    'moro_ex4',
    'moro_ex5',
    'moro_ex6',
    'moro_ex7'
  ]::text[] then
    raise exception 'Moro snapshot contract mismatch: %', actual_ids;
  end if;
end
$$;

commit;
