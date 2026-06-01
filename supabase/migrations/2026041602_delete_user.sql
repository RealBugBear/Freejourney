-- ============================================================================
-- CoreJourney — delete_user RPC
-- Called by the app when a user deletes their account.
-- Deletes the caller's auth.users entry, which cascades to profiles
-- and all child tables (on delete cascade).
--
-- Requires: extensions.http or direct auth admin access via service_role.
-- Uses security definer so the function runs as the DB owner.
--
-- Run against both DEV and PROD.
-- Run in: https://sxvpiggednbftfqeokyd.supabase.co/project/sxvpiggednbftfqeokyd/sql
-- ============================================================================

create or replace function delete_user()
returns void
language plpgsql
security definer
as $$
begin
  -- Delete the calling user from auth.users.
  -- The profiles row (and all cascading data) is removed automatically.
  delete from auth.users where id = auth.uid();
end;
$$;

grant execute on function delete_user() to authenticated;
