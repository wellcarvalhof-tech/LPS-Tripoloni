-- ============================================================
-- Categoria livre por recurso (ex.: M.O.D., M.O.I., Equipamentos
-- Pesados...) — agrupa a tabela de Realizado no Histograma.
-- ============================================================

alter table public.recursos add column if not exists categoria text;
