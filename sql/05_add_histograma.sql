-- ============================================================
-- Histograma de recursos: catálogo de recursos (funções/equipamentos)
-- e apontamento semanal do realizado
-- ============================================================

create table if not exists public.recursos (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  nome       text not null,
  tipo       text not null default 'funcao' check (tipo in ('funcao','equipamento')),
  unidade    text not null default 'un',
  ordem      int  not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_recursos_obra on public.recursos(obra_id);
alter table public.recursos enable row level security;
drop policy if exists recursos_member_all on public.recursos;
create policy recursos_member_all on public.recursos for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));

create table if not exists public.apontamento_recursos (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  recurso_id  uuid not null references public.recursos(id) on delete cascade,
  data_semana date not null, -- segunda-feira da semana apontada
  quantidade  numeric not null default 0,
  created_at  timestamptz not null default now(),
  unique (recurso_id, data_semana)
);
create index if not exists idx_apontrec_obra on public.apontamento_recursos(obra_id);
alter table public.apontamento_recursos enable row level security;
drop policy if exists apontrec_member_all on public.apontamento_recursos;
create policy apontrec_member_all on public.apontamento_recursos for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
