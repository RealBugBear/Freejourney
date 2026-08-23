-- Second repair of the repository/live drift (CLAUDE.md mistake #11).
--
-- Found by a read-only comparison of every public column, live against a
-- database built from this repository (founder-approved, 2026-08-23). Two
-- differences remained after 2026072300. They are different in kind:
--
--   1. journal_entries.day_key — NOT missing. The baseline migration
--      (20260412_core_schema_baseline.sql:250) creates it as `integer`, while
--      live has `bigint`. The comparison listed name plus type, which is why
--      it first looked like a missing column. Nothing breaks either way: the
--      value is an epoch day (~20,000), far inside integer range, and the app
--      reads it as a plain int. Widened here purely so the repository stops
--      describing a shape the live database does not have.
--
--   2. profiles.is_anonymous_default — genuinely missing. No migration creates
--      it, yet Profile.fromJson/toJson read and write it. A database built
--      from this repository would reject every profile write carrying the
--      field.
--
-- Today's date is fine as a version: no migration references either column, so
-- this file does not need to run before anything. On the live database both
-- statements are no-ops.
--
-- Definitions were read from the live database, not inferred:
--   journal_entries.day_key        bigint  NOT NULL, no default
--   profiles.is_anonymous_default  boolean NOT NULL DEFAULT false

-- Widening integer -> bigint keeps every existing value and cannot fail.
ALTER TABLE public.journal_entries
  ALTER COLUMN day_key TYPE bigint;

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_anonymous_default boolean NOT NULL DEFAULT false;
