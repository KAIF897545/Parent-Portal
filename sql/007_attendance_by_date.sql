-- Parent Portal — migrate attendance to a direct per-student-per-day model
--
-- Replaces class_sessions + attendance(session_id, student_id, present)
-- with a single attendance(student_id, school_id, session_date, ...) table,
-- where a row's existence means "present" — there is no explicit absent
-- record. This removes the get-or-create-a-session step that made "today"
-- fragile, and lets the client compute session_date once, explicitly in
-- Maldives time, instead of relying on whatever timezone happened to be
-- active when a session row was first created.
--
-- Run this once, in the Supabase SQL editor, against the live database.
-- Safe to run only if 001_schema.sql/002_functions.sql/003_policies.sql
-- from before this change already ran (i.e. class_sessions/attendance
-- exist in their original shape).

-- ---------------------------------------------------------------------
-- 1. Move the old attendance table aside and build the new one.
-- ---------------------------------------------------------------------
alter table public.attendance rename to attendance_old;

create table public.attendance (
  id           uuid primary key default gen_random_uuid(),
  student_id   uuid not null references public.students(id) on delete cascade,
  school_id    uuid not null references public.schools(id),
  session_date date not null,
  marked_by    uuid not null references public.coaches(id),
  marked_at    timestamptz not null default now(),
  unique (student_id, session_date)
);

create index attendance_school_date on public.attendance (school_id, session_date);

-- ---------------------------------------------------------------------
-- 2. Carry forward every row that actually meant "present". A present =
--    false row under the old model is equivalent to "no row" under the
--    new one, so it's dropped rather than migrated.
-- ---------------------------------------------------------------------
insert into public.attendance (student_id, school_id, session_date, marked_by)
select ao.student_id, cs.school_id, cs.session_date, cs.coach_id
from public.attendance_old ao
join public.class_sessions cs on cs.id = ao.session_id
where ao.present = true
on conflict (student_id, session_date) do nothing;

-- ---------------------------------------------------------------------
-- 3. Drop the old objects. Their policies go with them automatically.
-- ---------------------------------------------------------------------
drop table public.attendance_old;
drop table public.class_sessions;

-- ---------------------------------------------------------------------
-- 4. Integrity trigger: attendance.school_id must match the student's
--    actual school, so RLS (which trusts attendance.school_id) can't be
--    fooled by a client sending a mismatched school_id.
-- ---------------------------------------------------------------------
create or replace function public.attendance_check_school()
returns trigger
language plpgsql
as $$
begin
  if new.school_id <> (select school_id from public.students where id = new.student_id) then
    raise exception 'Attendance school_id must match the student''s school.' using errcode = 'PW014';
  end if;
  return new;
end;
$$;

create trigger trg_attendance_school_match
before insert or update on public.attendance
for each row execute function public.attendance_check_school();

-- ---------------------------------------------------------------------
-- 5. RLS: a coach reads/writes only her own school's rows; admin
--    reads/writes everywhere; marked_by must always be the caller.
-- ---------------------------------------------------------------------
alter table public.attendance enable row level security;

create policy attendance_select on public.attendance
  for select to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

create policy attendance_insert on public.attendance
  for insert to authenticated
  with check (
    marked_by = auth.uid()
    and (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()))
  );

create policy attendance_update on public.attendance
  for update to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()))
  with check (
    marked_by = auth.uid()
    and (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()))
  );

create policy attendance_delete on public.attendance
  for delete to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));
