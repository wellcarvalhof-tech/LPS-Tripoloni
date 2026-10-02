-- ============================================================
-- Médio Prazo · Restrições — acompanhamento e indicadores (IRR, TMD, TMR).
--
-- A tabela restricoes já existia desde o schema inicial, mas só com o básico. Pra medir
-- remoção no prazo, revisão de data e os indicadores do Excel, faltava guardar:
--
--   codigo               -> ID legível por obra (R-001, R-002…), que é como a obra fala da restrição
--   semana               -> semana do projeto em que a restrição foi lançada (janela do médio prazo)
--   equipe               -> equipe da célula de onde ela saiu (quando veio da matriz)
--   data_prazo_original  -> a PRIMEIRA previsão de resolução. data_prazo é a vigente; a original
--                           fica parada pra dar o TMD honesto e mostrar o quanto a data escorregou
--   data_conclusao       -> quando foi removida de fato (removida no prazo × com atraso, e o TMR)
--   revisoes             -> histórico [{de,para,motivo,em,por}] — toda mudança de prazo exige motivo
--   observacao           -> anotação livre do acompanhamento
--
-- Também entra o status 'cancelada': restrição que deixou de fazer sentido não conta como
-- falha de remoção, mas também não pode sumir do histórico.
--
-- "Atrasada" NÃO é status guardado: é calculado (em aberto + prazo vencido). Guardar daria
-- status errado no dia seguinte, porque ninguém volta no sistema pra mudar.
-- ============================================================

alter type public.status_restricao add value if not exists 'cancelada';

alter table public.restricoes add column if not exists codigo              text;
alter table public.restricoes add column if not exists semana              integer;
alter table public.restricoes add column if not exists equipe              integer;
alter table public.restricoes add column if not exists data_prazo_original date;
alter table public.restricoes add column if not exists data_conclusao      date;
alter table public.restricoes add column if not exists revisoes            jsonb not null default '[]'::jsonb;
alter table public.restricoes add column if not exists observacao          text;

-- quem já tinha prazo e nunca foi revisado: a original é a atual
update public.restricoes set data_prazo_original = data_prazo
 where data_prazo_original is null and data_prazo is not null;

create unique index if not exists idx_restricoes_codigo on public.restricoes(obra_id, codigo) where codigo is not null;
create index if not exists idx_restricoes_prazo  on public.restricoes(obra_id, data_prazo);
create index if not exists idx_restricoes_status on public.restricoes(obra_id, status);
