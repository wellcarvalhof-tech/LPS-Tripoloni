-- ============================================================
-- Cenários e Linhas de Base (baseline) do Tempo-Caminho
-- Cada linha guarda um snapshot dos ajustes manuais (OVR) —
-- um "rascunho" é um what-if; uma "baseline" é uma linha de base
-- congelada (REV00, REV01, ...) usada como previsto de referência
-- na Curva S. Só uma baseline fica "ativa" por obra por vez.
--
-- NOTA: a tabela public.cenarios já existia desde
-- 01_schema_supabase_proprio.sql, só que num formato mínimo
-- (id, obra_id, nome, is_baseline, descricao, created_at) que
-- não é usado pelo app. Este script ADICIONA as colunas que o
-- app realmente usa (com alter table ... add column if not
-- exists), sem mexer nas colunas antigas — funciona tanto se a
-- tabela já existir quanto se for a primeira vez.
-- ============================================================

create table if not exists public.cenarios (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  nome       text not null,
  created_at timestamptz not null default now()
);

alter table public.cenarios add column if not exists tipo text not null default 'rascunho';
alter table public.cenarios add column if not exists revisao text;
alter table public.cenarios add column if not exists ativo boolean not null default false;
alter table public.cenarios add column if not exists ajustes_manuais jsonb not null default '{}'::jsonb;
alter table public.cenarios add column if not exists ordem int not null default 0;
alter table public.cenarios add column if not exists congelado_em timestamptz;

create index if not exists idx_cenarios_obra on public.cenarios(obra_id);
alter table public.cenarios enable row level security;
drop policy if exists cenarios_member_all on public.cenarios;
create policy cenarios_member_all on public.cenarios for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
