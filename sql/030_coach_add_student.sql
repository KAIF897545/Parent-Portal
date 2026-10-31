-- Parent Portal — coaches can add a student with just a name
--
-- Until now only an admin could create a student, and it needed an email
-- (the sign-in) and a student ID (the starting password). A coach adding a
-- new child to their class often has neither, and doesn't need the child to
-- sign in at all -- they only want the child on the roster so attendance,
-- progress ticks and feedback can be recorded straight away.
--
-- coach_add_student creates that roster-only student: a name, plus an
-- optional group and the starting module. students.id is a foreign key to
-- auth.users, so the row still needs an auth account behind it. It gets the
-- same kind of placeholder the pre-017 students had: an address on the
-- reserved .invalid domain (it can never receive mail) and a random
-- password that nobody is ever told. students.email stays null, which is
-- exactly what the admin page already flags as "no email -- can't sign in
-- yet". Giving them a real sign-in later is the existing admin flow: set an
-- email, then reset the password.
--
-- The student ID is generated here (school prefix + running number, e.g.
-- BW-0007) instead of being typed, because it is no longer a password.
--
-- Callable by the signed-in coach themselves (not only through the server):
-- it checks inside that the caller is an active admin, or an active coach
-- of the very school being added to.

create or replace function public.coach_add_student(
  p_school_id uuid,
  p_full_name text,
  p_group_id  uuid,
  p_module_id uuid
)
returns table (id uuid, student_code text)
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $$
declare
  v_prefix  text;
  v_next    int;
  v_code    text;
  new_id    uuid := gen_random_uuid();
  v_email   text;
begin
  if not (
    public.is_admin()
    or (public.is_coach() and public.my_coach_school() = p_school_id)
  ) then
    raise exception 'Not allowed.' using errcode = 'PW032';
  end if;

  select s.prefix into v_prefix from public.schools s where s.id = p_school_id;
  if v_prefix is null then
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

  -- One coach at a time per school, so two people adding at once can't be
  -- handed the same number. (unique (school_id, student_code) is the
  -- backstop either way.)
  perform pg_advisory_xact_lock(hashtext('coach_add_student:' || p_school_id::text));

  -- Only codes of the form PREFIX-1234 count; IDs typed in by an admin
  -- (A417558 and the like) are ignored.
  select coalesce(max(substring(s.student_code from '^' || v_prefix || '-(\d{1,8})$')::int), 0) + 1
    into v_next
    from public.students s
   where s.school_id = p_school_id
     and s.student_code ~ ('^' || v_prefix || '-\d{1,8}$');

  v_code  := v_prefix || '-' || lpad(v_next::text, 4, '0');
  v_email := new_id::text || '@no-login.invalid';

  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_super_admin, is_sso_user
  ) values (
    '00000000-0000-0000-0000-000000000000', new_id, 'authenticated', 'authenticated',
    v_email, crypt(gen_random_uuid()::text || gen_random_uuid()::text, gen_salt('bf')),
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
    jsonb_build_object('sub', new_id::text, 'email', v_email),
    'email', now(), now(), now()
  );

  insert into public.students (
    id, school_id, student_code, full_name, group_id, current_module_id,
    must_change_password, active, email
  ) values (
    new_id, p_school_id, v_code, btrim(p_full_name),
    p_group_id, p_module_id, true, true, null
  );

  return query select new_id, v_code;
end;
$$;

revoke all on function public.coach_add_student(uuid, text, uuid, uuid) from public;
grant execute on function public.coach_add_student(uuid, text, uuid, uuid) to authenticated;
