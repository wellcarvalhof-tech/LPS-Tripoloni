-- ============================================================
-- EAP de serviços: o de-para entre as linguagens da obra
--
-- A obra fala quatro línguas pro mesmo serviço e nenhuma bate com a outra:
--
--   código da EAP de controle   2.2.1 CFT 01      (colunas da planilha de controle)
--   código contratual           T04               (cronograma do contrato)
--   serviço planejado           CFT               (o serviço do Tempo-Caminho)
--   item do orçamento           2.4 CFT           (a planilha de composições)
--
-- No CFT são três itens de EAP, um serviço planejado e um item de orçamento — e
-- o mesmo T04 cobre dois dos três. Até aqui essa tradução era refeita à mão a
-- cada importação; a EAP guarda o de-para uma vez só.
--
-- Fica em jsonb na obra, como ajustes_manuais e orcamento: são poucas dezenas
-- de linhas, sempre lidas inteiras, e assim não esbarram no teto de 1000 linhas
-- por SELECT do PostgREST.
--
-- Formato gravado em obras.eap:
--   {
--     "cfg": {"arquivo":"...", "importadoEm":"ISO"},
--     "itens": [
--       {"cod":"2.2.1", "nome":"CFT 01", "un":"m³", "contratual":"T04",
--        "svc":"<uuid do serviço>",              -- serviço planejado (0 ou 1)
--        "controle":["2.2.1 CFT 01 (m)","CFT 01"], -- apelidos na planilha de controle
--        "orc":"S1|2.4",                          -- item do orçamento (0 ou 1)
--        "sug":{"svc":true},                      -- veio de semelhança de nome, a confirmar
--        "auto":true}                             -- grupo criado a partir do código do filho
--     ]
--   }
--
-- A hierarquia sai do próprio código: 2.2.1 é filho de 2.2, que é filho de 2.
-- Não há quantidade aqui de propósito — ela vive em lote_servico e no orçamento,
-- e o mesmo número em dois lugares sempre termina divergindo.
--
-- Serviço do app pode existir sem item de EAP: ela é uma camada de leitura por
-- cima do cadastro, não um portão na frente dele.
-- ============================================================

alter table public.obras add column if not exists eap jsonb;

comment on column public.obras.eap is
  'EAP de serviços e o de-para com serviço planejado, serviço controlado e item do orçamento. Documentado em sql/33_eap_servicos.sql.';

-- As políticas de RLS de obras já cobrem a coluna nova: quem lê e escreve a
-- obra lê e escreve a EAP dela. Nenhuma policy precisa ser recriada.
