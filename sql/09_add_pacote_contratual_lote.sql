-- ============================================================
-- Pacote contratual do lote: obra dividida em mais de um contrato
-- (ex.: Lote 1, Lote 2, Lote 3) que compartilham o mesmo cronograma
-- integrado (serviços sequenciais entre eles), mas precisam de
-- relatórios/curvas separados por questão contratual.
-- ============================================================

alter table public.lotes add column if not exists pacote_contratual text;
