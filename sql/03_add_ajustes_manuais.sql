-- ============================================================
-- Coluna para guardar os ajustes manuais do cronograma (arrastar
-- pra mudar semana/equipe de um trecho) e a config avançada de
-- cada serviço (predecessores, produtividade por equipe, etc.)
-- ============================================================

alter table public.obras add column if not exists ajustes_manuais jsonb not null default '{}'::jsonb;

-- servicos.config já existe no schema original — nada a fazer aqui,
-- só confirma que está lá:
alter table public.servicos add column if not exists config jsonb not null default '{}'::jsonb;
