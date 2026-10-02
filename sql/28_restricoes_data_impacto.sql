-- ============================================================
-- Restrições: separa DATA DE IMPACTO de PREVISÃO DE REMOÇÃO.
--
-- Eram a mesma coisa (data_prazo) e não são:
--
--   data_impacto -> quando a restrição passa a atrapalhar a obra. É a data dura, a que vem do
--                   cronograma. É dela que sai o prazo ("faltam N dias"), se a restrição está
--                   atrasada e os indicadores (IRR e TMD).
--   data_prazo   -> quando quem vai resolver se compromete a remover. É o plano, e pode ser
--                   revisada com justificativa — sem mexer no impacto.
--
-- A diferença importa: adiar a previsão de remoção não pode melhorar o IRR, porque a obra
-- continua sendo impactada na mesma data. Antes, como eram o mesmo campo, adiava e o índice
-- subia sozinho.
--
-- No histórico que já foi importado as duas são iguais (a planilha só tinha "Data Limite"),
-- então o backfill abaixo copia data_prazo para data_impacto e nenhum número muda.
-- ============================================================

alter table public.restricoes add column if not exists data_impacto date;

update public.restricoes set data_impacto = data_prazo
 where data_impacto is null and data_prazo is not null;

create index if not exists idx_restricoes_impacto on public.restricoes(obra_id, data_impacto);
