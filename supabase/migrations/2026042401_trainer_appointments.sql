-- ============================================================================
-- CoreJourney — Trainer Appointment System Migration
-- Run in: https://sxvpiggednbftfqeokyd.supabase.co/project/sxvpiggednbftfqeokyd/sql
-- ============================================================================

-- ----------------------------------------------------------------------------
-- APPOINTMENTS
-- ----------------------------------------------------------------------------
create table if not exists appointments (
  id uuid primary key default gen_random_uuid(),
  trainer_id uuid not null references profiles(id) on delete cascade,
  trainee_id uuid not null references profiles(id) on delete cascade,
  title text not null default 'Isometrische Partnerübung',
  scheduled_for timestamptz not null,
  duration_minutes int not null default 60,
  location text,
  notes text,
  status text not null default 'planned'
    check (status in ('planned','confirmed','cancelled','done')),
  trigger text
    check (trigger in ('early_warning','completion_day','manual')),
  trainee_day_number int,
  calendar_event_id text,
  calendar_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_appointments_trainer on appointments(trainer_id, scheduled_for);
create index if not exists idx_appointments_trainee on appointments(trainee_id);

-- RLS
alter table appointments enable row level security;

create policy "Trainers manage own appointments" on appointments
  for all using (auth.uid() = trainer_id);

create policy "Trainees read own appointments" on appointments
  for select using (auth.uid() = trainee_id);

-- ----------------------------------------------------------------------------
-- INVITE CODE on trainer_client_relationships (ensure column exists)
-- ----------------------------------------------------------------------------
alter table trainer_client_relationships
  add column if not exists invite_code text unique;

-- ----------------------------------------------------------------------------
-- RPC: create_invite_code
-- Generates a unique 6-char invite code and stores it on a new relationship row.
-- Returns the code.
-- ----------------------------------------------------------------------------
create or replace function create_invite_code()
returns text
language plpgsql
security definer
as $$
declare
  _code text;
  _trainer_id uuid := auth.uid();
begin
  -- Verify caller is a trainer
  if not exists (
    select 1 from profiles where id = _trainer_id and role = 'trainer'
  ) then
    raise exception 'Only trainers can create invite codes';
  end if;

  -- Generate unique 6-character alphanumeric code
  loop
    _code := upper(substring(md5(random()::text), 1, 6));
    exit when not exists (
      select 1 from trainer_client_relationships where invite_code = _code
    );
  end loop;

  -- Insert a pending relationship placeholder (no client yet)
  insert into trainer_client_relationships (trainer_id, invite_code, status)
  values (_trainer_id, _code, 'pending')
  on conflict do nothing;

  return _code;
end;
$$;

-- ----------------------------------------------------------------------------
-- RPC: accept_invite
-- Client calls this with a code to link themselves to a trainer.
-- ----------------------------------------------------------------------------
create or replace function accept_invite(p_code text)
returns void
language plpgsql
security definer
as $$
declare
  _rel trainer_client_relationships%rowtype;
  _client_id uuid := auth.uid();
begin
  select * into _rel
  from trainer_client_relationships
  where invite_code = upper(trim(p_code))
    and status = 'pending'
    and client_id is null;

  if not found then
    raise exception 'Invalid or already used invite code';
  end if;

  update trainer_client_relationships
  set client_id = _client_id,
      status = 'active',
      linked_at = now()
  where id = _rel.id;
end;
$$;

-- ----------------------------------------------------------------------------
-- RPC: get_trainer_clients
-- Returns all active clients for the calling trainer with progress info.
-- ----------------------------------------------------------------------------
create or replace function get_trainer_clients()
returns table (
  relationship_id uuid,
  client_id uuid,
  display_name text,
  package_id text,
  current_day int,
  daily_streak int,
  last_activity_date date,
  trainer_notes text,
  linked_at timestamptz
)
language sql
security definer
as $$
  select
    tcr.id as relationship_id,
    tcr.client_id,
    coalesce(p.display_name, p.id::text) as display_name,
    e.package_id,
    coalesce(pe.current_day, 1) as current_day,
    coalesce(pe.daily_streak, 0) as daily_streak,
    pe.last_activity_date,
    tcr.trainer_notes,
    tcr.linked_at
  from trainer_client_relationships tcr
  join profiles p on p.id = tcr.client_id
  left join enrollments e on e.user_id = tcr.client_id and e.status = 'active'
  left join progress_entries pe on pe.enrollment_id = e.id
  where tcr.trainer_id = auth.uid()
    and tcr.status = 'active'
  order by pe.current_day desc nulls last;
$$;

-- ----------------------------------------------------------------------------
-- RPC: get_client_sessions
-- Returns last 30 days of sessions for a specific client.
-- ----------------------------------------------------------------------------
create or replace function get_client_sessions(p_client_id uuid)
returns table (
  session_date date,
  is_completed boolean,
  day_number int
)
language sql
security definer
as $$
  select
    ts.session_date,
    ts.is_completed,
    ts.day_number
  from training_sessions ts
  where ts.user_id = p_client_id
    and ts.session_date >= current_date - interval '30 days'
    and exists (
      select 1 from trainer_client_relationships tcr
      where tcr.trainer_id = auth.uid()
        and tcr.client_id = p_client_id
        and tcr.status = 'active'
    )
  order by ts.session_date desc;
$$;

-- ----------------------------------------------------------------------------
-- Grant execute permissions
-- ----------------------------------------------------------------------------
grant execute on function create_invite_code() to authenticated;
grant execute on function accept_invite(text) to authenticated;
grant execute on function get_trainer_clients() to authenticated;
grant execute on function get_client_sessions(uuid) to authenticated;
