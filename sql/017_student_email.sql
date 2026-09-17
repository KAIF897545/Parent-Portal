-- Parent Portal — students can reset their own password by email
--
-- Students have never had a real email on file -- admin_create_student
-- gives every student a synthetic <code>@students.maldiveschessclub.com
-- address purely so auth.users has something to store, since nobody
-- reads it or can receive mail there. resolve_login (the full-name sign
-- in path) just reads whatever is in auth.users.email for that id, so it
-- doesn't care whether that address is real or synthetic -- which means
-- swapping in a real, reachable email for students who have one is a
-- drop-in change: it doesn't touch how they normally sign in, but it lets
-- Supabase's existing password-recovery email (already wired up for
-- coaches via reset-password.html) work for them too.
--
-- auth.users.email has a project-wide unique constraint, so two students
-- can't share the exact same address (e.g. siblings on one parent email).
-- admin_set_student_email surfaces that as a friendly error suggesting a
-- "+" alias (name+child2@gmail.com), which still delivers to the same
-- inbox -- there's no clean way around the constraint itself without a
-- separate, non-Supabase email-sending setup, which is out of scope here.

alter table public.students add column if not exists email text;

-- admin_create_student gains an optional trailing p_email -- Postgres
-- allows this via create or replace as long as it's new, at the end, and
-- has a default, so the existing 5-arg call sites keep working unchanged.
create or replace function public.admin_create_student(
  p_school_id uuid,
  p_full_name text,
  p_group_id  uuid,
  p_module_id uuid,
  p_password  text,
  p_email     text default null
)
returns table (id uuid, student_code text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  clean_pw    text := btrim(p_password);
  clean_email text := nullif(lower(btrim(coalesce(p_email, ''))), '');
  code        text;
  new_id      uuid := gen_random_uuid();
  login_email text;
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

  if clean_email is not null and clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if clean_email is not null and exists (select 1 from auth.users where email = clean_email) then
    raise exception 'That email is already used by another account.' using errcode = 'PW029';
  end if;

  code := public.next_student_code(p_school_id);
  login_email := coalesce(clean_email, lower(code) || '@students.maldiveschessclub.com');

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_super_admin, is_sso_user
  ) values (
    '00000000-0000-0000-0000-000000000000', new_id, 'authenticated', 'authenticated',
    login_email, crypt(clean_pw, gen_salt('bf')),
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
    jsonb_build_object('sub', new_id::text, 'email', login_email),
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

-- admin_set_student_email(student, email) — service role only.
-- Sets or clears the real email used for both display and sign-in
-- recovery. Clearing it reverts auth.users.email to a fresh synthetic
-- address rather than leaving the old real one in place, so a cleared
-- email can no longer be used to request a reset link for that account.
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
  clean_email  text := nullif(lower(btrim(coalesce(p_email, ''))), '');
  target_code  text;
  login_email  text;
begin
  select student_code into target_code from public.students where id = p_student;
  if target_code is null then
    raise exception 'Unknown student.' using errcode = 'PW007';
  end if;

  if clean_email is not null and clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Enter a valid email address.' using errcode = 'PW018';
  end if;

  if clean_email is not null and exists (
    select 1 from auth.users where email = clean_email and id <> p_student
  ) then
    raise exception 'That email is already used by another account.' using errcode = 'PW029';
  end if;

  login_email := coalesce(clean_email, lower(target_code) || '@students.maldiveschessclub.com');

  update auth.users set email = login_email where id = p_student;

  update auth.identities
     set identity_data = jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', to_jsonb(login_email))
   where user_id = p_student;

  update public.students set email = clean_email where id = p_student;
end;
$$;

revoke all on function public.admin_set_student_email(uuid, text) from public;
grant execute on function public.admin_set_student_email(uuid, text) to service_role;
