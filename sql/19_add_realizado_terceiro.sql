-- ============================================================
-- Histograma: parcela de TERCEIROS dentro do realizado.
--
-- O previsto é geral — no planejamento não dá pra saber se o equipamento (ou a
-- mão de obra) vai ser da frota própria ou locado. Quem sabe disso é o realizado.
-- Por isso a divisão fica aqui, no apontamento, e não no cadastro do recurso:
--
--   quantidade           = realizado TOTAL da semana (próprio + terceiro) — como já era
--   quantidade_terceiro  = quanto desse total é de terceiro
--   próprio              = quantidade − quantidade_terceiro
--
-- Apontamentos antigos ficam com terceiro = 0 (tudo próprio) até serem reimportados
-- ou ajustados na tela. A importação DP + CEQ preenche os dois valores sozinha,
-- usando a coluna Locador da aba "DADOS Realizado CEQ" (TRIPOLONI = próprio).
-- ============================================================
alter table public.apontamento_recursos
  add column if not exists quantidade_terceiro numeric not null default 0;
