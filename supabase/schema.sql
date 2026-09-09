-- Reto Sin Pena — Pato Odor Block
-- Schema for the game's data tables in Supabase.
--
-- These tables are namespaced with the "pato_" prefix so they can coexist
-- safely in a Supabase project that already has other, unrelated tables.
--
-- Data model: each table stores one JSON "document" per row, mirroring a
-- Firestore-like doc/collection structure. This keeps the client-side code
-- simple (one generic adapter, see wrapSupabase() in index.html) while still
-- getting Postgres + Realtime for free.
--
--   pato_config   -> single row, id = "settings"   (game configuration)
--   pato_state    -> single row, id = "current"    (current round/game state)
--   pato_players  -> one row per participant, id = player slug
--   pato_answers  -> one row per (round, place), id = "<roundId>__<slug>"
--
-- This file is a checked-in copy of the migration already applied to the
-- live project via the Supabase MCP tools (migration name:
-- create_pato_game_tables). Safe to re-run: every statement is idempotent.

create table if not exists public.pato_config (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.pato_state (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.pato_players (
  id text primary key,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table if not exists public.pato_answers (
  id text primary key,
  round_id integer not null default 0,
  count integer not null default 0,
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create index if not exists pato_answers_round_id_idx on public.pato_answers (round_id);
create index if not exists pato_answers_count_idx on public.pato_answers (count desc);

-- Realtime: let clients subscribe to changes on these tables.
-- (ALTER PUBLICATION ... ADD TABLE has no IF NOT EXISTS, so this is wrapped
-- to stay safe to re-run.)
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'pato_config'
  ) then
    alter publication supabase_realtime add table public.pato_config;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'pato_state'
  ) then
    alter publication supabase_realtime add table public.pato_state;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'pato_players'
  ) then
    alter publication supabase_realtime add table public.pato_players;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'pato_answers'
  ) then
    alter publication supabase_realtime add table public.pato_answers;
  end if;
end $$;

-- Row Level Security: the game has no login system (it's a party game with
-- a name-based lookup, not real auth), so every policy below is fully open.
-- This is safe because the anon/publishable key only grants access to these
-- four "pato_" tables — nothing else in the project.
alter table public.pato_config enable row level security;
alter table public.pato_state enable row level security;
alter table public.pato_players enable row level security;
alter table public.pato_answers enable row level security;

-- CREATE POLICY has no IF NOT EXISTS in Postgres, so drop-then-create makes
-- this file safe to re-run.
drop policy if exists "public select" on public.pato_config;
drop policy if exists "public insert" on public.pato_config;
drop policy if exists "public update" on public.pato_config;
create policy "public select" on public.pato_config for select using (true);
create policy "public insert" on public.pato_config for insert with check (true);
create policy "public update" on public.pato_config for update using (true) with check (true);

drop policy if exists "public select" on public.pato_state;
drop policy if exists "public insert" on public.pato_state;
drop policy if exists "public update" on public.pato_state;
create policy "public select" on public.pato_state for select using (true);
create policy "public insert" on public.pato_state for insert with check (true);
create policy "public update" on public.pato_state for update using (true) with check (true);

drop policy if exists "public select" on public.pato_players;
drop policy if exists "public insert" on public.pato_players;
drop policy if exists "public update" on public.pato_players;
create policy "public select" on public.pato_players for select using (true);
create policy "public insert" on public.pato_players for insert with check (true);
create policy "public update" on public.pato_players for update using (true) with check (true);

drop policy if exists "public select" on public.pato_answers;
drop policy if exists "public insert" on public.pato_answers;
drop policy if exists "public update" on public.pato_answers;
create policy "public select" on public.pato_answers for select using (true);
create policy "public insert" on public.pato_answers for insert with check (true);
create policy "public update" on public.pato_answers for update using (true) with check (true);
