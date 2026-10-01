-- Parent Portal — allow a 7-character student ID / starting password
--
-- Per request: the real student ID cards being bulk-added are 7
-- characters (format like A417558, standard Maldives ID card length),
-- one character short of the 8-character floor sql/019 set. Lowering
-- just this one floor to 7 -- this only affects the TEMPORARY starting
-- password (student_code), not the real password rule students are
-- forced onto at first login (must_change_password + first-login.js's
-- own 8-character rule, untouched here, still comes from PW001
-- elsewhere and is a separate, intentionally-unchanged policy).
--
-- Same signature as sql/019's version, so a plain create or replace is
-- enough -- no parameter list change, nothing to drop first.

create or replace function public.admin_create_student(
  p_school_id   uuid,
  p_full_name   text,
  p_group_id    uuid,
  p_module_id   uuid,
  p_student_code text,
  p_email       text
)
returns table (id uuid, student_code text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_code  text := upper(btrim(coalesce(p_student_code, '')));
  clean_email text := lower(btrim(coalesce(p_email, '')));
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

  if length(clean_code) < 7 then
    raise exception 'Student ID must be at least 7 characters — it also becomes their starting password.' using errcode = 'PW030';
  end if;

  -- returns table (id uuid, student_code text) makes "student_code" a
  -- PL/pgSQL variable in scope here too, so the column below must be
  -- qualified -- same reason id needed a table alias in the very first
  -- version of this function (see sql/008's comment on it).
  if exists (
    select 1 from public.students s where s.school_id = p_school_id and s.student_code = clean_code
  ) then
    raise exception 'That student ID is already in use at this school.' using errcode = 'PW031';
  end if;

  if clean_email = '' or clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if exists (select 1 from auth.users where email = clean_email) then
    raise exception 'That email is already used by another account.' using errcode = 'PW029';
  end if;

  if public.password_in_use(clean_code, null) then
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
    clean_email, crypt(clean_code, gen_salt('bf')),
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
    new_id, p_school_id, clean_code, btrim(p_full_name),
    p_group_id, p_module_id, true, true, clean_email
  );

  return query select new_id, clean_code;
end;
$$;

revoke all on function public.admin_create_student(uuid, text, uuid, uuid, text, text) from public;
grant execute on function public.admin_create_student(uuid, text, uuid, uuid, text, text) to service_role;
