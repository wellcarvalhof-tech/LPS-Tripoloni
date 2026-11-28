-- 42 — RDO: onde a produção aconteceu, e como foi o dia
--
-- Por quê: a Produção Diária registrava QUANTO e em QUAL LOTE. O lote é grosso demais para
-- rastrear onde a equipe esteve — num lote de 2 km, "12.000 m³ no 255" não diz se a frente
-- andou no começo ou no fim. E o dia não tinha onde guardar o que todo diário de obra guarda:
-- o clima, a condição de trabalho, o efetivo e o que atrapalhou.
--
-- Esta migração faz as duas coisas:
--   1. producao_diaria ganha o intervalo de estacas do lançamento (texto livre de propósito:
--      obra sem cubação importada não tem estaca cadastrada, e mesmo assim a equipe sabe dizer
--      "de 255+000 a 258+020"). A coluna `observacao`, que já existia, passa a ser o campo de
--      detalhes da linha — é dela que os importadores já escrevem a origem do lançamento.
--   2. nasce rdo_dia: uma linha por obra e por dia, com o cabeçalho do diário.
--
-- Uma linha por obra+dia é regra do banco, não da tela: dois RDOs do mesmo dia seriam duas
-- versões da verdade, e quem lê depois não teria como saber qual vale.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

-- ---------------------------------------------------------------------------
-- 1) Onde foi a produção
-- ---------------------------------------------------------------------------
alter table public.producao_diaria
  add column if not exists estaca_ini text,
  add column if not exists estaca_fim text;

comment on column public.producao_diaria.estaca_ini is
  'Estaca (ou km) onde o serviço começou no dia. Texto livre: "255+000". Opcional.';
comment on column public.producao_diaria.estaca_fim is
  'Estaca (ou km) onde o serviço parou no dia. Texto livre: "258+020". Opcional.';
comment on column public.producao_diaria.observacao is
  'Detalhes do lançamento — o que a equipe escreve sobre aquele serviço naquele dia.';

-- ---------------------------------------------------------------------------
-- 2) O cabeçalho do dia
-- ---------------------------------------------------------------------------
create table if not exists public.rdo_dia (
  id            uuid primary key default gen_random_uuid(),
  obra_id       uuid not null references public.obras(id) on delete cascade,
  data          date not null,
  clima_manha   text,
  clima_tarde   text,
  condicao      text,
  efetivo       integer,
  equipamentos  text,
  ocorrencias   text,
  created_by    uuid default auth.uid(),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  unique (obra_id, data)
);

comment on table  public.rdo_dia              is 'Cabeçalho do Relatório Diário de Obra: uma linha por obra e por dia.';
comment on column public.rdo_dia.clima_manha  is 'bom | nublado | chuva | chuva_forte';
comment on column public.rdo_dia.clima_tarde  is 'bom | nublado | chuva | chuva_forte';
comment on column public.rdo_dia.condicao     is 'praticavel | parcial | impraticavel — se deu para trabalhar no dia.';
comment on column public.rdo_dia.efetivo      is 'Quantas pessoas estiveram na obra no dia.';
comment on column public.rdo_dia.ocorrencias  is 'O que aconteceu no dia: parada de chuva, quebra, visita, acidente.';

create index if not exists rdo_dia_obra_idx on public.rdo_dia(obra_id, data desc);

alter table public.rdo_dia enable row level security;

-- Mesma regra das outras tabelas da obra: quem é membro da obra lê e escreve.
drop policy if exists rdo_dia_member_all on public.rdo_dia;
create policy rdo_dia_member_all on public.rdo_dia for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));

-- Conferência rápida depois de rodar:
--   select data, clima_manha, condicao, efetivo from public.rdo_dia order by data desc limit 5;
--   select data, estaca_ini, estaca_fim, observacao from public.producao_diaria order by data desc limit 5;
