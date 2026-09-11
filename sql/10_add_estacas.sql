-- ============================================================
-- Estaqueamento por lote — controle de produção fino (corte, aterro,
-- CFT, base... por estaca), separado do cronograma. O cronograma
-- (Tempo-Caminho) continua calculado por lote, sem nenhuma mudança;
-- as estacas só alimentam as quantidades por lote (soma automática)
-- e o "realizado" da Curva S (via producao_diaria), com mais detalhe.
-- ============================================================

alter table public.lotes add column if not exists comprimento_m numeric;
alter table public.lotes add column if not exists espacamento_estaca_m numeric not null default 20;

create table if not exists public.lote_estacas (
  id           uuid primary key default gen_random_uuid(),
  obra_id      uuid not null references public.obras(id) on delete cascade,
  lote_id      uuid not null references public.lotes(id) on delete cascade,
  numero       int not null,
  distancia_m  numeric not null default 0,
  created_at   timestamptz not null default now(),
  unique(lote_id,numero)
);
create index if not exists idx_lote_estacas_lote on public.lote_estacas(lote_id);

-- Quantidade cadastrada por estaca+serviço (corte, aterro, CFT, base...).
-- A soma de todas as estacas de um lote, por serviço, é gravada em
-- lote_servico (a mesma tabela de quantidades por lote que já existe),
-- então o cronograma nem sabe que isso existe — só vê o total.
create table if not exists public.estaca_quantidades (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  lote_id     uuid not null references public.lotes(id) on delete cascade,
  estaca_id   uuid not null references public.lote_estacas(id) on delete cascade,
  servico_id  uuid not null references public.servicos(id) on delete cascade,
  quantidade  numeric not null default 0,
  updated_at  timestamptz not null default now(),
  unique(estaca_id,servico_id)
);
create index if not exists idx_estaca_qtd_estaca on public.estaca_quantidades(estaca_id);
create index if not exists idx_estaca_qtd_lote on public.estaca_quantidades(lote_id);

-- Avanço: data de início/término de cada serviço em cada estaca. Quando
-- a data de término é preenchida, o app cria automaticamente um
-- lançamento em producao_diaria (mesma tabela que já alimenta a Curva S
-- "Realizado") com a quantidade daquela estaca — producao_diaria_id
-- guarda o vínculo pra poder atualizar/remover se a data mudar.
create table if not exists public.estaca_apontamentos (
  id                  uuid primary key default gen_random_uuid(),
  obra_id             uuid not null references public.obras(id) on delete cascade,
  lote_id             uuid not null references public.lotes(id) on delete cascade,
  estaca_id           uuid not null references public.lote_estacas(id) on delete cascade,
  servico_id          uuid not null references public.servicos(id) on delete cascade,
  data_inicio         date,
  data_fim            date,
  producao_diaria_id  uuid references public.producao_diaria(id) on delete set null,
  updated_at          timestamptz not null default now(),
  unique(estaca_id,servico_id)
);
create index if not exists idx_estaca_apont_estaca on public.estaca_apontamentos(estaca_id);
create index if not exists idx_estaca_apont_lote on public.estaca_apontamentos(lote_id);

do $blk$
declare t text;
begin
  foreach t in array array['lote_estacas','estaca_quantidades','estaca_apontamentos'] loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists %I_member_all on public.%I;', t, t);
    execute format('create policy %I_member_all on public.%I for all using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));', t, t);
  end loop;
end $blk$;
