-- ============================================================
-- Orçamento do projeto e AVA (Análise do Valor Agregado)
--
-- O orçamento inteiro vive numa coluna jsonb da obra, do mesmo jeito que
-- obras.ajustes_manuais: ele vai e volta inteiro, nunca é consultado por
-- pedaço, e uma planilha de orçamento tem centenas de linhas — em tabela
-- própria isso bateria no teto de 1000 linhas por SELECT do PostgREST e
-- exigiria paginar uma leitura que sempre é integral.
--
-- Formato gravado em obras.orcamento:
--   {
--     "cfg": {"base":"custo"|"venda", "bac":0, "limiarAtencao":0.95,
--             "limiarCritico":0.90, "arquivo":"...", "importadoEm":"ISO"},
--     "secoes": [{"k":"S1","nome":"DUPLICAÇÃO"}],
--     "meses":  ["2026-10","2026-11", ...],            -- eixo do cronograma importado
--     "itens":  [{"id":"S1|2.3","sec":"S1","cod":"2.3","nivel":2,"pai":"2",
--                 "nome":"Aterro","un":"m³","qtd":163691.43,
--                 "cu":23.37,"custo":3825468.72,"vu":15.03,"venda":2460378.2,
--                 "folha":true,"svc":null,
--                 "pm":{"2027-01":1200000.0},            -- previsto mensal (R$)
--                 "rm":{"2027-01":0.18}}],               -- realizado acumulado (fração)
--     "custos": {"2026-10": 0}                           -- CRTR lançado por mês (R$)
--   }
--
-- Nada aqui altera o cronograma: o orçamento só dá PESO FINANCEIRO às
-- atividades. O Tempo-Caminho continua calculado por quantidade e equipe.
-- ============================================================

alter table public.obras add column if not exists orcamento jsonb;

comment on column public.obras.orcamento is
  'Orçamento do projeto e lançamentos da AVA (cfg/secoes/meses/itens/custos). Documentado em sql/32_orcamento_ava.sql.';

-- As políticas de RLS de obras já cobrem a coluna nova: quem lê e escreve a
-- obra lê e escreve o orçamento dela. Nenhuma policy precisa ser recriada.
