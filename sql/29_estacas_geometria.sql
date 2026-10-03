-- ============================================================
-- Controle de produção por estaca: geometria, volumes de projeto e EAP.
--
-- A planilha "Informes de produção" guarda, por estaca de 20m: a largura da pista, a
-- espessura de cada camada, os volumes de projeto de terraplanagem e o par início/término
-- de cada serviço. O que faltava no app:
--
--   lote_estacas.largura_m      -> largura da plataforma naquela estaca
--   lote_estacas.acesso         -> "Nomenclatura de acessos (EAP comercial)" da planilha
--   lote_estacas.vol_corte      -> volumes de PROJETO (não dá pra calcular: vêm da cubação)
--   lote_estacas.vol_rebaixo
--   lote_estacas.vol_aterro
--
--   estaca_quantidades.espessura_m   -> espessura da camada naquela estaca. Com a largura e o
--                                       espaçamento, a quantidade sai sozinha:
--                                       qtd = largura × espessura × espaçamento
--   estaca_quantidades.nao_se_aplica -> a célula cinza da planilha. Diferente de zero: zero é
--                                       "tem que fazer e ainda não fez"; aqui o serviço não
--                                       existe naquela estaca e não pode pesar no avanço.
--
--   servicos.codigo -> código da EAP do cronograma contratual (T02, T02.2, T03…)
--   servicos.eap    -> item da EAP (2.1, 2.1.1, 2.2.1…)
--   servicos.grupo  -> macro-item (2 Terraplenagem, 3 Pavimentação…)
--
-- O código é o que amarra a planilha ao serviço do app na importação, e depois deixa previsto
-- (Tempo-Caminho) e realizado (estacas) conversarem sem de-para manual.
-- ============================================================

alter table public.lote_estacas add column if not exists largura_m   numeric;
alter table public.lote_estacas add column if not exists acesso      text;
alter table public.lote_estacas add column if not exists vol_corte   numeric;
alter table public.lote_estacas add column if not exists vol_rebaixo numeric;
alter table public.lote_estacas add column if not exists vol_aterro  numeric;

alter table public.estaca_quantidades add column if not exists espessura_m    numeric;
alter table public.estaca_quantidades add column if not exists nao_se_aplica  boolean not null default false;

alter table public.servicos add column if not exists codigo text;
alter table public.servicos add column if not exists eap    text;
alter table public.servicos add column if not exists grupo  text;

create index if not exists idx_servicos_codigo on public.servicos(obra_id, codigo) where codigo is not null;
