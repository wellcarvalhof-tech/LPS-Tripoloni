-- 41 — Duas datas na obra: quando ela começou e onde a matriz começa
--
-- Por quê: até aqui `obras.data_inicio` fazia dois trabalhos ao mesmo tempo. Era a data em que
-- a obra começou E a semana 1 da Matriz Tempo-Caminho. Numa obra que já vinha rodando antes de
-- o planejamento existir (um contrato nos anos 03 e 04, por exemplo) as duas não são a mesma
-- coisa: a obra começou lá atrás, e o plano foi fincado agora. Quem recuava a data para contar
-- a verdade empurrava todos os segmentos do cronograma para trás junto — então ninguém recuava,
-- e a produção apontada antes do plano sumia da tela sem explicação.
--
-- A partir daqui:
--   data_inicio         — quando a obra começou de verdade (a linha do tempo do Retigráfico
--                         começa aqui, e é aqui que entra o que foi apontado antes do plano);
--   data_inicio_matriz  — a segunda-feira da semana 1 do Tempo-Caminho. Em branco = a matriz
--                         continua começando na data de início da obra, que é exatamente o
--                         comportamento de antes.
--
-- Obra antiga fica com a coluna nova em NULL e não muda de comportamento nenhum. Por isso a
-- coluna nasce NULL e não copiando data_inicio: NULL quer dizer "ninguém separou as duas", e
-- copiar transformaria um palpite em dado.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

alter table public.obras
  add column if not exists data_inicio_matriz date;

comment on column public.obras.data_inicio_matriz is
  'Segunda-feira da semana 1 da Matriz Tempo-Caminho. NULL = a matriz começa em data_inicio (comportamento anterior à migração 41).';

-- Conferência rápida depois de rodar:
--   select nome, data_inicio, data_inicio_matriz from public.obras order by created_at desc;
