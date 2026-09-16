-- Parent Portal — attendance audit trail + calendar summary
--
-- `attendance` already stores marked_by/marked_at per row (schema hasn't
-- changed there), but a row is deleted the moment a coach un-marks a
-- student — so there was no way to see "who removed whom" after the fact.
-- attendance_log is a separate, append-only table: every mark and every
-- unmark gets a row here, and rows are never deleted, even once the
-- corresponding attendance row is gone.

create table public.attendance_log (
  id           uuid primary key default gen_random_uuid(),
  school_id    uuid not null references public.schools(id),
  session_date date not null,
  student_id   uuid not null references public.students(id),
  action       text not null check (action in ('added', 'removed')),
  coach_id     uuid not null references public.coaches(id),
  created_at   timestamptz not null default now()
);

create index attendance_log_school_date on public.attendance_log (school_id, session_date, created_at desc);

alter table public.attendance_log enable row level security;

create policy attendance_log_select on public.attendance_log
  for select to authenticated
  using (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()));

create policy attendance_log_insert on public.attendance_log
  for insert to authenticated
  with check (
    coach_id = auth.uid()
    and (public.is_admin() or (public.is_coach() and school_id = public.my_coach_school()))
  );

-- ---------------------------------------------------------------------
-- attendance_month_counts(...) — one query for the whole calendar month:
-- how many students were present on each date that has any attendance at
-- all. Runs as the caller (no security definer), so the existing
-- attendance_select RLS policy still gates which rows it can see.
-- ---------------------------------------------------------------------
create or replace function public.attendance_month_counts(p_school_id uuid, p_start date, p_end date)
returns table (session_date date, present_count bigint)
language sql
stable
set search_path = public, pg_temp
as $$
  select session_date, count(*)::bigint
  from public.attendance
  where school_id = p_school_id
    and session_date >= p_start
    and session_date <= p_end
  group by session_date;
$$;

grant execute on function public.attendance_month_counts(uuid, date, date) to authenticated;

-- ---------------------------------------------------------------------
-- save_attendance(...) — applies a batch of adds/removes for one session
-- date in a single round trip, and writes the matching attendance_log
-- rows in the same transaction. Runs as the caller (no security
-- definer): every insert/delete below still goes through the normal
-- attendance RLS policies for that coach, so this grants no privilege
-- the coach didn't already have — it just makes the multi-row change
-- atomic and saves a round trip per student.
-- ---------------------------------------------------------------------
create or replace function public.save_attendance(
  p_school_id    uuid,
  p_session_date date,
  p_added        uuid[],
  p_removed      uuid[]
)
returns void
language plpgsql
set search_path = public, pg_temp
as $$
declare
  sid uuid;
begin
  foreach sid in array coalesce(p_added, array[]::uuid[])
  loop
    insert into public.attendance (student_id, school_id, session_date, marked_by, marked_at)
    values (sid, p_school_id, p_session_date, auth.uid(), now())
    on conflict (student_id, session_date) do update
      set marked_by = excluded.marked_by, marked_at = excluded.marked_at;

    insert into public.attendance_log (school_id, session_date, student_id, action, coach_id)
    values (p_school_id, p_session_date, sid, 'added', auth.uid());
  end loop;

  foreach sid in array coalesce(p_removed, array[]::uuid[])
  loop
    delete from public.attendance
      where student_id = sid and session_date = p_session_date;

    insert into public.attendance_log (school_id, session_date, student_id, action, coach_id)
    values (p_school_id, p_session_date, sid, 'removed', auth.uid());
  end loop;
end;
$$;

grant execute on function public.save_attendance(uuid, date, uuid[], uuid[]) to authenticated;

-- ---------------------------------------------------------------------
-- attendance_log has no ON DELETE cascade from students or coaches (it's
-- an audit trail, same reasoning as item_ticks/feedback/coach_notes), so
-- the delete functions that wipe a student's or coach's other history
-- must wipe this too, or a delete now fails on a foreign key violation.
-- ---------------------------------------------------------------------
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
  delete from public.attendance_log where student_id = p_student_id;

  delete from auth.users where id = p_student_id;
end;
$$;

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
    (select count(*) from public.attendance where marked_by = p_coach_id) +
    (select count(*) from public.attendance_log where coach_id = p_coach_id)
  into activity_count;

  if activity_count > 0 then
    raise exception 'This coach has recorded activity. Deactivate them instead of deleting.' using errcode = 'PW027';
  end if;

  delete from auth.users where id = p_coach_id;
end;
$$;
