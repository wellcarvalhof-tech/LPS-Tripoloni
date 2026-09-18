-- ============================================================
-- Acessos por obra: perfis (planejador / gestor / visualizador), abas
-- permitidas por membro, convite por e-mail e RLS que respeita o perfil.
--
--   planejador  -> acesso total à obra (edita tudo, gerencia acessos)
--   gestor      -> edita, mas só nas abas liberadas em "permissoes"
--   visualizador-> só lê, e só nas abas liberadas em "permissoes"
--
-- Quem cria a obra vira planejador. Membros que já existiam: o criador
-- (papel 'gestor' no schema antigo) vira planejador; 'membro' vira gestor
-- com todas as abas (mantém quem já editava editando).
--
-- Convite: o app chama convidar_membro(obra, email, papel, abas). Se o
-- e-mail já tem conta, vira membro na hora; senão fica em obra_convites
-- e é aplicado automaticamente quando a pessoa criar a conta (trigger em
-- auth.users). O e-mail fica copiado em obra_membros pra tela de Acessos
-- mostrar (o cliente não enxerga auth.users).
--
-- RLS: leitura = qualquer membro; escrita = planejador ou gestor. A
-- restrição de abas do gestor é feita na tela (as tabelas não mapeiam
-- 1:1 com abas); o visualizador é bloqueado de escrever no banco mesmo.
-- ============================================================

-- 1) obra_membros: papel novo + abas + e-mail
alter table public.obra_membros add column if not exists permissoes jsonb not null default '[]'::jsonb;
alter table public.obra_membros add column if not exists email text;

update public.obra_membros set papel='planejador' where papel='gestor';
update public.obra_membros set papel='gestor', permissoes='["*"]'::jsonb where papel='membro';

alter table public.obra_membros drop constraint if exists obra_membros_papel_check;
alter table public.obra_membros add constraint obra_membros_papel_check
  check (papel in ('planejador','gestor','visualizador'));

-- preenche o e-mail dos membros já existentes (roda como postgres, que enxerga auth.users)
update public.obra_membros m set email = lower(u.email)
  from auth.users u where u.id = m.user_id and m.email is null;

-- 2) convites pendentes
create table if not exists public.obra_convites (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  email       text not null,
  papel       text not null default 'visualizador' check (papel in ('planejador','gestor','visualizador')),
  permissoes  jsonb not null default '[]'::jsonb,
  created_by  uuid,
  created_at  timestamptz not null default now(),
  unique (obra_id, email)
);
alter table public.obra_convites enable row level security;

-- 3) funções de perfil
create or replace function public.is_obra_planejador(_obra_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.obra_membros m
                  where m.obra_id = _obra_id and m.user_id = auth.uid() and m.papel = 'planejador')
         or public.has_role(auth.uid(), 'admin');
$$;

create or replace function public.is_obra_editor(_obra_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.obra_membros m
                  where m.obra_id = _obra_id and m.user_id = auth.uid() and m.papel in ('planejador','gestor'))
         or public.has_role(auth.uid(), 'admin');
$$;

-- criador da obra vira planejador
create or replace function public.tg_obra_add_criador()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.obra_membros (obra_id, user_id, papel, permissoes, email)
  values (new.id, coalesce(new.created_by, auth.uid()), 'planejador', '["*"]'::jsonb,
          (select lower(email) from auth.users where id = coalesce(new.created_by, auth.uid())))
  on conflict (obra_id, user_id) do nothing;
  return new;
end; $$;

-- 4) convidar por e-mail (só planejador). Retorna 'membro' se já tinha conta, 'convite' se ficou pendente.
create or replace function public.convidar_membro(_obra_id uuid, _email text, _papel text, _permissoes jsonb)
returns text language plpgsql security definer set search_path = public as $$
declare uid uuid; em text := lower(trim(_email));
begin
  if not public.is_obra_planejador(_obra_id) then raise exception 'Sem permissão para gerenciar acessos desta obra.'; end if;
  if _papel not in ('planejador','gestor','visualizador') then raise exception 'Perfil inválido.'; end if;
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

-- ao criar a conta, aplica os convites pendentes daquele e-mail
create or replace function public.tg_aplicar_convites()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.obra_membros (obra_id, user_id, papel, permissoes, email)
  select c.obra_id, new.id, c.papel, c.permissoes, lower(new.email)
    from public.obra_convites c where lower(c.email) = lower(new.email)
  on conflict (obra_id, user_id) do update
    set papel = excluded.papel, permissoes = excluded.permissoes, email = excluded.email;
  delete from public.obra_convites where lower(email) = lower(new.email);
  return new;
end; $$;

drop trigger if exists trg_aplicar_convites on auth.users;
create trigger trg_aplicar_convites after insert on auth.users
  for each row execute function public.tg_aplicar_convites();

-- 5) RLS
-- obras: ler = membro; editar = planejador/gestor; excluir = planejador
drop policy if exists obras_update on public.obras;
create policy obras_update on public.obras for update using (public.is_obra_editor(id));
drop policy if exists obras_delete on public.obras;
create policy obras_delete on public.obras for delete using (public.is_obra_planejador(id));

-- obra_membros: ler = membro; gerenciar = planejador
drop policy if exists membros_all on public.obra_membros;
create policy membros_all on public.obra_membros for all
  using (public.is_obra_planejador(obra_id)) with check (public.is_obra_planejador(obra_id));

-- obra_convites: só planejador
drop policy if exists convites_all on public.obra_convites;
create policy convites_all on public.obra_convites for all
  using (public.is_obra_planejador(obra_id)) with check (public.is_obra_planejador(obra_id));

-- tabelas da obra: derruba todas as policies antigas e recria
--   <tabela>_select : qualquer membro lê
--   <tabela>_write  : planejador/gestor inserem, alteram e apagam (visualizador não)
do $blk$
declare t text; p record;
begin
  foreach t in array array[
    'lotes','servicos','lote_servico','equipes','servico_precedencias','cenarios','atividades',
    'medicoes','producao_diaria','restricoes','planos_semanais','compromissos',
    'recursos','apontamento_recursos','lote_estacas','estaca_quantidades','estaca_apontamentos',
    'apoio_admin','apoio_alocacao'] loop
    if to_regclass('public.'||t) is null then continue; end if;
    for p in select policyname from pg_policies where schemaname='public' and tablename=t loop
      execute format('drop policy if exists %I on public.%I;', p.policyname, t);
    end loop;
    execute format('create policy %I_select on public.%I for select using (public.is_obra_member(obra_id));', t, t);
    execute format('create policy %I_write on public.%I for all using (public.is_obra_editor(obra_id)) with check (public.is_obra_editor(obra_id));', t, t);
  end loop;
end $blk$;

-- causas_nao_cumprimento: obra_id pode ser nulo (causas globais, só leitura)
drop policy if exists causas_select on public.causas_nao_cumprimento;
create policy causas_select on public.causas_nao_cumprimento for select
  using (obra_id is null or public.is_obra_member(obra_id));
drop policy if exists causas_write on public.causas_nao_cumprimento;
create policy causas_write on public.causas_nao_cumprimento for all
  using (obra_id is not null and public.is_obra_editor(obra_id))
  with check (obra_id is not null and public.is_obra_editor(obra_id));
