-- Parent Portal — fix trg_students_coach_update_scope blocking legitimate updates
--
-- enforce_student_coach_update_scope() (sql/016) was meant to stop a coach's
-- own client-side update from touching anything but group_id, exempting only
-- public.is_admin(). But it's a plain BEFORE UPDATE trigger, so it fires on
-- every update to students regardless of who's doing it or how -- including
-- two paths that were never meant to be restricted at all:
--
--   * set_my_password -- a student flipping their own must_change_password
--     to false after choosing a real password. auth.uid() here is the
--     student's own id, which is never in coaches, so is_admin() is false
--     and the trigger rejected it with PW028. This has been silently
--     breaking first-login for every student since sql/016 shipped.
--
--   * admin_set_student_password -- called from the server with the service
--     role key, which carries no JWT/user context at all, so auth.uid() is
--     null. is_admin() is false there too (it compares against auth.uid()),
--     so admin-triggered password resets have been broken the same way.
--
-- Fixed by also exempting: auth.uid() is null (server-side/service-role
-- calls, which are already trusted by the API layer's requireAdmin() or are
-- a student's own SECURITY DEFINER RPC) and auth.uid() = new.id (a student
-- updating their own row). A coach's own client-side update is neither --
-- auth.uid() is their own id, which is never null and never equals the
-- student's id -- so the original restriction still applies to exactly the
-- case it was built for.

create or replace function public.enforce_student_coach_update_scope()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() or auth.uid() is null or auth.uid() = new.id then
    return new;
  end if;

  if new.school_id is distinct from old.school_id
    or new.student_code is distinct from old.student_code
    or new.full_name is distinct from old.full_name
    or new.login_name is distinct from old.login_name
    or new.current_module_id is distinct from old.current_module_id
    or new.must_change_password is distinct from old.must_change_password
    or new.active is distinct from old.active
  then
    raise exception 'Coaches can only change a student''s group.' using errcode = 'PW028';
  end if;

  return new;
end;
$$;
