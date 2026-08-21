-- Reflex profile trainer shares must not outlive the trainer-client relationship.
--
-- Regression cover for the defect where switching or ending a trainer left
-- reflex_profile_trainer_shares.revoked_at NULL, so the former trainer kept
-- SELECT on the child's subject profile and full assessment while the owner's
-- UI no longer offered any way to revoke it.
--
-- Synthetic accounts only. No real client data.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Synthetic accounts. These UUIDs/emails exist only inside this transaction.
-- ---------------------------------------------------------------------------

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  fixture.id,
  'authenticated',
  'authenticated',
  fixture.email,
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  ''
FROM (
  VALUES
    ('27270000-0000-4000-8000-000000000001'::uuid, 't27-trainer-old@example.invalid'),
    ('27270000-0000-4000-8000-000000000002'::uuid, 't27-trainer-new@example.invalid'),
    ('27270000-0000-4000-8000-000000000003'::uuid, 't27-parent@example.invalid'),
    ('27270000-0000-4000-8000-000000000004'::uuid, 't27-trainer-keep@example.invalid'),
    ('27270000-0000-4000-8000-000000000005'::uuid, 't27-parent-keep@example.invalid')
) AS fixture(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles
   SET role = 'trainer'
 WHERE id IN (
   '27270000-0000-4000-8000-000000000001',
   '27270000-0000-4000-8000-000000000002',
   '27270000-0000-4000-8000-000000000004'
 );

-- ---------------------------------------------------------------------------
-- A parent-owned child profile with a completed assessment, shared with the
-- currently active trainer.
-- ---------------------------------------------------------------------------

INSERT INTO public.reflex_subject_profiles (
  id, owner_user_id, profile_type, display_name, age_group
) VALUES (
  '27271000-0000-4000-8000-000000000001',
  '27270000-0000-4000-8000-000000000003',
  'child',
  'Testkind',
  '5-7'
);

INSERT INTO public.reflex_profile_assessments (
  id, user_id, subject_profile_id, status, completed_at
) VALUES (
  '27272000-0000-4000-8000-000000000001',
  '27270000-0000-4000-8000-000000000003',
  '27271000-0000-4000-8000-000000000001',
  'completed',
  now()
);

INSERT INTO public.trainer_client_relationships (
  id, trainer_id, client_id, status, linked_at
) VALUES (
  '27273000-0000-4000-8000-000000000001',
  '27270000-0000-4000-8000-000000000001',
  '27270000-0000-4000-8000-000000000003',
  'active',
  now()
);

INSERT INTO public.reflex_profile_trainer_shares (
  id, subject_profile_id, owner_user_id, trainer_id, relationship_id
) VALUES (
  '27274000-0000-4000-8000-000000000001',
  '27271000-0000-4000-8000-000000000001',
  '27270000-0000-4000-8000-000000000003',
  '27270000-0000-4000-8000-000000000001',
  '27273000-0000-4000-8000-000000000001'
);

-- ---------------------------------------------------------------------------
-- Baseline: while the relationship is active the trainer legitimately reads.
-- ---------------------------------------------------------------------------

SELECT set_config('request.jwt.claim.sub', '27270000-0000-4000-8000-000000000001', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"27270000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_subject_profiles
     WHERE id = '27271000-0000-4000-8000-000000000001'
  ),
  1,
  'active trainer reads the shared subject profile'
);
SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_profile_assessments
     WHERE subject_profile_id = '27271000-0000-4000-8000-000000000001'
  ),
  1,
  'active trainer reads the shared assessment'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- The switch. accept_invite() deactivates prior relationships exactly this way.
-- ---------------------------------------------------------------------------

UPDATE public.trainer_client_relationships
   SET status = 'disconnected'
 WHERE id = '27273000-0000-4000-8000-000000000001';

SELECT isnt(
  (
    SELECT revoked_at FROM public.reflex_profile_trainer_shares
     WHERE id = '27274000-0000-4000-8000-000000000001'
  ),
  NULL,
  'leaving active status revokes the reflex profile share'
);

-- ---------------------------------------------------------------------------
-- The former trainer must lose both reads immediately.
-- ---------------------------------------------------------------------------

SELECT set_config('request.jwt.claim.sub', '27270000-0000-4000-8000-000000000001', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"27270000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_subject_profiles
     WHERE id = '27271000-0000-4000-8000-000000000001'
  ),
  0,
  'former trainer cannot read the subject profile after the relationship ends'
);
SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_profile_assessments
     WHERE subject_profile_id = '27271000-0000-4000-8000-000000000001'
  ),
  0,
  'former trainer cannot read the assessment after the relationship ends'
);
SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_profile_trainer_shares
     WHERE id = '27274000-0000-4000-8000-000000000001'
  ),
  0,
  'former trainer cannot read the share row itself'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Deleting the relationship row must revoke too. relationship_id is
-- ON DELETE SET NULL, so the share would otherwise survive unlinked.
-- ---------------------------------------------------------------------------

INSERT INTO public.reflex_subject_profiles (
  id, owner_user_id, profile_type, display_name, age_group
) VALUES (
  '27271000-0000-4000-8000-000000000002',
  '27270000-0000-4000-8000-000000000003',
  'child',
  'Testkind zwei',
  '8-10'
);

INSERT INTO public.trainer_client_relationships (
  id, trainer_id, client_id, status, linked_at
) VALUES (
  '27273000-0000-4000-8000-000000000002',
  '27270000-0000-4000-8000-000000000002',
  '27270000-0000-4000-8000-000000000003',
  'active',
  now()
);

INSERT INTO public.reflex_profile_trainer_shares (
  id, subject_profile_id, owner_user_id, trainer_id, relationship_id
) VALUES (
  '27274000-0000-4000-8000-000000000002',
  '27271000-0000-4000-8000-000000000002',
  '27270000-0000-4000-8000-000000000003',
  '27270000-0000-4000-8000-000000000002',
  '27273000-0000-4000-8000-000000000002'
);

DELETE FROM public.trainer_client_relationships
 WHERE id = '27273000-0000-4000-8000-000000000002';

SELECT isnt(
  (
    SELECT revoked_at FROM public.reflex_profile_trainer_shares
     WHERE id = '27274000-0000-4000-8000-000000000002'
  ),
  NULL,
  'deleting the relationship revokes the reflex profile share'
);

-- ---------------------------------------------------------------------------
-- No over-revocation: an unrelated active pairing keeps working.
-- ---------------------------------------------------------------------------

INSERT INTO public.reflex_subject_profiles (
  id, owner_user_id, profile_type, display_name, age_group
) VALUES (
  '27271000-0000-4000-8000-000000000003',
  '27270000-0000-4000-8000-000000000005',
  'child',
  'Testkind drei',
  '3-4'
);

INSERT INTO public.trainer_client_relationships (
  id, trainer_id, client_id, status, linked_at
) VALUES (
  '27273000-0000-4000-8000-000000000003',
  '27270000-0000-4000-8000-000000000004',
  '27270000-0000-4000-8000-000000000005',
  'active',
  now()
);

INSERT INTO public.reflex_profile_trainer_shares (
  id, subject_profile_id, owner_user_id, trainer_id, relationship_id
) VALUES (
  '27274000-0000-4000-8000-000000000003',
  '27271000-0000-4000-8000-000000000003',
  '27270000-0000-4000-8000-000000000005',
  '27270000-0000-4000-8000-000000000004',
  '27273000-0000-4000-8000-000000000003'
);

-- Re-run the earlier revocations' side effects by touching an unrelated row.
UPDATE public.trainer_client_relationships
   SET linked_at = now()
 WHERE id = '27273000-0000-4000-8000-000000000003';

SELECT is(
  (
    SELECT revoked_at FROM public.reflex_profile_trainer_shares
     WHERE id = '27274000-0000-4000-8000-000000000003'
  ),
  NULL,
  'an update that does not end the relationship leaves the share intact'
);

SELECT set_config('request.jwt.claim.sub', '27270000-0000-4000-8000-000000000004', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"27270000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_subject_profiles
     WHERE id = '27271000-0000-4000-8000-000000000003'
  ),
  1,
  'a still-active trainer keeps reading their shared profile'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- The owner always keeps full control of their own share rows.
-- ---------------------------------------------------------------------------

SELECT set_config('request.jwt.claim.sub', '27270000-0000-4000-8000-000000000003', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"27270000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (
    SELECT count(*)::integer FROM public.reflex_profile_trainer_shares
     WHERE owner_user_id = '27270000-0000-4000-8000-000000000003'
  ),
  2,
  'the owner still sees every share they ever granted, revoked or not'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
