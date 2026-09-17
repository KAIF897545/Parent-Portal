-- Parent Portal — remove the "category" concept from students
--
-- Category (Beginner/Intermediate/Advanced) is replaced entirely by
-- groups, which already existed and cover the same "which class is this
-- student in" need without a second, overlapping field to keep in sync.

-- admin_create_student's signature is changing (category param dropped),
-- so the old 6-arg overload must be dropped explicitly before the new
-- 5-arg version is created — create or replace can't change a function's
-- parameter list.
drop function if exists public.admin_create_student(uuid, text, text, uuid, uuid, text);

create or replace function public.admin_create_student(
  p_school_id uuid,
  p_full_name text,
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
    id, school_id, student_code, full_name, group_id, current_module_id,
    must_change_password, active
  ) values (
    new_id, p_school_id, code, btrim(p_full_name),
    p_group_id, p_module_id, true, true
  );

  return query select new_id, code;
end;
$$;

revoke all on function public.admin_create_student(uuid, text, uuid, uuid, text) from public;
grant execute on function public.admin_create_student(uuid, text, uuid, uuid, text) to service_role;

-- my_identity() showed "Category" on the first-login confirmation screen;
-- now shows the student's group instead (nullable — not every student has
-- one, hence the left join). Its return columns are changing shape, so
-- (like admin_create_student above) it has to be dropped before it can
-- be recreated — create or replace can't do that on its own.
drop function if exists public.my_identity();

create or replace function public.my_identity()
returns table (full_name text, student_code text, group_name text, school_name text)
language sql
security definer
stable
set search_path = public, pg_temp
as $$
  select s.full_name, s.student_code, g.name, sc.name
  from public.students s
  join public.schools sc on sc.id = s.school_id
  left join public.school_groups g on g.id = s.group_id
  where s.id = auth.uid();
$$;

alter table public.students drop column category;
