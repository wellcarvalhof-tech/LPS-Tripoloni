-- 38 — Início e fim de execução de cada linha da programação semanal
--
-- Por quê: a semana diz o QUE fazer, mas não em que dias. O encarregado recebe a programação e
-- precisa saber se o corte do 167 LD é segunda e terça ou quarta a sexta — é isso que permite
-- montar o quadro da semana (um serviço por linha, um dia por coluna) e distribuir na obra.
--
-- As duas colunas são opcionais: linha sem datas vale a semana inteira, que é como a
-- programação funcionava até aqui. Nada quebra em quem não preencher.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

alter table public.compromissos add column if not exists data_inicio date;
alter table public.compromissos add column if not exists data_fim    date;

comment on column public.compromissos.data_inicio is
  'Primeiro dia de execução dentro da semana. NULL = a semana inteira.';
comment on column public.compromissos.data_fim is
  'Último dia de execução dentro da semana. NULL = a semana inteira.';

-- Conferência depois de rodar:
--   select id, descricao, data_inicio, data_fim from public.compromissos limit 5;
