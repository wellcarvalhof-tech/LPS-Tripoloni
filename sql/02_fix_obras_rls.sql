-- ============================================================
-- CORREÇÃO RLS: INSERT de obras (resolve o 403 42501)
-- Causa: a policy de INSERT exigia is_obra_member(id) -> ovo-e-galinha.
-- Fix: INSERT so exige usuario logado; o trigger adiciona o criador
--      como membro, e ai SELECT/UPDATE/DELETE liberam via is_obra_member.
-- Seguro e idempotente. Mexe apenas nas policies da tabela obras.
-- ============================================================

-- 1) coluna created_by com default do usuario logado (para o trigger e auditoria)
alter table public.obras add column if not exists created_by uuid;
alter table public.obras alter column created_by set default auth.uid();

-- 2) garantir RLS ligado
alter table public.obras enable row level security;

-- 3) remover policies antigas de obras (qualquer que seja o estado atual)
drop policy if exists obras_select     on public.obras;
drop policy if exists obras_insert     on public.obras;
drop policy if exists obras_update     on public.obras;
drop policy if exists obras_delete     on public.obras;
drop policy if exists obras_member_all on public.obras;

-- 4) recriar policies corretas
create policy obras_insert on public.obras
  for insert to authenticated
  with check (auth.uid() is not null);

create policy obras_select on public.obras
  for select to authenticated
  using (public.is_obra_member(id));

create policy obras_update on public.obras
  for update to authenticated
  using (public.is_obra_member(id))
  with check (public.is_obra_member(id));

create policy obras_delete on public.obras
  for delete to authenticated
  using (public.is_obra_member(id));

-- 5) grants (redundante com o default do Supabase, mas garante)
grant select, insert, update, delete on public.obras to authenticated;
