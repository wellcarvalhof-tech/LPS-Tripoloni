-- ============================================================
-- Quem pode CRIAR obra:
--   • desenvolvedor (admin global, migração 17) -> quantas quiser;
--   • planejador de alguma obra              -> só UMA obra criada por ele;
--   • gestor / visualizador / conta sem obra -> nenhuma.
--
-- A conta da pessoa vira planejadora da obra que ela criar (trigger tg_obra_add_criador),
-- então a partir da segunda tentativa a policy barra. Se o desenvolvedor apagar a obra
-- que ela criou, ela volta a poder criar uma.
--
-- Tudo é decidido no banco (RLS), não só na tela: mesmo chamando a API direto, a
-- criação é recusada. Idempotente — pode rodar de novo.
-- ============================================================

create or replace function public.pode_criar_obra()
returns boolean language sql stable security definer set search_path = public as $$
  select
    public.has_role(auth.uid(), 'admin')
    or (
      exists (select 1 from public.obra_membros m
               where m.user_id = auth.uid() and m.papel = 'planejador')
      and (select count(*) from public.obras o where o.created_by = auth.uid()) = 0
    );
$$;
grant execute on function public.pode_criar_obra() to authenticated;

-- INSERT de obras passa a exigir a regra acima (antes bastava estar logado).
drop policy if exists obras_insert on public.obras;
create policy obras_insert on public.obras
  for insert to authenticated
  with check (auth.uid() is not null and public.pode_criar_obra());

-- Confere o que a SUA conta pode fazer agora:
--   select public.pode_criar_obra();
