-- ============================================================
-- CoreJourney — RLS Verifikation (nur lesen, nichts schreiben)
-- ============================================================
-- Ausführen im Supabase SQL Editor → zeigt Ist-Zustand.
-- NUR lesen — nichts verändern.
--
-- Die RLS-Policies sind bereits korrekt definiert in:
--   app/supabase/schema.sql (Zeilen 239–307)
--   app/supabase_rls.sql
--
-- Dort NICHT nochmal ausführen wenn Policies bereits existieren
-- → führt zu "policy already exists"-Fehler. Erst prüfen!
-- ============================================================


-- 1. Ist RLS auf jeder Tabelle aktiviert?
--    rowsecurity = true → RLS aktiv, false → GEFÄHRLICH
SELECT
  tablename,
  rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'enrollments','progress_entries','training_sessions',
    'mood_checkins','intake_assessments','completion_questionnaires',
    'journal_entries','profiles','trainer_client_relationships',
    'device_tokens','vorrunde_phases'
  )
ORDER BY tablename;

-- 1b. Show every app-owned public table that still has RLS disabled.
--     Expected result after hardening: zero rows.
--     `spatial_ref_sys` is a PostGIS extension table managed by Supabase.
SELECT
  tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND rowsecurity = false
  AND tablename <> 'spatial_ref_sys'
ORDER BY tablename;


-- 2. Welche Policies sind aktiv?
SELECT
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;


-- ============================================================
-- Erwartetes Ergebnis (aus schema.sql / supabase_rls.sql):
--
-- enrollments          → "Users can manage own enrollments"  (ALL)
--                      → "Trainers can read client enrollments" (SELECT)
-- intake_assessments   → "Users manage own intake assessments" (ALL, via enrollment join)
-- completion_q...      → "Users manage own completion questionnaires" (ALL, via enrollment join)
-- training_sessions    → "Users can manage own sessions" (ALL)
--                      → "Trainers can read client sessions" (SELECT)
-- progress_entries     → "Users manage own progress" (ALL)
--                      → "Trainers read client progress" (SELECT)
-- mood_checkins        → "Users manage own mood" (ALL)
--                      → "Trainers read client mood" (SELECT)
-- trainer_client_rel.  → "Users see own relationships" (SELECT)
--                      → "Trainers manage relationships" (ALL)
--                      → "Clients update their side" (UPDATE)
-- profiles             → "Users can view own profile" (SELECT)
--                      → "Users can update own profile" (UPDATE)
-- device_tokens        → "Users manage own tokens" (ALL)
-- ============================================================


-- 3. Fehlen Policies? → DANN und NUR DANN ausführen:
--    Kopiere den fehlenden Block aus app/supabase_rls.sql
--    und führe NUR diesen Block aus (nicht die ganze Datei).
