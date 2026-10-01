-- ============================================================
-- Programação Semanal — campos novos nos compromissos.
--
-- A programação puxa SUGESTÕES do Tempo-Caminho e da Linha de Balanço, mas o que vale
-- é o que o usuário deixar aqui: editar, apagar ou acrescentar linhas não mexe em
-- cronograma nenhum (por isso os campos são próprios, e não ligações rígidas).
--
--   grupo         -> campo aberto pra agrupar como a obra quiser (frente, equipe, turno…)
--   etapa         -> nome da etapa quando a linha vem da Linha de Balanço (texto livre)
--   lote_fim_id   -> trecho: do lote X ao lote Y (lote_id continua sendo o lote inicial)
--   detalhamento  -> descrição do que será feito
--   origem        -> 'tc' (tempo-caminho) | 'lb' (linha de balanço) | 'manual'
--   ordem         -> ordem de exibição dentro da semana
--
-- Previsto: serviço/etapa, grupo, lote início, lote fim, detalhamento, quantidade prevista.
-- Acompanhamento: status, quantidade realizada e causa de não cumprimento (já existiam).
-- ============================================================

alter table public.compromissos add column if not exists grupo        text;
alter table public.compromissos add column if not exists etapa        text;
alter table public.compromissos add column if not exists lote_fim_id  uuid references public.lotes(id) on delete set null;
alter table public.compromissos add column if not exists detalhamento text;
alter table public.compromissos add column if not exists origem       text not null default 'manual';
alter table public.compromissos add column if not exists ordem        integer not null default 0;

-- descrição deixa de ser obrigatória (o nome vem do serviço/etapa)
alter table public.compromissos alter column descricao drop not null;

create index if not exists idx_compromissos_plano_ordem on public.compromissos(plano_id, ordem);
