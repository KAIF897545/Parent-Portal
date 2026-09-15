-- Parent Portal — test data seed
-- Fixes the school naming mismatch, adds the Brightway and Finland partner
-- schools, and creates sample students and coach accounts for testing.
--
-- Auth users are created by inserting directly into auth.users/auth.identities
-- via a helper function, mirroring the well-known Supabase seeding pattern.
-- This avoids ever routing a password through a browser form for test data.

-- ---------------------------------------------------------------------
-- Helper: create an auth user (email + password) and return its id.
-- ---------------------------------------------------------------------
create or replace function public._seed_auth_user(p_email text, p_password text)
returns uuid
language plpgsql
as $$
declare
  uid uuid := gen_random_uuid();
begin
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at, created_at, updated_at,
    raw_app_meta_data, raw_user_meta_data,
    confirmation_token, recovery_token, email_change_token_new, email_change,
    is_super_admin, is_sso_user
  ) values (
    '00000000-0000-0000-0000-000000000000', uid, 'authenticated', 'authenticated',
    p_email, crypt(p_password, gen_salt('bf')),
    now(), now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    '', '', '', '',
    false, false
  );

  insert into auth.identities (
    id, user_id, provider_id, identity_data, provider,
    last_sign_in_at, created_at, updated_at
  ) values (
    gen_random_uuid(), uid, uid::text,
    jsonb_build_object('sub', uid::text, 'email', p_email),
    'email', now(), now(), now()
  );

  return uid;
end;
$$;

-- ---------------------------------------------------------------------
-- Fix the school created in Step A: it was renamed away from its
-- original MCC identity. Restore it, then add the two partner schools.
-- ---------------------------------------------------------------------
update public.schools
   set name = 'Maldives Chess Club', location = 'Male'
 where prefix = 'MCC';

insert into public.schools (name, location, prefix) values
  ('Brightway School', 'Male', 'BW'),
  ('Finland School', 'Hulhumale', 'FIN');

insert into public.school_groups (school_id, name)
select id, g.name from public.schools, (values
  ('Saturday Beginners'), ('Sunday Intermediate'), ('Wednesday Advanced')
) as g(name)
where schools.prefix = 'MCC';

insert into public.school_groups (school_id, name)
select id, g.name from public.schools, (values
  ('Grade 4-5 Club'), ('Grade 6-7 Club')
) as g(name)
where schools.prefix = 'BW';

insert into public.school_groups (school_id, name)
select id, g.name from public.schools, (values
  ('After-school Chess')
) as g(name)
where schools.prefix = 'FIN';

-- ---------------------------------------------------------------------
-- Sample students
-- ---------------------------------------------------------------------
do $$
declare
  mcc_id uuid; bw_id uuid; fin_id uuid;
  uid uuid;
begin
  select id into mcc_id from public.schools where prefix = 'MCC';
  select id into bw_id  from public.schools where prefix = 'BW';
  select id into fin_id from public.schools where prefix = 'FIN';

  -- Aishath Ibrahim, MCC-0142, Sunday Intermediate, Intermediate, Module 3
  uid := public._seed_auth_user('mcc-0142@students.maldiveschessclub.com', 'chess2026');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, mcc_id, 'MCC-0142', 'Aishath Ibrahim', 'Intermediate',
    (select id from public.school_groups where school_id = mcc_id and name = 'Sunday Intermediate'),
    (select id from public.modules where number = 3), false, true);

  -- Hassan Naseer, MCC-0118, Wednesday Advanced, Advanced, Module 3
  uid := public._seed_auth_user('mcc-0118@students.maldiveschessclub.com', 'knight77');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, mcc_id, 'MCC-0118', 'Hassan Naseer', 'Advanced',
    (select id from public.school_groups where school_id = mcc_id and name = 'Wednesday Advanced'),
    (select id from public.modules where number = 3), false, true);

  -- Mariyam Shifa, MCC-0151, Sunday Intermediate, Intermediate, Module 2
  uid := public._seed_auth_user('mcc-0151@students.maldiveschessclub.com', 'rook4444');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, mcc_id, 'MCC-0151', 'Mariyam Shifa', 'Intermediate',
    (select id from public.school_groups where school_id = mcc_id and name = 'Sunday Intermediate'),
    (select id from public.modules where number = 2), false, true);

  -- Ahmed Rasheed, MCC-0163, Saturday Beginners, Beginner, Module 1 (must change password)
  uid := public._seed_auth_user('mcc-0163@students.maldiveschessclub.com', 'pawn1234');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, mcc_id, 'MCC-0163', 'Ahmed Rasheed', 'Beginner',
    (select id from public.school_groups where school_id = mcc_id and name = 'Saturday Beginners'),
    (select id from public.modules where number = 1), true, true);

  -- Ahmed Rasheed, MCC-0171, Saturday Beginners, Beginner, Module 1 (namesake, tests ambiguous login)
  uid := public._seed_auth_user('mcc-0171@students.maldiveschessclub.com', 'bishop99');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, mcc_id, 'MCC-0171', 'Ahmed Rasheed', 'Beginner',
    (select id from public.school_groups where school_id = mcc_id and name = 'Saturday Beginners'),
    (select id from public.modules where number = 1), true, true);

  -- Ahmed Rasheed, BW-0003, Grade 6-7 Club, Beginner, Module 1 (different school, not ambiguous there)
  uid := public._seed_auth_user('bw-0003@students.maldiveschessclub.com', 'castle2026');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, bw_id, 'BW-0003', 'Ahmed Rasheed', 'Beginner',
    (select id from public.school_groups where school_id = bw_id and name = 'Grade 6-7 Club'),
    (select id from public.modules where number = 1), false, true);

  -- Layaal Mohamed, BW-0004, Grade 4-5 Club, Beginner, Module 1
  uid := public._seed_auth_user('bw-0004@students.maldiveschessclub.com', 'atoll4821');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, bw_id, 'BW-0004', 'Layaal Mohamed', 'Beginner',
    (select id from public.school_groups where school_id = bw_id and name = 'Grade 4-5 Club'),
    (select id from public.modules where number = 1), true, true);

  -- Yoosuf Adam, FIN-0001, After-school Chess, Beginner, Module 1
  uid := public._seed_auth_user('fin-0001@students.maldiveschessclub.com', 'lagoon7714');
  insert into public.students (id, school_id, student_code, full_name, category, group_id, current_module_id, must_change_password, active)
  values (uid, fin_id, 'FIN-0001', 'Yoosuf Adam', 'Beginner',
    (select id from public.school_groups where school_id = fin_id and name = 'After-school Chess'),
    (select id from public.modules where number = 1), true, true);
end $$;

-- ---------------------------------------------------------------------
-- Coach accounts
-- ---------------------------------------------------------------------
do $$
declare
  mcc_id uuid; bw_id uuid;
  uid uuid;
begin
  select id into mcc_id from public.schools where prefix = 'MCC';
  select id into bw_id  from public.schools where prefix = 'BW';

  -- Kaif — test coach at MCC, password as requested for testing
  uid := public._seed_auth_user('kaif@maldiveschessclub.com', 'welcome@123');
  insert into public.coaches (id, school_id, name, role, active)
  values (uid, mcc_id, 'Kaif', 'coach', true);

  -- Hassan Naseer — coach at MCC
  uid := public._seed_auth_user('hassan@maldiveschessclub.com', 'endgame2026');
  insert into public.coaches (id, school_id, name, role, active)
  values (uid, mcc_id, 'Hassan Naseer', 'coach', true);

  -- Shifa Adam — coach at Brightway (for cross-school isolation testing)
  uid := public._seed_auth_user('shifa@brightway.edu.mv', 'opening4417');
  insert into public.coaches (id, school_id, name, role, active)
  values (uid, bw_id, 'Shifa Adam', 'coach', true);
end $$;

drop function public._seed_auth_user(text, text);
