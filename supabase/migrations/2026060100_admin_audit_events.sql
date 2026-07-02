-- General audit trail for admin web actions not covered by domain-specific audit tables.
CREATE TABLE IF NOT EXISTS public.admin_audit_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  action text NOT NULL,
  target_type text NOT NULL,
  target_id uuid,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_events_created_at
  ON public.admin_audit_events(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_audit_events_actor_created
  ON public.admin_audit_events(actor_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_admin_audit_events_target
  ON public.admin_audit_events(target_type, target_id);

ALTER TABLE public.admin_audit_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS admin_audit_events_admin_select
  ON public.admin_audit_events;
CREATE POLICY admin_audit_events_admin_select
  ON public.admin_audit_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS admin_audit_events_admin_insert
  ON public.admin_audit_events;
CREATE POLICY admin_audit_events_admin_insert
  ON public.admin_audit_events FOR INSERT
  WITH CHECK (
    actor_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

REVOKE ALL ON public.admin_audit_events FROM PUBLIC;
GRANT SELECT, INSERT ON public.admin_audit_events TO authenticated;

COMMENT ON TABLE public.admin_audit_events IS
  'General audit trail for admin web actions. V1 writes are client-side after successful mutations and are not atomic with the domain mutation.';
