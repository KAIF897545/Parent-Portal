# Setup

Everything below is a one-time setup. Do it in order.

## 1. Create the Supabase project

Create a project at supabase.com. Note its **Project URL** — you'll need it
in step 3 and step 5.

## 2. Run the SQL

In the Supabase dashboard, open **SQL Editor** and run these files, in this
exact order (each depends on the one before it):

1. `sql/001_schema.sql` — tables, and the pgcrypto extension they need
2. `sql/002_functions.sql` — RLS helpers and the RPC functions
3. `sql/003_policies.sql` — row level security policies
4. `sql/004_seed_module1.sql` — Module 1 curriculum (Modules 2-6 arrive later,
   the same way, once you send that content)

Paste each file's contents into a new SQL Editor query and run it before
moving to the next file.

**A deliberate departure from the normal Supabase pattern:** `set_my_password`,
`admin_set_student_password` and `admin_set_coach_password` write directly to
`auth.users.encrypted_password` using `crypt(password, gen_salt('bf'))`,
instead of going through the Auth admin API. This is necessary because the
project's password rules — no two accounts may share a password, a student's
password can't be their name or ID — can't be expressed through
`signUp`/`updateUser`. `gen_salt('bf')` produces bcrypt hashes ($2a$) that
GoTrue's own bcrypt verification reads correctly, so sign-in works normally
afterward. This is a known, common workaround, not an oversight.

## 3. Turn off email confirmation and public sign-up

Students' email addresses are synthetic and never receive mail, and every
account is created by the admin — nobody should be able to self-register.

In **Authentication → Providers → Email**:
- Turn **off** "Confirm email"

In **Authentication → Settings** (or the sign-up toggle wherever your
Supabase version places it):
- Turn **off** "Allow new users to sign up"

## 4. Collect your keys

**Project Settings → API**. You need three values:

- **Project URL**
- **anon public key** — safe to expose in the browser
- **service_role key** — secret; never put this in a file the browser loads

## 5. Fill in `js/config.js`

Open [js/config.js](js/config.js) and replace the two placeholder values with
your real Project URL and anon key. Commit this file — those two values are
meant to be public. There's no build step, so this file is read by the
browser exactly as committed.

## 6. Set Vercel environment variables

In the Vercel project settings, add:

| Name | Value |
|---|---|
| `SUPABASE_URL` | your Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | your service_role key |

These are read only by the functions in `/api` (Node, server-side). They are
never sent to the browser.

Connect the GitHub repo to Vercel as an "Other" framework preset — there's no
build command and no output directory to configure; static files and `/api`
are served as-is.

## 7. Create the first school by hand

In the SQL Editor:

```sql
insert into public.schools (name, location, prefix)
values ('Maldives Chess Club', 'Malé', 'MCC');
```

Adjust the location if you'd like. `MCC` is the prefix used in the example
student codes throughout the brief (`MCC-0142`); pick your own if you'd
rather.

## 8. Create the first admin by hand

Admins sign in with a real email address on the Coaches tab of `login.html`
— there is no resolve-login step for them. Creating the first one:

1. **Authentication → Users → Add user.** Enter the admin's real email and a
   password. Toggle **Auto Confirm User** on.
2. Copy the new user's UUID from that screen.
3. In the SQL Editor, insert their coach row (`school_id` stays `null` —
   that's what marks the account as an admin, not a school-bound coach):

   ```sql
   insert into public.coaches (id, school_id, name, role, active)
   values ('paste-the-uuid-here', null, 'Admin''s Name', 'admin', true);
   ```

4. Sign in at `login.html` on the Coaches tab with that email and password.

**A note on the admin's own password:** the app deliberately gives no coach —
admin included — a way to change their own password (rule 4: coaches never
change their password; only the admin changes passwords, and there's no one
above the admin). If the admin ever needs to change their own password,
do it directly in **Authentication → Users** in the Supabase dashboard, not
through the app.

## Environment variable summary

| File | Contains | Committed to git? |
|---|---|---|
| `js/config.js` | Supabase URL + anon key | Yes — meant to be public |
| Vercel env vars | Supabase URL + service_role key | No — set in Vercel's dashboard |
