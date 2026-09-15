-- ============================================================
-- Alocação de Apoio Administrativo — quantidade e período de
-- mobilização de cada item do catálogo (apoio_admin) nesta obra.
-- Separado do catálogo em si (que é só a estrutura de 3 níveis),
-- igual quantidades/lote_servico são separados de lotes/servicos.
-- ============================================================

create table if not exists public.apoio_alocacao (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  apoio_id    uuid not null references public.apoio_admin(id) on delete cascade,
  quantidade  numeric not null default 0,
  data_inicio date,
  data_fim    date,
  updated_at  timestamptz not null default now(),
  unique(apoio_id)
);
create index if not exists idx_apoio_alocacao_obra on public.apoio_alocacao(obra_id);
alter table public.apoio_alocacao enable row level security;
drop policy if exists apoio_alocacao_member_all on public.apoio_alocacao;
create policy apoio_alocacao_member_all on public.apoio_alocacao for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
