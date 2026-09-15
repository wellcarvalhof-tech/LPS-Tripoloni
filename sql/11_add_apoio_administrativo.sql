-- ============================================================
-- Apoio Administrativo — estrutura de mão de obra e recursos indiretos
-- da obra (gerência, QSMS, engenharia, produção, unidade industrial...),
-- em 3 níveis de classificação (ex.: "INDIRETO ADMINISTRATIVO" >
-- "1. Administrativo" > "RECURSOS HUMANOS"). É um cadastro/catálogo,
-- separado dos Serviços/Lotes — não entra no cálculo do cronograma.
-- ============================================================

create table if not exists public.apoio_admin (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  nivel1     text not null,
  nivel2     text,
  nivel3     text not null,
  ordem      int  not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_apoio_admin_obra on public.apoio_admin(obra_id);
alter table public.apoio_admin enable row level security;
drop policy if exists apoio_admin_member_all on public.apoio_admin;
create policy apoio_admin_member_all on public.apoio_admin for all
  using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));
