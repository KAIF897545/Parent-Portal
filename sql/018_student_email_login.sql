-- Parent Portal — students sign in with email instead of full name
--
-- resolve_login (the full-name -> email lookup, with its "two students
-- share this name" disambiguation) is no longer needed: students now sign
-- in the same way coaches always have, straight to
-- supabase.auth.signInWithPassword({email, password}) from the browser.
-- Dropped along with its only caller, api/resolve-login.js.
--
-- This makes a real email mandatory going forward, not optional --
-- there's no more synthetic <code>@students.maldiveschessclub.com
-- fallback to sign in with if one isn't set. admin_create_student now
-- requires p_email (same shape as admin_create_coach already did), and
-- admin_set_student_email no longer accepts clearing it to blank, since
-- that would leave the account with no way to sign in at all --
-- Deactivate already exists as the purpose-built way to disable a
-- student's access without touching their email.
--
-- Any student created before this migration with no email on file
-- (students.email is null) keeps whatever synthetic address it already
-- has and simply can't sign in until an admin edits in a real one.

drop function if exists public.resolve_login(uuid, text, text, text);

-- p_email is going from "default null" to required -- Postgres allows
-- create or replace to change a default value in general, but not to
-- *remove* one from an existing function, so the old signature has to
-- go first (same class of gotcha as the admin_create_student overload
-- fixed in the previous migration, just a different variant of it).
drop function if exists public.admin_create_student(uuid, text, uuid, uuid, text, text);

create or replace function public.admin_create_student(
  p_school_id uuid,
  p_full_name text,
  p_group_id  uuid,
  p_module_id uuid,
  p_password  text,
  p_email     text
)
returns table (id uuid, student_code text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_pw    text := btrim(p_password);
  clean_email text := lower(btrim(coalesce(p_email, '')));
  code        text;
  new_id      uuid := gen_random_uuid();
begin
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

  if clean_email = '' or clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if exists (select 1 from auth.users where email = clean_email) then
    raise exception 'That email is already used by another account.' using errcode = 'PW029';
  end if;

  code := public.next_student_code(p_school_id);

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

  insert into public.students (
    id, school_id, student_code, full_name, group_id, current_module_id,
    must_change_password, active, email
  ) values (
    new_id, p_school_id, code, btrim(p_full_name),
    p_group_id, p_module_id, true, true, clean_email
  );

  return query select new_id, code;
end;
$$;

revoke all on function public.admin_create_student(uuid, text, uuid, uuid, text, text) from public;
grant execute on function public.admin_create_student(uuid, text, uuid, uuid, text, text) to service_role;

create or replace function public.admin_set_student_email(
  p_student uuid,
  p_email   text
)
returns void
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_email text := lower(btrim(coalesce(p_email, '')));
begin
  if not exists (select 1 from public.students where id = p_student) then
    raise exception 'Unknown student.' using errcode = 'PW007';
  end if;

  if clean_email = '' or clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if exists (select 1 from auth.users where email = clean_email and id <> p_student) then
    raise exception 'That email is already used by another account.' using errcode = 'PW029';
  end if;

  update auth.users set email = clean_email where id = p_student;

  update auth.identities
     set identity_data = jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(clean_email))
   where user_id = p_student;

  update public.students set email = clean_email where id = p_student;
end;
$$;

revoke all on function public.admin_set_student_email(uuid, text) from public;
grant execute on function public.admin_set_student_email(uuid, text) to service_role;
