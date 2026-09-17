-- Parent Portal — schema
-- Run this first, in the Supabase SQL editor.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- schools
-- ---------------------------------------------------------------------
create table public.schools (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  location   text,
  prefix     text not null unique check (prefix ~ '^[A-Z]{2,6}$'),
  created_at timestamptz not null default now()
);

create or replace function public.schools_lock_prefix()
returns trigger
language plpgsql
as $$
begin
  if new.prefix <> old.prefix and exists (
    select 1 from public.students where school_id = new.id
  ) then
    raise exception 'Prefix is locked once a school has students.' using errcode = 'PW013';
  end if;
  return new;
end;
$$;

create trigger trg_schools_lock_prefix
before update of prefix on public.schools
for each row execute function public.schools_lock_prefix();

-- ---------------------------------------------------------------------
-- school_groups
-- ---------------------------------------------------------------------
create table public.school_groups (
  id         uuid primary key default gen_random_uuid(),
  school_id  uuid not null references public.schools(id),
  name       text not null,
  created_at timestamptz not null default now(),
  unique (school_id, name)
);

-- ---------------------------------------------------------------------
-- curriculum: modules / units / items
-- ---------------------------------------------------------------------
create table public.modules (
  id     uuid primary key default gen_random_uuid(),
  number int  not null unique,
  name   text not null
);

create table public.units (
  id         uuid primary key default gen_random_uuid(),
  module_id  uuid not null references public.modules(id),
  number     text not null,   -- e.g. '1.1'
  name       text not null,
  sort_order int  not null,
  unique (module_id, number)
);

create table public.items (
  id            uuid primary key default gen_random_uuid(),
  unit_id       uuid not null references public.units(id),
  description   text not null,
  pass_standard text not null,
  is_checkpoint boolean not null default false,
  sort_order    int not null
);

-- ---------------------------------------------------------------------
-- students  (id == auth.users.id)
-- ---------------------------------------------------------------------
create table public.students (
  id                  uuid primary key references auth.users(id) on delete cascade,
  school_id           uuid not null references public.schools(id),
  student_code        text not null,
  full_name           text not null,
  login_name          text not null,
  group_id            uuid references public.school_groups(id),
  current_module_id   uuid not null references public.modules(id),
  must_change_password boolean not null default true,
  active              boolean not null default true,
  created_at          timestamptz not null default now(),
  unique (school_id, student_code)
);

create index students_login_lookup on public.students (school_id, login_name) where active;

create or replace function public.students_set_login_name()
returns trigger
language plpgsql
as $$
begin
  new.login_name := lower(regexp_replace(btrim(new.full_name), '\s+', ' ', 'g'));
  return new;
end;
$$;

create trigger trg_students_login_name
before insert or update of full_name on public.students
for each row execute function public.students_set_login_name();

create or replace function public.students_block_school_change()
returns trigger
language plpgsql
as $$
begin
  if new.school_id <> old.school_id then
    raise exception 'Students cannot be moved between schools.' using errcode = 'PW010';
  end if;
  return new;
end;
$$;

create trigger trg_students_no_school_move
before update of school_id on public.students
for each row execute function public.students_block_school_change();

-- ---------------------------------------------------------------------
-- coaches  (id == auth.users.id; role 'admin' has no school)
-- ---------------------------------------------------------------------
create table public.coaches (
  id         uuid primary key references auth.users(id) on delete cascade,
  school_id  uuid references public.schools(id),
  name       text not null,
  role       text not null check (role in ('coach', 'admin')),
  active     boolean not null default true,
  created_at timestamptz not null default now(),
  constraint coaches_role_school_chk check (
    (role = 'admin' and school_id is null) or
    (role = 'coach' and school_id is not null)
  )
);

-- ---------------------------------------------------------------------
-- item_ticks — one row per student per non-checkpoint item
-- ---------------------------------------------------------------------
create table public.item_ticks (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  item_id    uuid not null references public.items(id),
  marked_by  uuid not null references public.coaches(id),
  marked_on  date not null default current_date,
  unique (student_id, item_id)
);

create or replace function public.enforce_non_checkpoint_item()
returns trigger
language plpgsql
as $$
declare
  is_cp boolean;
begin
  select is_checkpoint into is_cp from public.items where id = new.item_id;
  if is_cp then
    raise exception 'Checkpoint items are recorded in checkpoint_passes, not item_ticks.' using errcode = 'PW011';
  end if;
  return new;
end;
$$;

create trigger trg_item_ticks_non_checkpoint
before insert or update on public.item_ticks
for each row execute function public.enforce_non_checkpoint_item();

-- ---------------------------------------------------------------------
-- checkpoint_passes — one row per student per checkpoint item, with evidence
-- ---------------------------------------------------------------------
create table public.checkpoint_passes (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  item_id    uuid not null references public.items(id),
  evidence   text not null check (length(btrim(evidence)) > 0),
  marked_by  uuid not null references public.coaches(id),
  marked_on  date not null default current_date,
  unique (student_id, item_id)
);

create or replace function public.enforce_checkpoint_item()
returns trigger
language plpgsql
as $$
declare
  is_cp boolean;
begin
  select is_checkpoint into is_cp from public.items where id = new.item_id;
  if not is_cp then
    raise exception 'Only checkpoint items are recorded in checkpoint_passes.' using errcode = 'PW012';
  end if;
  return new;
end;
$$;

create trigger trg_checkpoint_passes_is_checkpoint
before insert or update on public.checkpoint_passes
for each row execute function public.enforce_checkpoint_item();

-- ---------------------------------------------------------------------
-- feedback — monthly summary, student-readable
-- ---------------------------------------------------------------------
create table public.feedback (
  id          uuid primary key default gen_random_uuid(),
  student_id  uuid not null references public.students(id),
  coach_id    uuid not null references public.coaches(id),
  month       date not null,
  body        text not null check (length(btrim(body)) > 0),
  rating      smallint check (rating between 1 and 5),
  highlight   text,
  next_focus  text,
  created_at  timestamptz not null default now()
);

create index feedback_student_month on public.feedback (student_id, month desc);

-- ---------------------------------------------------------------------
-- coach_notes — coach-only, never student-readable
-- ---------------------------------------------------------------------
create table public.coach_notes (
  id         uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id),
  coach_id   uuid not null references public.coaches(id),
  body       text not null check (length(btrim(body)) > 0),
  created_at timestamptz not null default now()
);

create index coach_notes_student on public.coach_notes (student_id, created_at desc);

-- ---------------------------------------------------------------------
-- attendance — one row per student per calendar day they were present.
-- No row = absent; there is no explicit "absent" record. session_date is
-- always computed in Maldives time (UTC+5) by the client, never the
-- server's own timezone.
-- ---------------------------------------------------------------------
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

-- Belt-and-braces: school_id must always match the student's actual school,
-- so RLS (which trusts attendance.school_id) can't be fooled by a client
-- sending a mismatched school_id.
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
-- attendance_log — append-only audit trail. A row in `attendance` is
-- deleted the moment a student is un-marked, so this is the only place
-- a removal is still visible afterwards; rows here are never deleted.
-- ---------------------------------------------------------------------
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
