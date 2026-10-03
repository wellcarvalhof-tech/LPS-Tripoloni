-- ============================================================
-- Estacas: volume REALIZADO por estaca × serviço.
--
-- A planilha guarda, por estaca, quanto já foi executado de cada serviço — e isso NÃO sai das
-- datas. Uma estaca pode estar 95% cortada: tem início, não tem término, e mesmo assim
-- produziu volume. São dois registros independentes e a obra sempre tratou assim:
--
--   data_inicio / data_fim  -> avanço LINEAR: onde a frente está, em que estaca
--   volume_realizado        -> avanço VOLUMÉTRICO: quanto saiu de fato
--
-- O percentual da estaca é a divisão dos dois (realizado ÷ projeto), então não precisa de
-- campo próprio.
--
-- Nada aqui toca lote_servico, producao_diaria ou o cronograma: é só controle de produção.
-- ============================================================

alter table public.estaca_quantidades add column if not exists volume_realizado numeric;

comment on column public.estaca_quantidades.volume_realizado is 'Executado nesta estaca neste serviço (planilha de controle). Independe das datas.';
