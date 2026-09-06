BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;
SELECT no_plan();
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);
SELECT set_config('request.jwt.claim.role', 'service_role', true);

INSERT INTO auth.users (id, email, raw_user_meta_data)
VALUES ('95000000-0000-4000-8000-000000000001', 'ownership-a@example.invalid', '{}'),
       ('95000000-0000-4000-8000-000000000002', 'ownership-b@example.invalid', '{}');
INSERT INTO public.reflex_subject_profiles (id, owner_user_id, profile_type, display_name)
VALUES ('95000000-0000-4000-8000-000000000011', '95000000-0000-4000-8000-000000000001', 'child', 'Synthetic A'),
       ('95000000-0000-4000-8000-000000000012', '95000000-0000-4000-8000-000000000002', 'child', 'Synthetic B');
INSERT INTO public.enrollments
  (id, user_id, package_id, status, assigned_duration_weeks, start_date, target_completion_date)
VALUES ('95000000-0000-4000-8000-000000000021', '95000000-0000-4000-8000-000000000001', 'moro', 'paused', 4, current_date, current_date + 28),
       ('95000000-0000-4000-8000-000000000022', '95000000-0000-4000-8000-000000000002', 'moro', 'paused', 4, current_date, current_date + 28);

SELECT set_config('request.jwt.claims', '{"role":"authenticated","sub":"95000000-0000-4000-8000-000000000001"}', true);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok($$INSERT INTO public.enrollments
  (user_id, subject_profile_id, package_id, assigned_duration_weeks, start_date, target_completion_date)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000012', 'moro', 4, current_date, current_date + 28)$$,
  '23514', 'training_reference_owner_mismatch', 'cannot occupy another account subject active-enrollment slot');
SELECT lives_ok($$UPDATE public.enrollments SET subject_profile_id = '95000000-0000-4000-8000-000000000011'
  WHERE id = '95000000-0000-4000-8000-000000000021'$$, 'own subject is accepted');
SELECT throws_ok($$UPDATE public.enrollments SET subject_profile_id = '95000000-0000-4000-8000-000000000012'
  WHERE id = '95000000-0000-4000-8000-000000000021'$$,
  '23514', 'training_reference_owner_mismatch', 'cannot move existing enrollment onto foreign subject');

SELECT throws_ok($$INSERT INTO public.streak_credits (id, user_id, subject_profile_id)
VALUES ('ownership-test', '95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000012')$$,
  '23514', 'training_reference_owner_mismatch', 'streak ledger rejects foreign subject');
SELECT throws_ok($$INSERT INTO public.vorrunde_phases (user_id, subject_profile_id)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000012')$$,
  '23514', 'training_reference_owner_mismatch', 'preparation phase rejects foreign subject');
SELECT throws_ok($$INSERT INTO public.reflex_profile_assessments (user_id, subject_profile_id, status, skipped_at)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000012', 'skipped', now())$$,
  '23514', 'training_reference_owner_mismatch', 'assessment rejects foreign subject');
SELECT throws_ok($$INSERT INTO public.journal_entries (user_id, subject_profile_id, content, day_key)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000012', 'Synthetic', 1)$$,
  '23514', 'training_reference_owner_mismatch', 'journal rejects foreign subject');
SELECT throws_ok($$INSERT INTO public.journal_entries (user_id, enrollment_id, content, day_key)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000022', 'Synthetic', 1)$$,
  '23514', 'training_reference_owner_mismatch', 'journal rejects foreign enrollment even without a subject');
SELECT lives_ok($$INSERT INTO public.journal_entries (user_id, content, day_key)
VALUES ('95000000-0000-4000-8000-000000000001', 'Synthetic', 1)$$,
  'legacy journal without subject or enrollment remains valid');
SELECT throws_ok($$INSERT INTO public.progress_entries (user_id, enrollment_id)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000022')$$,
  '23514', 'training_reference_owner_mismatch', 'progress rejects foreign enrollment');
SELECT throws_ok($$INSERT INTO public.training_sessions (user_id, enrollment_id, session_date, day_number, completed_exercise_ids)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000022', current_date, 1, '{}')$$,
  '23514', 'training_reference_owner_mismatch', 'session rejects foreign enrollment');
SELECT throws_ok($$INSERT INTO public.mood_checkins (user_id, enrollment_id, day_key, source)
VALUES ('95000000-0000-4000-8000-000000000001', '95000000-0000-4000-8000-000000000022', 1, 'manual')$$,
  '23514', 'training_reference_owner_mismatch', 'mood rejects foreign enrollment');
SELECT throws_ok($$INSERT INTO public.completion_questionnaires (enrollment_id, subject_profile_id, response, result)
VALUES ('95000000-0000-4000-8000-000000000021', '95000000-0000-4000-8000-000000000012', true, 'passed')$$,
  '23514', 'training_reference_owner_mismatch', 'completion derives owner from enrollment and rejects foreign subject');
SELECT lives_ok($$INSERT INTO public.completion_questionnaires (enrollment_id, subject_profile_id, response, result)
VALUES ('95000000-0000-4000-8000-000000000021', '95000000-0000-4000-8000-000000000011', true, 'passed')$$,
  'completion accepts enrollment owner subject');

RESET ROLE;
INSERT INTO public.reflex_subject_profiles(id,owner_user_id,profile_type,display_name)
VALUES ('95000000-0000-4000-8000-000000000013','95000000-0000-4000-8000-000000000001','child','Synthetic sibling');
SET LOCAL ROLE authenticated;
SELECT throws_ok($$INSERT INTO public.journal_entries(user_id,enrollment_id,subject_profile_id,content,day_key)
VALUES ('95000000-0000-4000-8000-000000000001','95000000-0000-4000-8000-000000000021','95000000-0000-4000-8000-000000000013','Synthetic',1)$$,
  '23514','training_reference_owner_mismatch','sibling data cannot be attributed to another child enrollment');

RESET ROLE;
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT lives_ok($$DELETE FROM public.reflex_subject_profiles
  WHERE id = '95000000-0000-4000-8000-000000000011'$$,
  'subject deletion still clears nullable legacy references');
INSERT INTO public.reflex_subject_profiles (id, owner_user_id, profile_type, display_name)
VALUES ('95000000-0000-4000-8000-000000000011', '95000000-0000-4000-8000-000000000001', 'child', 'Synthetic A');
UPDATE public.enrollments SET subject_profile_id = '95000000-0000-4000-8000-000000000011'
  WHERE id = '95000000-0000-4000-8000-000000000021';
UPDATE public.completion_questionnaires SET subject_profile_id = '95000000-0000-4000-8000-000000000011'
  WHERE enrollment_id = '95000000-0000-4000-8000-000000000021';
SELECT lives_ok($$DELETE FROM auth.users
  WHERE id = '95000000-0000-4000-8000-000000000001'$$,
  'account deletion still cascades through linked training records');
SELECT * FROM finish();
ROLLBACK;
