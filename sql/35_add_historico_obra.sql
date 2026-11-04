-- ============================================================
-- 35 — Histórico anterior da obra
--
-- A obra começou em janeiro de 2026; o modelo de planejamento desta plataforma
-- entrou em setembro. Tudo que foi executado antes disso não tinha onde morar:
-- as quantidades cadastradas em Lotes & Quantidades são o SALDO, e as curvas
-- mediam o avanço contra esse saldo — ou seja, contra uma obra que começava do
-- zero em setembro.
--
-- Esta coluna guarda, por obra, o retrato do que já existia antes do plano:
-- a quantidade de CONTRATO e a EXECUTADA de cada serviço, com a data de corte
-- a que esse acumulado se refere.
--
-- Forma do jsonb:
-- {
--   "corte":   "2026-05-30",              -- o acumulado vale até esta data
--   "inicio":  "2026-01-05",              -- início real da obra (informativo)
--   "fonte":   "ACOMPANHAMENTO DE PRODUÇÃO ... REVISAO 8 / Cronograma FF (2)",
--   "importado_em": "2026-11-04T12:00:00.000Z",
--   "servicos": {
--     "<servico_id>": { "contrato": 623018.5, "executado": 277257.74,
--                       "grupo": "CORTE 1ª CAT", "unidade": "m³" }
--   }
-- }
--
-- Nada aqui altera o cronograma: `data_inicio` continua sendo a semana 1 do
-- Tempo-Caminho. Recuar aquela data empurraria todos os segmentos planejados
-- para trás e destruiria o plano — por isso o histórico é um campo separado.
-- ============================================================

alter table public.obras
  add column if not exists historico jsonb;

comment on column public.obras.historico is
  'Retrato do que a obra já tinha executado ANTES do início do planejamento nesta plataforma: contrato e executado por serviço, com data de corte. Ver sql/35_add_historico_obra.sql.';


-- ------------------------------------------------------------
-- Conferir se rodou
-- ------------------------------------------------------------
-- select column_name, data_type
--   from information_schema.columns
--  where table_schema='public' and table_name='obras' and column_name='historico';
