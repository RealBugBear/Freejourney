-- Connect the finalized, bundled training artwork to the active exercise rows.

UPDATE public.exercises AS exercise
SET image_path = media.image_path
FROM (VALUES
  ('moro_ex1', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_05.png'),
  ('moro_ex2', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_03.png'),
  ('moro_ex3', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_04.png'),
  ('moro_ex4', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_01.png'),
  ('moro_ex5', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_02.png'),
  ('moro_ex6', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_06.png'),
  ('moro_ex7', 'assets/images/Bilder/01_FLR und Moro-Reflex/FRI_App_01_FLR und Moro-Reflex_07.png'),
  ('sg_ex1', 'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_01.png'),
  ('sg_ex2', 'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_02.png'),
  ('sg_ex3', 'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_03.png'),
  ('sg_ex4', 'assets/images/Bilder/02_Spinaler Galant-Reflex/FRI_App_02_Spinaler Galant-Reflex_04.png'),
  ('tlr_ex1', 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_01.png'),
  ('tlr_ex2', 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_02.png'),
  ('tlr_ex3', 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_03.png'),
  ('tlr_ex4', 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle1_04.png'),
  ('tlr_ex5', 'assets/images/Bilder/03_TLR-Reflex/FRI_App_03_TLR-Refle_05.png'),
  ('vorrunde_ex1', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_01.png'),
  ('vorrunde_ex2', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_02.png'),
  ('vorrunde_ex3', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_03.png'),
  ('vorrunde_ex4', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_04.png'),
  ('vorrunde_ex5', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_05.png'),
  ('vorrunde_ex6', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_06.png')
) AS media(id, image_path)
WHERE exercise.id = media.id;

UPDATE public.exercises AS exercise
SET duo_image_path = media.image_path
FROM (VALUES
  ('vorrunde_ex1', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_01.png'),
  ('vorrunde_ex2', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_02.png'),
  ('vorrunde_ex3', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_03.png'),
  ('vorrunde_ex4', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_04.png'),
  ('vorrunde_ex5', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_05.png'),
  ('vorrunde_ex6', 'assets/images/Bilder/00_Vorbereitung/FRI_App_Vorbereitung_06.png')
) AS media(id, image_path)
WHERE exercise.id = media.id;
