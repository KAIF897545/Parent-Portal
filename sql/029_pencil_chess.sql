-- Parent Portal -- online games for Pencil Chess (pencil-chess.html)
--
-- One row per game, keyed by the 5-character invite code. The whole game
-- document (seats, moves, names, result) lives in `data`; `status` is mirrored
-- into its own column so the open-games lobby can filter on it. Only signed-in
-- portal users (students, coaches, admins) can read or play; seats are the
-- players' auth user ids.

create table public.pencil_games (
  code       text primary key check (code ~ '^[A-Z0-9]{5}$'),
  status     text not null default 'waiting' check (status in ('waiting', 'playing', 'over')),
  ver        int  not null default 0,
  data       jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.pencil_games enable row level security;

grant select, insert, update, delete on public.pencil_games to authenticated;

create policy pencil_games_select on public.pencil_games
  for select to authenticated using (true);

-- Create: you must be the host and occupy one seat, and the game starts waiting.
create policy pencil_games_insert on public.pencil_games
  for insert to authenticated
  with check (
    status = 'waiting'
    and data->>'host' = auth.uid()::text
    and (data->>'w' = auth.uid()::text or data->>'b' = auth.uid()::text)
  );

-- Update: players of the game, or anyone joining a game that is still waiting;
-- afterwards you must hold a seat in it.
create policy pencil_games_update on public.pencil_games
  for update to authenticated
  using (status = 'waiting' or auth.uid()::text in (data->>'w', data->>'b'))
  with check (auth.uid()::text in (data->>'w', data->>'b'));

create policy pencil_games_delete on public.pencil_games
  for delete to authenticated
  using (data->>'host' = auth.uid()::text);

-- Bump the version on every change (the client uses it to avoid overwriting the
-- other player's move) and stop anyone taking over a seat that is already filled.
create or replace function public.pencil_games_guard()
returns trigger
language plpgsql
as $$
begin
  new.ver := old.ver + 1;
  if new.code is distinct from old.code then
    raise exception 'The game code cannot change.';
  end if;
  if old.data->>'host' is distinct from new.data->>'host' then
    raise exception 'The host cannot change.';
  end if;
  if old.data->>'w' is not null and old.data->>'w' is distinct from new.data->>'w' then
    raise exception 'That seat is already taken.';
  end if;
  if old.data->>'b' is not null and old.data->>'b' is distinct from new.data->>'b' then
    raise exception 'That seat is already taken.';
  end if;
  return new;
end;
$$;

create trigger trg_pencil_games_guard
before update on public.pencil_games
for each row execute function public.pencil_games_guard();

-- Live updates for both players.
do $$
begin
  alter publication supabase_realtime add table public.pencil_games;
exception when duplicate_object then
  null;
end $$;
