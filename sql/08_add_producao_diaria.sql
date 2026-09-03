-- ============================================================
-- Produção Diária (RDO) — lançamentos reais de quantidade
-- executada por serviço/lote/data. Alimenta o "realizado" da
-- Curva S (aba Acompanhamento > Curva S / Produção Diária).
-- ============================================================

create table if not exists public.producao_diaria (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  servico_id  uuid not null references public.servicos(id) on delete cascade,
  lote_id     uuid not null references public.lotes(id) on delete cascade,
  data        date not null,
  quantidade  numeric not null default 0,
  created_at  timestamptz not null default now()
);
create index if not exists idx_prod_diaria_obra on public.producao_diaria(obra_id);
create index if not exists idx_prod_diaria_data on public.producao_diaria(obra_id,data);
alter table public.producao_diaria enable row level security;
drop policy if exists prod_diaria_member_all on public.producao_diaria;
create policy prod_diaria_member_all on public.producao_diaria for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
