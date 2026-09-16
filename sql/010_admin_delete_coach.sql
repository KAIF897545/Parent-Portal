-- Parent Portal — admin_delete_coach
--
-- Deactivating a coach doesn't need a function here — it goes through a
-- plain authenticated update from the admin's own browser session, already
-- allowed by the coaches_update_admin RLS policy from 003_policies.sql.

create or replace function public.admin_delete_coach(p_coach_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  activity_count int;
begin
  if not exists (select 1 from public.coaches c where c.id = p_coach_id) then
    raise exception 'Unknown coach.' using errcode = 'PW008';
  end if;

  select
    (select count(*) from public.item_ticks where marked_by = p_coach_id) +
    (select count(*) from public.checkpoint_passes where marked_by = p_coach_id) +
    (select count(*) from public.feedback where coach_id = p_coach_id) +
    (select count(*) from public.coach_notes where coach_id = p_coach_id) +
    (select count(*) from public.attendance where marked_by = p_coach_id)
  into activity_count;

  if activity_count > 0 then
    raise exception 'This coach has recorded activity. Deactivate them instead of deleting.' using errcode = 'PW027';
  end if;

  delete from auth.users where id = p_coach_id;
end;
$$;

revoke all on function public.admin_delete_coach(uuid) from public;
grant execute on function public.admin_delete_coach(uuid) to service_role;
