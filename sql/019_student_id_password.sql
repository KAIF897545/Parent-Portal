-- Parent Portal — admin sets the student ID directly; it's also the starting password
--
-- Student IDs were auto-generated (school prefix + sequence, e.g.
-- BW-0002) via next_student_code, purely internal and never chosen by
-- anyone. The admin now types the student ID directly at creation time,
-- and that same value becomes the account's starting password (the
-- student still has to set a real one on first sign-in --
-- must_change_password is unaffected by any of this). One value to hand
-- a family instead of two.
--
-- Since it's also the password, it has to clear the same 8-character
-- floor every password does, and password_in_use still runs against it
-- (a student ID can't collide with any other account's current password,
-- same as before). Kept scoped to (school_id, student_code) for the
-- uniqueness check, matching the existing table constraint -- two
-- different schools could still coincidentally pick the same code, which
-- would only ever surface as a rare password_in_use rejection.
--
-- next_student_code is no longer called by anything and is dropped along
-- with the old admin_create_student signature (password param replaced
-- by student_code; removing an existing parameter can't be done via plain
-- create or replace, so the old one has to go first — see the note on
-- this same gotcha in sql/018).

drop function if exists public.admin_create_student(uuid, text, uuid, uuid, text, text);
drop function if exists public.next_student_code(uuid);

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

  if length(clean_code) < 8 then
    raise exception 'Student ID must be at least 8 characters — it also becomes their starting password.' using errcode = 'PW030';
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
