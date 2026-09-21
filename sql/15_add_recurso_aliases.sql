-- ============================================================
-- Histograma: importação do realizado a partir da planilha de acompanhamento
-- da obra (abas "Dados EFETIVO DP" e "DADOS Realizado CEQ").
--
-- recursos.aliases = lista de nomes "de-para": como o recurso aparece na
-- planilha (ex.: "MOTONIVELADORA CAT 140" -> recurso "MN - MOTONIVELADORA").
-- O app pergunta o de-para na primeira importação e guarda aqui; nas próximas
-- vezes casa automático. Mão de obra normalmente casa pelo nome (FUNÇÃO OBRA).
-- ============================================================
alter table public.recursos add column if not exists aliases jsonb not null default '[]'::jsonb;
