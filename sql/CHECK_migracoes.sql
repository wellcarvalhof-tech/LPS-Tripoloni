-- ============================================================
-- Diagnóstico: quais migrações já rodaram neste banco.
--
-- Cole no SQL Editor do Supabase e rode. Não altera nada — só olha.
-- Cada linha diz se a mudança daquele arquivo já está no banco.
-- O que aparecer como "FALTA" é só abrir o arquivo em sql/ e rodar.
-- ============================================================

with c as (
  select table_name, column_name from information_schema.columns where table_schema='public'
), t as (
  select table_name from information_schema.tables where table_schema='public'
)
select * from (
  values
  ('15_add_recurso_aliases',        (select count(*)>0 from c where table_name='recursos' and column_name='aliases')),
  ('16_add_recurso_classe',         (select count(*)>0 from c where table_name='recursos' and column_name='classe')),
  ('17_add_admin_desenvolvedor',    (select count(*)>0 from public.user_roles where role='admin')),
  ('18_limita_criacao_de_obras',    (to_regprocedure('public.pode_criar_obra()') is not null)),
  ('19_add_realizado_terceiro',     (select count(*)>0 from c where table_name='apontamento_recursos' and column_name='quantidade_terceiro')),
  ('20_add_linha_balanco',          (select count(*)>0 from c where table_name='obras' and column_name='linha_balanco')),
  ('21_add_perfil_controle',        (select count(*)>0 from pg_constraint where conname='obra_membros_papel_check' and pg_get_constraintdef(oid) like '%controle%')),
  ('22_add_presenca',               (select count(*)>0 from t where table_name='presenca')),
  ('23_add_auditoria',              (select count(*)>0 from t where table_name='auditoria')),
  ('24_programacao_semanal',        (select count(*)>0 from c where table_name='compromissos' and column_name='grupo')),
  ('26_restricoes_acompanhamento',  (select count(*)>0 from c where table_name='restricoes' and column_name='data_conclusao')),
  ('27_restricoes_pacote_local',    (select count(*)>0 from c where table_name='restricoes' and column_name='pacote')),
  ('28_restricoes_data_impacto',    (select count(*)>0 from c where table_name='restricoes' and column_name='data_impacto')),
  ('29_estacas_geometria',          (select count(*)>0 from c where table_name='lote_estacas' and column_name='largura_m')),
  ('30_estaca_volume_projeto',      (select count(*)>0 from c where table_name='estaca_quantidades' and column_name='volume_projeto')),
  ('31_estaca_volume_realizado',    (select count(*)>0 from c where table_name='estaca_quantidades' and column_name='volume_realizado')),
  ('25_fix_views_security_invoker', (select coalesce(bool_and(array_to_string(cl.reloptions,',') like '%security_invoker=%'),false)
                                       from pg_class cl join pg_namespace n on n.oid=cl.relnamespace
                                      where n.nspname='public' and cl.relname in ('vw_ppc_semanal','vw_curva_s')))
) as m(migracao, rodou)
order by migracao;
