-- ============================================================
-- Novo perfil de acesso: CONTROLE.
--
-- Mesma mecânica do gestor — edita, mas só nas abas liberadas em "permissoes" —
-- separado só pra organizar quem é quem (ex.: controle de produção/custos).
-- Resumo dos perfis depois desta migração:
--   planejador   -> tudo na obra, inclusive gerenciar acessos
--   gestor       -> edita, só nas abas liberadas
--   controle     -> edita, só nas abas liberadas   (novo)
--   visualizador -> só lê, só nas abas liberadas
--
-- Idempotente: pode rodar de novo.
-- ============================================================

alter table public.obra_membros drop constraint if exists obra_membros_papel_check;
alter table public.obra_membros add constraint obra_membros_papel_check
  check (papel in ('planejador','gestor','controle','visualizador'));

alter table public.obra_convites drop constraint if exists obra_convites_papel_check;
alter table public.obra_convites add constraint obra_convites_papel_check
  check (papel in ('planejador','gestor','controle','visualizador'));

-- quem pode escrever nas tabelas da obra (RLS): planejador, gestor e agora controle
create or replace function public.is_obra_editor(_obra_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.obra_membros m
                  where m.obra_id = _obra_id and m.user_id = auth.uid()
                    and m.papel in ('planejador','gestor','controle'))
         or public.has_role(auth.uid(), 'admin');
$$;

-- o convite passa a aceitar o perfil novo
create or replace function public.convidar_membro(_obra_id uuid, _email text, _papel text, _permissoes jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare uid uuid; em text := lower(trim(_email));
begin
  if not public.is_obra_planejador(_obra_id) then raise exception 'Sem permissão para gerenciar acessos desta obra.'; end if;
  if _papel not in ('planejador','gestor','controle','visualizador') then raise exception 'Perfil inválido.'; end if;
  if em is null or em = '' or position('@' in em) = 0 then raise exception 'E-mail inválido.'; end if;
  select id into uid from auth.users where lower(email) = em limit 1;
  if uid is not null then
    insert into public.obra_membros (obra_id, user_id, papel, permissoes, email)
    values (_obra_id, uid, _papel, coalesce(_permissoes, '[]'::jsonb), em)
    on conflict (obra_id, user_id) do update
      set papel = excluded.papel, permissoes = excluded.permissoes, email = excluded.email;
    delete from public.obra_convites where obra_id = _obra_id and email = em;
    return 'membro';
  else
    insert into public.obra_convites (obra_id, email, papel, permissoes, created_by)
    values (_obra_id, em, _papel, coalesce(_permissoes, '[]'::jsonb), auth.uid())
    on conflict (obra_id, email) do update
      set papel = excluded.papel, permissoes = excluded.permissoes;
    return 'convite';
  end if;
end $$;
