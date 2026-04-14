-- Ejecutar en Supabase SQL editor (o migración) antes de usar la app con la nueva versión.
alter table public.player_stats
  add column if not exists minutes_played integer not null default 0;

alter table public.player_stats
  add column if not exists times_started integer not null default 0;
