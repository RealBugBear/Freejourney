-- Reflex profile shares must not outlive the trainer-client relationship.
--
-- Defect: reflex_profile_trainer_shares.revoked_at was the ONLY gate in the
-- trainer-side RLS policies, but nothing in the relationship lifecycle ever set
-- it. accept_invite() deactivates prior relationships (status -> 'disconnected')
-- without touching shares, and no trigger existed. The sole revocation path was
-- a manual toggle in the owner's UI that is rendered only for the currently
-- ACTIVE trainer -- so after a switch the former trainer kept SELECT on the
-- child's subject profile and full assessment, and the owner could no longer
-- even see the switch to turn it off.
--
-- Three layers, deliberately redundant:
--   1. trigger  -- ending or deleting a relationship revokes its shares
--   2. RLS      -- trainer reads additionally require an ACTIVE relationship,
--                  so a stale share row can never grant access on its own
--   3. backfill -- close shares that are already orphaned today
--
-- Idempotent: safe to replay.

-- ---------------------------------------------------------------------------
-- 1. Revoke on relationship end.
--
-- SECURITY DEFINER is required, not cosmetic: "cj: tcr all trainer" lets a
-- trainer update their own relationship row, and reflex_profile_trainer_shares
-- grants writes only to the owner. An INVOKER trigger would therefore update
-- zero rows -- silently -- exactly when a trainer ends the relationship.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.revoke_reflex_shares_on_relationship_end()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  _client  uuid := OLD.client_id;
  _trainer uuid := OLD.trainer_id;
BEGIN
  -- Pending invite rows carry no client yet; nothing can have been shared.
  IF _client IS NULL OR _trainer IS NULL THEN
    RETURN NULL;
  END IF;

  IF TG_OP = 'UPDATE' THEN
    -- Only react to a relationship actually leaving active use. An ordinary
    -- UPDATE (linked_at, notes, ...) must not revoke a live consent.
    IF NOT (OLD.status = 'active' AND NEW.status IS DISTINCT FROM 'active') THEN
      RETURN NULL;
    END IF;
  END IF;

  UPDATE public.reflex_profile_trainer_shares
     SET revoked_at = now(),
         updated_at = now()
   WHERE owner_user_id = _client
     AND trainer_id    = _trainer
     AND revoked_at IS NULL;

  RETURN NULL;
END;
$function$;

REVOKE ALL ON FUNCTION public.revoke_reflex_shares_on_relationship_end()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_revoke_reflex_shares_on_relationship_end
  ON public.trainer_client_relationships;
CREATE TRIGGER trg_revoke_reflex_shares_on_relationship_end
  AFTER UPDATE OR DELETE ON public.trainer_client_relationships
  FOR EACH ROW
  EXECUTE FUNCTION public.revoke_reflex_shares_on_relationship_end();

-- Supports the trigger's revoke predicate.
CREATE INDEX IF NOT EXISTS idx_reflex_profile_trainer_shares_owner_trainer_active
  ON public.reflex_profile_trainer_shares(owner_user_id, trainer_id)
  WHERE revoked_at IS NULL;

-- ---------------------------------------------------------------------------
-- 2. Trainer reads require an ACTIVE relationship, not merely a share row.
--
-- The nested reads of trainer_client_relationships stay inside that table's own
-- RLS ("cj: tcr select participant" covers auth.uid() = trainer_id), so the
-- trainer can still evaluate their own relationship. No recursion: the
-- relationship policies do not reference these tables.
-- ---------------------------------------------------------------------------

DROP POLICY IF EXISTS reflex_subject_profiles_trainer_select
  ON public.reflex_subject_profiles;
CREATE POLICY reflex_subject_profiles_trainer_select
  ON public.reflex_subject_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      JOIN public.trainer_client_relationships r
        ON r.trainer_id = s.trainer_id
       AND r.client_id  = s.owner_user_id
      WHERE s.subject_profile_id = reflex_subject_profiles.id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
        AND r.status = 'active'
    )
  );

DROP POLICY IF EXISTS reflex_profile_assessments_trainer_select
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_trainer_select
  ON public.reflex_profile_assessments FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reflex_profile_trainer_shares s
      JOIN public.trainer_client_relationships r
        ON r.trainer_id = s.trainer_id
       AND r.client_id  = s.owner_user_id
      WHERE s.subject_profile_id = reflex_profile_assessments.subject_profile_id
        AND s.trainer_id = auth.uid()
        AND s.revoked_at IS NULL
        AND r.status = 'active'
    )
  );

DROP POLICY IF EXISTS reflex_profile_trainer_shares_trainer_select
  ON public.reflex_profile_trainer_shares;
CREATE POLICY reflex_profile_trainer_shares_trainer_select
  ON public.reflex_profile_trainer_shares FOR SELECT
  USING (
    trainer_id = auth.uid()
    AND revoked_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM public.trainer_client_relationships r
      WHERE r.trainer_id = reflex_profile_trainer_shares.trainer_id
        AND r.client_id  = reflex_profile_trainer_shares.owner_user_id
        AND r.status = 'active'
    )
  );

-- The owner's own access is unchanged and deliberately covers revoked rows too,
-- so a client can always audit what they once shared.

-- ---------------------------------------------------------------------------
-- 3. Backfill shares that are already orphaned.
--
-- Runs as the migration role, so RLS does not apply. Re-running is a no-op.
-- ---------------------------------------------------------------------------

UPDATE public.reflex_profile_trainer_shares s
   SET revoked_at = now(),
       updated_at = now()
 WHERE s.revoked_at IS NULL
   AND NOT EXISTS (
     SELECT 1
     FROM public.trainer_client_relationships r
     WHERE r.trainer_id = s.trainer_id
       AND r.client_id  = s.owner_user_id
       AND r.status = 'active'
   );
