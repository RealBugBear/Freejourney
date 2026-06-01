-- ============================================================================
-- CoreJourney — User Consents
-- Stores a permanent audit trail of every user's disclaimer acceptance.
-- Run against both DEV and PROD.
--
-- Run in: https://sxvpiggednbftfqeokyd.supabase.co/project/sxvpiggednbftfqeokyd/sql
-- ============================================================================

create table if not exists user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  consent_version int not null,
  consented_at timestamptz not null default now(),

  -- One row per user per version (upsert-safe)
  unique (user_id, consent_version)
);

-- Only the user themselves and service_role can read/write
alter table user_consents enable row level security;

create policy "Users manage own consent" on user_consents
  for all using (auth.uid() = user_id);

-- Index for fast lookups per user
create index if not exists idx_user_consents_user on user_consents(user_id, consent_version);
