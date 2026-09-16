-- Parent Portal — admin_delete_student and admin_delete_school
--
-- Pure additions (create or replace, fresh grants). Editing a student or
-- school, and deactivating a student, don't need functions here — they go
-- through a plain authenticated update from the admin's own browser
-- session, already allowed by the students_update_admin / schools_update_admin
-- RLS policies from 003_policies.sql.

create or replace function public.admin_delete_student(p_student_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (select 1 from public.students s where s.id = p_student_id) then
    raise exception 'Unknown student.' using errcode = 'PW007';
  end if;

  delete from public.item_ticks where student_id = p_student_id;
  delete from public.checkpoint_passes where student_id = p_student_id;
  delete from public.feedback where student_id = p_student_id;
  delete from public.coach_notes where student_id = p_student_id;

  delete from auth.users where id = p_student_id;
end;
$$;

revoke all on function public.admin_delete_student(uuid) from public;
grant execute on function public.admin_delete_student(uuid) to service_role;

create or replace function public.admin_delete_school(p_school_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  student_count int;
  coach_count   int;
begin
  if not exists (select 1 from public.schools sc where sc.id = p_school_id) then
    raise exception 'Unknown school.' using errcode = 'PW009';
  end if;

  select count(*) into student_count from public.students where school_id = p_school_id;
  select count(*) into coach_count from public.coaches where school_id = p_school_id;

  if student_count > 0 or coach_count > 0 then
    raise exception 'Remove every student and coach from this school before deleting it.' using errcode = 'PW026';
  end if;

  delete from public.school_groups where school_id = p_school_id;
  delete from public.schools where id = p_school_id;
end;
$$;

revoke all on function public.admin_delete_school(uuid) from public;
grant execute on function public.admin_delete_school(uuid) to service_role;
