-- T23 (D4, 2026-07-07): Entitlement-Felder für die Paywall-Grundstruktur.
-- Die Paywall ist client-seitig hinter kPaywallEnabled=false deaktiviert;
-- dieses Schema ist die vorbereitete Grundlage für T24 (Freischalt-Codes)
-- und T25 (RevenueCat/IAP). Design: docs/superpowers/specs/
-- 2026-05-28-monetization-design.md §3 (+ 'code' für Gründungsnutzer-Codes).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS premium_type text
    CHECK (premium_type IN ('monthly', 'yearly', 'lifetime', 'code')),
  ADD COLUMN IF NOT EXISTS premium_valid_until timestamptz,
  ADD COLUMN IF NOT EXISTS stripe_customer_id text;

-- Entitlements sind Zahlungsäquivalente: Clients dürfen sie NIE selbst
-- setzen — profiles ist per RLS durch den Eigentümer updatebar, deshalb
-- derselbe Schutz wie bei der Rolle (Muster: 2026041504
-- prevent_direct_role_change). Nur service_role (Edge Functions:
-- Stripe-/RevenueCat-Webhook, redeem-access-code) darf diese Felder ändern.
CREATE OR REPLACE FUNCTION public.prevent_direct_premium_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() != 'service_role' AND (
       OLD.is_premium         IS DISTINCT FROM NEW.is_premium
    OR OLD.premium_type       IS DISTINCT FROM NEW.premium_type
    OR OLD.premium_valid_until IS DISTINCT FROM NEW.premium_valid_until
    OR OLD.stripe_customer_id IS DISTINCT FROM NEW.stripe_customer_id
  ) THEN
    RAISE EXCEPTION
      'Changing premium entitlement columns directly is not permitted. '
      'Entitlements are granted server-side only.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_direct_premium_change ON public.profiles;

CREATE TRIGGER trg_prevent_direct_premium_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_premium_change();
