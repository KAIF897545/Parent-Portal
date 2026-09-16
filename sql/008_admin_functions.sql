-- Parent Portal — admin account-creation functions (Step D)
--
-- Adds admin_create_student, admin_create_coach and admin_create_school.
-- Pure additions (create or replace, fresh grants) — no existing objects
-- change shape, so this is safe to run once against the live database.
-- After this, sql/002_functions.sql also carries these for fresh installs.

-- ---------------------------------------------------------------------
-- admin_create_student(...) — service role only.
-- ---------------------------------------------------------------------
create or replace function public.admin_create_student(
  p_school_id uuid,
  p_full_name text,
  p_category  text,
  p_group_id  uuid,
  p_module_id uuid,
  p_password  text
)
returns table (id uuid, student_code text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_pw text := btrim(p_password);
  code     text;
  new_id   uuid := gen_random_uuid();
  email    text;
begin
  -- returns table (id uuid, ...) makes "id" a PL/pgSQL variable in scope
  -- for the rest of this function, so every lookup below must qualify
  -- the column with a table alias — a bare "id" is ambiguous here.
  if p_school_id is null or not exists (select 1 from public.schools s where s.id = p_school_id) then
    raise exception 'Unknown school.' using errcode = 'PW009';
  end if;

  if p_full_name is null or length(btrim(p_full_name)) = 0 then
    raise exception 'Full name is required.' using errcode = 'PW015';
  end if;

  if p_module_id is null or not exists (select 1 from public.modules m where m.id = p_module_id) then
    raise exception 'Unknown module.' using errcode = 'PW016';
  end if;

  if p_group_id is not null and not exists (
    select 1 from public.school_groups g where g.id = p_group_id and g.school_id = p_school_id
  ) then
    raise exception 'Unknown group for that school.' using errcode = 'PW017';
  end if;

  if length(clean_pw) < 8 then
    raise exception 'Password must be at least 8 characters.' using errcode = 'PW001';
  end if;

  if public.password_in_use(clean_pw, null) then
    raise exception 'Password rejected.' using errcode = 'PW004';
  end if;

  code  := public.next_student_code(p_school_id);
  email := lower(code) || '@students.maldiveschessclub.com';

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_super_admin, is_sso_user
  ) values (
    '00000000-0000-0000-0000-000000000000', new_id, 'authenticated', 'authenticated',
    email, crypt(clean_pw, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    '', '', '', '',
    false, false
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), new_id, new_id::text,
    jsonb_build_object('sub', new_id::text, 'email', email),
    'email', now(), now(), now()
  );

  insert into public.students (
    id, school_id, student_code, full_name, category, group_id, current_module_id,
    must_change_password, active
  ) values (
    new_id, p_school_id, code, btrim(p_full_name),
    coalesce(nullif(btrim(p_category), ''), 'Beginner'),
    p_group_id, p_module_id, true, true
  );

  return query select new_id, code;
end;
$$;

revoke all on function public.admin_create_student(uuid, text, text, uuid, uuid, text) from public;
grant execute on function public.admin_create_student(uuid, text, text, uuid, uuid, text) to service_role;

-- ---------------------------------------------------------------------
-- admin_create_coach(...) — service role only.
-- ---------------------------------------------------------------------
create or replace function public.admin_create_coach(
  p_email     text,
  p_name      text,
  p_role      text,
  p_school_id uuid,
  p_password  text
)
returns table (id uuid)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_pw    text := btrim(p_password);
  clean_email text := lower(btrim(p_email));
  new_id      uuid := gen_random_uuid();
begin
  if clean_email = '' or clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if exists (select 1 from auth.users where email = clean_email) then
    raise exception 'That email is already in use.' using errcode = 'PW019';
  end if;

  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'Name is required.' using errcode = 'PW015';
  end if;

  if p_role not in ('coach', 'admin') then
    raise exception 'Role must be coach or admin.' using errcode = 'PW020';
  end if;

  if p_role = 'coach' and p_school_id is null then
    raise exception 'Choose a school for this coach.' using errcode = 'PW021';
  end if;

  if p_role = 'admin' and p_school_id is not null then
    raise exception 'Admins don''t belong to a school.' using errcode = 'PW022';
  end if;

  -- returns table (id uuid) makes "id" a PL/pgSQL variable in scope for
  -- the rest of this function, so this lookup must qualify the column.
  if p_school_id is not null and not exists (select 1 from public.schools s where s.id = p_school_id) then
    raise exception 'Unknown school.' using errcode = 'PW009';
  end if;

  if length(clean_pw) < 8 then
    raise exception 'Password must be at least 8 characters.' using errcode = 'PW001';
  end if;

  if public.password_in_use(clean_pw, null) then
    raise exception 'Password rejected.' using errcode = 'PW004';
  end if;

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_super_admin, is_sso_user
  ) values (
    '00000000-0000-0000-0000-000000000000', new_id, 'authenticated', 'authenticated',
    clean_email, crypt(clean_pw, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    '', '', '', '',
    false, false
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), new_id, new_id::text,
    jsonb_build_object('sub', new_id::text, 'email', clean_email),
    'email', now(), now(), now()
  );

  insert into public.coaches (id, school_id, name, role, active)
  values (new_id, p_school_id, btrim(p_name), p_role, true);

  return query select new_id;
end;
$$;

revoke all on function public.admin_create_coach(text, text, text, uuid, text) from public;
grant execute on function public.admin_create_coach(text, text, text, uuid, text) to service_role;

-- ---------------------------------------------------------------------
-- admin_create_school(...) — service role only.
-- ---------------------------------------------------------------------
create or replace function public.admin_create_school(
  p_name     text,
  p_location text,
  p_prefix   text,
  p_groups   text[]
)
returns table (id uuid)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  clean_prefix text := upper(btrim(p_prefix));
  new_id       uuid;
  g            text;
begin
  if p_name is null or length(btrim(p_name)) = 0 then
    raise exception 'School name is required.' using errcode = 'PW023';
  end if;

  if clean_prefix !~ '^[A-Z]{2,6}$' then
    raise exception 'Prefix must be 2 to 6 letters.' using errcode = 'PW024';
  end if;

  if exists (select 1 from public.schools where prefix = clean_prefix) then
    raise exception 'That prefix is already in use.' using errcode = 'PW025';
  end if;

  insert into public.schools (name, location, prefix)
  values (btrim(p_name), nullif(btrim(coalesce(p_location, '')), ''), clean_prefix)
  returning schools.id into new_id;

  if p_groups is not null then
    foreach g in array p_groups loop
      if length(btrim(g)) > 0 then
        insert into public.school_groups (school_id, name) values (new_id, btrim(g));
      end if;
    end loop;
  end if;

  return query select new_id;
end;
$$;

revoke all on function public.admin_create_school(text, text, text, text[]) from public;
grant execute on function public.admin_create_school(text, text, text, text[]) to service_role;
