-- ============================================================
-- Estacas: separa VOLUME DE PROJETO (obra toda) de QUANTIDADE (saldo planejado).
--
-- São dois universos diferentes e misturá-los quebra os dois:
--
--   quantidade      -> o que o app planeja. Hoje o Tempo-Caminho é montado sobre o SALDO de
--                      serviço, não sobre o escopo total. Esse número soma pra virar a
--                      quantidade do lote e é o que move cronograma, histograma e curva S.
--
--   volume_projeto  -> o volume de projeto daquela estaca naquele serviço, vindo da planilha
--                      de controle, que cobre a OBRA TODA (inclusive o que já foi executado
--                      antes do planejamento começar).
--
-- O avanço físico volumétrico tem que sair do volume_projeto: é ele que representa o escopo
-- real. Se saísse da quantidade, mediria avanço contra o saldo e daria percentual inflado.
-- E o caminho inverso é pior: se a importação gravasse o volume total em quantidade, o
-- cronograma passaria a ser recalculado sobre a obra inteira e os prazos explodiriam.
--
-- Por isso a importação dos informes escreve SÓ em volume_projeto e nunca encosta em
-- quantidade nem em lote_servico.
-- ============================================================

alter table public.estaca_quantidades add column if not exists volume_projeto numeric;

comment on column public.estaca_quantidades.quantidade     is 'Saldo planejado — alimenta lote_servico e o cronograma.';
comment on column public.estaca_quantidades.volume_projeto is 'Volume de projeto da obra toda (planilha de controle) — base do avanço físico.';
