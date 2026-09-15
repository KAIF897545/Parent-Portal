-- Parent Portal — functions
-- Run after 001_schema.sql.
--
-- Two families:
--  * RLS helpers (is_admin, is_coach, my_coach_school, can_see_student, can_manage_student)
--    — granted to `authenticated`, run as the signed-in user via auth.uid().
--  * Sensitive RPCs (resolve_login, password_in_use, admin_set_*_password, next_student_code)
--    — granted to `service_role` only. They are called exclusively from /api functions
--    that hold the service role key; the actual "is this caller an admin" check happens
--    in requireAdmin() at the API layer, not in these functions.

-- ---------------------------------------------------------------------
-- RLS helpers
-- ---------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.coaches c
    where c.id = auth.uid() and c.role = 'admin' and c.active
  );
$$;

create or replace function public.is_coach()
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.coaches c
    where c.id = auth.uid() and c.role = 'coach' and c.active
  );
$$;

create or replace function public.my_coach_school()
returns uuid
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select school_id from public.coaches where id = auth.uid() and active;
$$;

create or replace function public.my_student_school()
returns uuid
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select school_id from public.students where id = auth.uid() and active;
$$;

create or replace function public.is_active_student()
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select exists (
    select 1 from public.students s where s.id = auth.uid() and s.active
  );
$$;

-- true for admins, and for coaches whose school matches the student's school
create or replace function public.can_manage_student(p_student uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    public.is_admin()
    or (
      public.is_coach()
      and exists (
        select 1 from public.students s
        where s.id = p_student and s.school_id = public.my_coach_school()
      )
    );
$$;

-- can_manage_student(), plus the student's own row
create or replace function public.can_see_student(p_student uuid)
returns boolean
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select
    public.can_manage_student(p_student)
    or (auth.uid() = p_student and public.is_active_student());
$$;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_coach() to authenticated;
grant execute on function public.my_coach_school() to authenticated;
grant execute on function public.my_student_school() to authenticated;
grant execute on function public.is_active_student() to authenticated;
grant execute on function public.can_manage_student(uuid) to authenticated;
grant execute on function public.can_see_student(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- my_identity() — first-login confirmation screen
-- ---------------------------------------------------------------------
create or replace function public.my_identity()
returns table (full_name text, student_code text, category text, school_name text)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select s.full_name, s.student_code, s.category, sc.name
  from public.students s
  join public.schools sc on sc.id = s.school_id
  where s.id = auth.uid();
$$;

revoke all on function public.my_identity() from public;
grant execute on function public.my_identity() to authenticated;

-- ---------------------------------------------------------------------
-- school_student_counts() — for portals.html, readable before login
-- ---------------------------------------------------------------------
create or replace function public.school_student_counts()
returns table (school_id uuid, student_count bigint)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select school_id, count(*) from public.students where active group by school_id;
$$;

grant execute on function public.school_student_counts() to anon, authenticated;

-- ---------------------------------------------------------------------
-- password_in_use(password, exclude_id) — service role only
-- One bcrypt comparison per account, via crypt(candidate, stored_hash).
-- ---------------------------------------------------------------------
create or replace function public.password_in_use(password text, exclude_id uuid default null)
returns boolean
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean text := btrim(password);
  hit   boolean;
begin
  select exists (
    select 1 from auth.users u
    where u.id is distinct from exclude_id
      and u.encrypted_password is not null
      and u.encrypted_password = crypt(clean, u.encrypted_password)
  ) into hit;
  return hit;
end;
$$;

revoke all on function public.password_in_use(text, uuid) from public;
grant execute on function public.password_in_use(text, uuid) to service_role;

-- ---------------------------------------------------------------------
-- set_my_password(password) — students only, called with their own session.
-- Distinct errcodes so the client can word each rejection; PW004 (password
-- already in use elsewhere) always renders as exactly "Password rejected."
-- ---------------------------------------------------------------------
create or replace function public.set_my_password(password text)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  uid   uuid := auth.uid();
  stu   record;
  clean text := btrim(password);
begin
  select * into stu from public.students where id = uid;
  if stu.id is null then
    raise exception 'Only students change their password here.' using errcode = 'PW005';
  end if;

  if length(clean) < 8 then
    raise exception 'Password must be at least 8 characters.' using errcode = 'PW001';
  end if;

  if lower(clean) = lower(btrim(stu.full_name)) then
    raise exception 'Password cannot be your name.' using errcode = 'PW002';
  end if;

  if lower(clean) = lower(btrim(stu.student_code)) then
    raise exception 'Password cannot be your student ID.' using errcode = 'PW003';
  end if;

  if public.password_in_use(clean, uid) then
    raise exception 'Password rejected.' using errcode = 'PW004';
  end if;

  update auth.users set encrypted_password = crypt(clean, gen_salt('bf')) where id = uid;
  update public.students set must_change_password = false where id = uid;
end;
$$;

revoke all on function public.set_my_password(text) from public;
grant execute on function public.set_my_password(text) to authenticated;

-- ---------------------------------------------------------------------
-- resolve_login(school, name, password, student_code) — service role only.
-- Collapses "no such name" and "wrong password" into the same 'not_found'
-- status so failures stay vague. Returns 'ambiguous' when more than one
-- active student at the school shares the normalised name.
-- ---------------------------------------------------------------------
create or replace function public.resolve_login(
  p_school       uuid,
  p_name         text,
  p_password     text,
  p_student_code text default null
)
returns table (status text, email text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_name text := lower(regexp_replace(btrim(p_name), '\s+', ' ', 'g'));
  clean_pw   text := btrim(p_password);
  clean_code text := nullif(upper(btrim(coalesce(p_student_code, ''))), '');
  matches    uuid[];
  target     uuid;
  target_email text;
  ok boolean;
begin
  if clean_code is not null then
    select array_agg(id) into matches
    from public.students
    where school_id = p_school and active and login_name = clean_name and student_code = clean_code;
  else
    select array_agg(id) into matches
    from public.students
    where school_id = p_school and active and login_name = clean_name;
  end if;

  if matches is null or array_length(matches, 1) = 0 then
    return query select 'not_found'::text, null::text;
    return;
  end if;

  if array_length(matches, 1) > 1 then
    return query select 'ambiguous'::text, null::text;
    return;
  end if;

  target := matches[1];

  select (u.encrypted_password is not null and u.encrypted_password = crypt(clean_pw, u.encrypted_password)), u.email
    into ok, target_email
    from auth.users u
   where u.id = target;

  if not coalesce(ok, false) then
    return query select 'not_found'::text, null::text;
    return;
  end if;

  return query select 'ok'::text, target_email;
end;
$$;

revoke all on function public.resolve_login(uuid, text, text, text) from public;
grant execute on function public.resolve_login(uuid, text, text, text) to service_role;

-- ---------------------------------------------------------------------
-- admin_set_student_password(student, password) — service role only.
-- Used both at creation and at reset; always leaves must_change_password
-- true so the student is forced through first-login again.
-- ---------------------------------------------------------------------
create or replace function public.admin_set_student_password(p_student uuid, p_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean text := btrim(p_password);
begin
  if not exists (select 1 from public.students where id = p_student) then
    raise exception 'Unknown student.' using errcode = 'PW007';
  end if;

  if length(clean) < 8 then
    raise exception 'Password must be at least 8 characters.' using errcode = 'PW001';
  end if;

  if public.password_in_use(clean, p_student) then
    raise exception 'Password rejected.' using errcode = 'PW004';
  end if;

  update auth.users set encrypted_password = crypt(clean, gen_salt('bf')) where id = p_student;
  update public.students set must_change_password = true where id = p_student;
end;
$$;

revoke all on function public.admin_set_student_password(uuid, text) from public;
grant execute on function public.admin_set_student_password(uuid, text) to service_role;

-- ---------------------------------------------------------------------
-- admin_set_coach_password(coach, password) — service role only.
-- Coaches never change this themselves; only the admin calls it.
-- ---------------------------------------------------------------------
create or replace function public.admin_set_coach_password(p_coach uuid, p_password text)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean text := btrim(p_password);
begin
  if not exists (select 1 from public.coaches where id = p_coach) then
    raise exception 'Unknown coach.' using errcode = 'PW008';
  end if;

  if length(clean) < 8 then
    raise exception 'Password must be at least 8 characters.' using errcode = 'PW001';
  end if;

  if public.password_in_use(clean, p_coach) then
    raise exception 'Password rejected.' using errcode = 'PW004';
  end if;

  update auth.users set encrypted_password = crypt(clean, gen_salt('bf')) where id = p_coach;
end;
$$;

revoke all on function public.admin_set_coach_password(uuid, text) from public;
grant execute on function public.admin_set_coach_password(uuid, text) to service_role;

-- ---------------------------------------------------------------------
-- next_student_code(school) — service role only.
-- ---------------------------------------------------------------------
create or replace function public.next_student_code(p_school uuid)
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  pfx text;
  n   int;
begin
  select prefix into pfx from public.schools where id = p_school;
  if pfx is null then
    raise exception 'Unknown school.' using errcode = 'PW009';
  end if;

  select coalesce(max(substring(student_code from '[0-9]+$')::int), 0) + 1
    into n
    from public.students
   where school_id = p_school;

  return pfx || '-' || lpad(n::text, 4, '0');
end;
$$;

revoke all on function public.next_student_code(uuid) from public;
grant execute on function public.next_student_code(uuid) to service_role;
