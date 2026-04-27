-- Hueco táctico al inicio del partido; [position] sigue reflejando el estado en vivo.
alter table public.match_lineup
  add column if not exists initial_position integer;

comment on column public.match_lineup.initial_position is
  'Índice del hueco en campo al inicio (1ª parte). Se fija al arrancar el partido; position sigue los cambios.';
