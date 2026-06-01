-- ============================================================================
-- CoreJourney — Appointments: proposed-flow support
-- Fixes schema conflict between Dart model and initial trainer_appointments.sql
--
-- Changes:
--   1. scheduled_for → nullable (null when status = 'proposed')
--   2. status CHECK → adds 'proposed'
--   3. proposed_slots column added (timestamptz[])
--
-- Run in: https://sxvpiggednbftfqeokyd.supabase.co/project/sxvpiggednbftfqeokyd/sql
-- ============================================================================

-- 1. Make scheduled_for nullable
alter table appointments
  alter column scheduled_for drop not null;

-- 2. Replace status CHECK to include 'proposed'
alter table appointments
  drop constraint if exists appointments_status_check;

alter table appointments
  add constraint appointments_status_check
    check (status in ('proposed','planned','confirmed','cancelled','done'));

-- 3. Add proposed_slots column (array of timestamptz, empty by default)
alter table appointments
  add column if not exists proposed_slots timestamptz[] not null default '{}';
