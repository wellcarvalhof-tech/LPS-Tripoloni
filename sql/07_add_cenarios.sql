-- ============================================================
-- Cenários e Linhas de Base (baseline) do Tempo-Caminho
-- Cada linha guarda um snapshot dos ajustes manuais (OVR) —
-- um "rascunho" é um what-if; uma "baseline" é uma linha de base
-- congelada (REV00, REV01, ...) usada como previsto de referência
-- na Curva S. Só uma baseline fica "ativa" por obra por vez.
-- ============================================================

create table if not exists public.cenarios (
  id              uuid primary key default gen_random_uuid(),
  obra_id         uuid not null references public.obras(id) on delete cascade,
  nome            text not null,
  tipo            text not null default 'rascunho' check (tipo in ('rascunho','baseline')),
  revisao         text,           -- 'REV00','REV01',... só quando tipo='baseline'
  ativo           boolean not null default false, -- baseline em uso atualmente (só 1 por obra)
  ajustes_manuais jsonb not null default '{}'::jsonb, -- snapshot de OVR no momento do save/congelamento
  ordem           int not null default 0,
  congelado_em    timestamptz,
  created_at      timestamptz not null default now()
);
create index if not exists idx_cenarios_obra on public.cenarios(obra_id);
alter table public.cenarios enable row level security;
drop policy if exists cenarios_member_all on public.cenarios;
create policy cenarios_member_all on public.cenarios for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
