-- ============================================================
-- Campos de contrato na obra: cliente, valor do contrato, aditivos
-- ============================================================

alter table public.obras add column if not exists cliente text;
alter table public.obras add column if not exists valor_contrato numeric;
alter table public.obras add column if not exists aditivos jsonb not null default '[]'::jsonb;
