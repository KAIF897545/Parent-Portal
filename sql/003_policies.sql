-- Parent Portal — row level security
-- Run after 002_functions.sql. Enables RLS on every table and adds policies.
-- service_role bypasses RLS automatically and is used only by /api functions.

alter table public.schools           enable row level security;
alter table public.school_groups     enable row level security;
alter table public.modules           enable row level security;
alter table public.units             enable row level security;
alter table public.items             enable row level security;
alter table public.students          enable row level security;
alter table public.coaches           enable row level security;
alter table public.item_ticks        enable row level security;
alter table public.checkpoint_passes enable row level security;
alter table public.feedback          enable row level security;
alter table public.coach_notes       enable row level security;
alter table public.class_sessions    enable row level security;
alter table public.attendance        enable row level security;

-- ---------------------------------------------------------------------
-- schools — public listing (portals.html, pre-login), admin writes
-- ---------------------------------------------------------------------
create policy schools_select_all on public.schools
  for select to anon, authenticated using (true);

create policy schools_write_admin on public.schools
  for insert to authenticated with check (public.is_admin());

create policy schools_update_admin on public.schools
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- school_groups — coach/admin read within school, student reads her own
-- school's groups (needed to show her own group name), admin writes
-- ---------------------------------------------------------------------
create policy school_groups_select on public.school_groups
  for select to authenticated
  using (
    public.is_admin()
    or (public.is_coach() and school_id = public.my_coach_school())
    or (public.is_active_student() and school_id = public.my_student_school())
  );

create policy school_groups_write_admin on public.school_groups
  for insert to authenticated with check (public.is_admin());

create policy school_groups_update_admin on public.school_groups
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- curriculum — readable by any signed-in role, writes reserved to service_role
-- ---------------------------------------------------------------------
create policy modules_select on public.modules for select to authenticated using (true);
create policy units_select   on public.units   for select to authenticated using (true);
create policy items_select   on public.items   for select to authenticated using (true);

-- ---------------------------------------------------------------------
-- students
-- ---------------------------------------------------------------------
create policy students_select on public.students
  for select to authenticated
  using (public.can_manage_student(id) or (auth.uid() = id and public.is_active_student()));

create policy students_insert_admin on public.students
  for insert to authenticated with check (public.is_admin());

create policy students_update_admin on public.students
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- coaches
-- ---------------------------------------------------------------------
create policy coaches_select on public.coaches
  for select to authenticated
  using (auth.uid() = id or public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

create policy coaches_insert_admin on public.coaches
  for insert to authenticated with check (public.is_admin());

create policy coaches_update_admin on public.coaches
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- ---------------------------------------------------------------------
-- item_ticks
-- ---------------------------------------------------------------------
create policy item_ticks_select on public.item_ticks
  for select to authenticated using (public.can_see_student(student_id));

create policy item_ticks_insert on public.item_ticks
  for insert to authenticated
  with check (marked_by = auth.uid() and public.can_manage_student(student_id));

create policy item_ticks_update on public.item_ticks
  for update to authenticated
  using (public.can_manage_student(student_id))
  with check (marked_by = auth.uid() and public.can_manage_student(student_id));

-- ---------------------------------------------------------------------
-- checkpoint_passes
-- ---------------------------------------------------------------------
create policy checkpoint_passes_select on public.checkpoint_passes
  for select to authenticated using (public.can_see_student(student_id));

create policy checkpoint_passes_insert on public.checkpoint_passes
  for insert to authenticated
  with check (marked_by = auth.uid() and public.can_manage_student(student_id));

create policy checkpoint_passes_update on public.checkpoint_passes
  for update to authenticated
  using (public.can_manage_student(student_id))
  with check (marked_by = auth.uid() and public.can_manage_student(student_id));

-- ---------------------------------------------------------------------
-- feedback — student reads their own; coach/admin read & write their school's
-- ---------------------------------------------------------------------
create policy feedback_select on public.feedback
  for select to authenticated using (public.can_see_student(student_id));

create policy feedback_insert on public.feedback
  for insert to authenticated
  with check (coach_id = auth.uid() and public.can_manage_student(student_id));

create policy feedback_update on public.feedback
  for update to authenticated
  using (public.can_manage_student(student_id))
  with check (coach_id = auth.uid() and public.can_manage_student(student_id));

-- ---------------------------------------------------------------------
-- coach_notes — coach/admin only, never the student (no policy grants them access)
-- ---------------------------------------------------------------------
create policy coach_notes_select on public.coach_notes
  for select to authenticated using (public.can_manage_student(student_id));

create policy coach_notes_insert on public.coach_notes
  for insert to authenticated
  with check (coach_id = auth.uid() and public.can_manage_student(student_id));

create policy coach_notes_update on public.coach_notes
  for update to authenticated
  using (public.can_manage_student(student_id))
  with check (coach_id = auth.uid() and public.can_manage_student(student_id));

-- ---------------------------------------------------------------------
-- class_sessions
-- ---------------------------------------------------------------------
create policy class_sessions_select on public.class_sessions
  for select to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

create policy class_sessions_insert on public.class_sessions
  for insert to authenticated
  with check (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

create policy class_sessions_update on public.class_sessions
  for update to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()))
  with check (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

-- ---------------------------------------------------------------------
-- attendance — scoped through its class_session's school
-- ---------------------------------------------------------------------
create policy attendance_select on public.attendance
  for select to authenticated
  using (exists (
    select 1 from public.class_sessions cs
    where cs.id = session_id
      and (public.is_admin() or (public.is_coach() and cs.school_id = public.my_coach_school()))
  ));

create policy attendance_insert on public.attendance
  for insert to authenticated
  with check (exists (
    select 1 from public.class_sessions cs
    where cs.id = session_id
      and (public.is_admin() or (public.is_coach() and cs.school_id = public.my_coach_school()))
  ));

create policy attendance_update on public.attendance
  for update to authenticated
  using (exists (
    select 1 from public.class_sessions cs
    where cs.id = session_id
      and (public.is_admin() or (public.is_coach() and cs.school_id = public.my_coach_school()))
  ))
  with check (exists (
    select 1 from public.class_sessions cs
    where cs.id = session_id
      and (public.is_admin() or (public.is_coach() and cs.school_id = public.my_coach_school()))
  ));
