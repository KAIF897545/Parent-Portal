-- Parent Portal -- let anyone play Pencil Chess online without an account
--
-- Pencil Chess is separate from the student/coach portal, so players don't
-- sign up or sign in. Each player's browser keeps a random secret token; the
-- game only ever stores its SHA-256 hash (the "seat id"), so reading a game
-- never reveals anyone's token. Everything that changes a game goes through
-- the three functions below, which check the token against the seat. The table
-- itself is read-only for everyone (reading is needed for live updates).
--
-- Replaces the account-based policies from 029_pencil_chess.sql. Safe to run
-- more than once.

drop policy if exists pencil_games_select on public.pencil_games;
drop policy if exists pencil_games_insert on public.pencil_games;
drop policy if exists pencil_games_update on public.pencil_games;
drop policy if exists pencil_games_delete on public.pencil_games;

revoke all on table public.pencil_games from anon, authenticated;
grant select on public.pencil_games to anon, authenticated;

create policy pencil_games_select on public.pencil_games
  for select to anon, authenticated using (true);

-- Create a game. The caller must be the host and hold one of the two seats.
create or replace function public.pencil_create(p_code text, p_token text, p_data jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me text;
begin
  if p_token is null or length(p_token) < 16 then
    raise exception 'Invalid player.';
  end if;
  me := encode(sha256(convert_to(p_token, 'UTF8')), 'hex');

  if p_code is null or p_code !~ '^[A-Z0-9]{5}$' then
    raise exception 'Invalid game code.';
  end if;
  if length(p_data::text) > 4000 then
    raise exception 'Game data too large.';
  end if;
  if p_data->>'host' is distinct from me
     or not (coalesce(p_data->>'w' = me, false) or coalesce(p_data->>'b' = me, false)) then
    raise exception 'You must be the host and hold a seat.';
  end if;

  -- Housekeeping, and a cap so one browser can't flood the lobby.
  delete from public.pencil_games where created_at < now() - interval '2 days';
  if (select count(*) from public.pencil_games where data->>'host' = me and status = 'waiting') >= 3 then
    raise exception 'You already have open games. Cancel one first.';
  end if;

  insert into public.pencil_games (code, status, data)
  values (p_code, 'waiting', p_data - 'status');
end;
$$;

-- Change a game. Players of the game can update it; anyone can join a game that
-- is still waiting by taking the empty seat. Returns false if the game changed
-- since p_ver was read (the client re-reads and retries).
create or replace function public.pencil_patch(p_code text, p_token text, p_patch jsonb, p_ver int)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  me text;
  r public.pencil_games;
  merged jsonb;
  k text;
  allowed text[] := array['w', 'b', 'wu', 'bu', 'moves', 'updated', 'status', 'result', 'resigned', 'names'];
  join_allowed text[] := array['w', 'b', 'wu', 'bu', 'updated', 'status', 'names'];
  playing boolean;
begin
  if p_token is null or length(p_token) < 16 then
    raise exception 'Invalid player.';
  end if;
  me := encode(sha256(convert_to(p_token, 'UTF8')), 'hex');

  select * into r from public.pencil_games where code = p_code for update;
  if not found then
    raise exception 'No such game.';
  end if;
  if r.ver <> p_ver then
    return false;
  end if;

  playing := coalesce(me = r.data->>'w', false) or coalesce(me = r.data->>'b', false);

  for k in select jsonb_object_keys(p_patch) loop
    if k <> all (allowed) then
      raise exception 'Not allowed.';
    end if;
    if not playing and k <> all (join_allowed) then
      raise exception 'Not allowed.';
    end if;
  end loop;

  merged := r.data || (p_patch - 'status');

  if not playing then
    if r.status <> 'waiting'
       or not (coalesce(merged->>'w' = me, false) or coalesce(merged->>'b' = me, false)) then
      raise exception 'You are not in this game.';
    end if;
  end if;

  update public.pencil_games
     set data = merged,
         status = coalesce(p_patch->>'status', r.status)
   where code = p_code;
  return true;
end;
$$;

-- Cancel a game. Only the host can.
create or replace function public.pencil_delete(p_code text, p_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  me text;
begin
  if p_token is null or length(p_token) < 16 then
    raise exception 'Invalid player.';
  end if;
  me := encode(sha256(convert_to(p_token, 'UTF8')), 'hex');
  delete from public.pencil_games where code = p_code and data->>'host' = me;
end;
$$;

revoke all on function public.pencil_create(text, text, jsonb) from public;
revoke all on function public.pencil_patch(text, text, jsonb, int) from public;
revoke all on function public.pencil_delete(text, text) from public;
grant execute on function public.pencil_create(text, text, jsonb) to anon, authenticated;
grant execute on function public.pencil_patch(text, text, jsonb, int) to anon, authenticated;
grant execute on function public.pencil_delete(text, text) to anon, authenticated;
