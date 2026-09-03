-- ============================================================
-- Produção Diária (RDO) — lançamentos reais de quantidade
-- executada por serviço/lote/data. Alimenta o "realizado" da
-- Curva S (aba Acompanhamento > Curva S / Produção Diária).
--
-- NOTA: a tabela public.producao_diaria já existia desde
-- 01_schema_supabase_proprio.sql com um formato compatível
-- (obra_id, data, servico_id, lote_id, equipe_id, quantidade,
-- observacao, created_by). Este script só garante que as
-- colunas usadas pelo app existem, sem recriar nada.
-- ============================================================

create table if not exists public.producao_diaria (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  data        date not null default current_date,
  created_at  timestamptz not null default now()
);

alter table public.producao_diaria add column if not exists servico_id uuid references public.servicos(id) on delete set null;
alter table public.producao_diaria add column if not exists lote_id uuid references public.lotes(id) on delete set null;
alter table public.producao_diaria add column if not exists quantidade numeric not null default 0;

create index if not exists idx_prod_diaria_obra on public.producao_diaria(obra_id);
create index if not exists idx_prod_diaria_data on public.producao_diaria(obra_id,data);
alter table public.producao_diaria enable row level security;
drop policy if exists prod_diaria_member_all on public.producao_diaria;
create policy prod_diaria_member_all on public.producao_diaria for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
