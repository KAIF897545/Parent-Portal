-- Parent Portal — coaches can reassign a student's group; delete a note
--
-- 1) Group assignment previously required the admin panel (students_update_admin
-- is the only update policy, gated on public.is_admin()). Coaches now get
-- their own update policy scoped to students at their school, but RLS alone
-- can't express a column-level restriction -- a permissive USING/WITH CHECK
-- that lets a coach touch the row at all would let them touch every column.
-- A trigger blocks non-admin callers from changing anything except group_id:
-- renaming a student, moving them to a different module, or reactivating/
-- deactivating them still requires an admin.
--
-- 2) coach_notes already had an update policy (added ahead of an editing UI
-- that never shipped) but no delete -- coaches could never remove a note.
-- Reuses the same can_manage_student authorization as coach_notes_update.

create policy students_update_coach_group on public.students
  for update to authenticated
  using (public.can_manage_student(id))
  with check (public.can_manage_student(id));

create or replace function public.enforce_student_coach_update_scope()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
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

create trigger trg_students_coach_update_scope
before update on public.students
for each row execute function public.enforce_student_coach_update_scope();

create policy coach_notes_delete on public.coach_notes
  for delete to authenticated using (public.can_manage_student(student_id));
