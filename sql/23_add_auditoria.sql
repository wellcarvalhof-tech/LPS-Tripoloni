-- ============================================================
-- Auditoria: quem alterou o quê e quando.
--
-- Registra INSERT / UPDATE / DELETE das tabelas da obra com o estado antes e depois,
-- direto no banco (trigger) — então pega qualquer alteração, venha do app, da API ou
-- do SQL Editor. O app mostra isso em Cadastro → Histórico de alterações, já com os
-- campos que mudaram destacados.
--
-- Quem lê: planejador da obra e o desenvolvedor (admin). Ninguém escreve à mão: as
-- linhas entram só pela trigger (security definer).
-- ============================================================

create table if not exists public.auditoria (
  id          bigserial primary key,
  obra_id     uuid,
  user_id     uuid,
  email       text,
  tabela      text not null,
  registro_id uuid,
  acao        text not null,
  antes       jsonb,
  depois      jsonb,
  em          timestamptz not null default now()
);
alter table public.auditoria enable row level security;

create index if not exists auditoria_obra_em_idx on public.auditoria (obra_id, em desc);

drop policy if exists auditoria_select on public.auditoria;
create policy auditoria_select on public.auditoria for select to authenticated
  using (public.has_role(auth.uid(),'admin')
         or (obra_id is not null and public.is_obra_planejador(obra_id)));

create or replace function public.tg_auditoria()
returns trigger language plpgsql security definer set search_path = public as $$
declare v_obra uuid; v_id uuid; v_email text;
begin
  if TG_TABLE_NAME = 'obras' then
    v_obra := coalesce(new.id, old.id); v_id := v_obra;
  else
    begin v_obra := coalesce(new.obra_id, old.obra_id); exception when others then v_obra := null; end;
    begin v_id := coalesce(new.id, old.id);            exception when others then v_id := null; end;
  end if;
  select lower(email) into v_email from auth.users where id = auth.uid();
  insert into public.auditoria(obra_id,user_id,email,tabela,registro_id,acao,antes,depois)
  values (v_obra, auth.uid(), v_email, TG_TABLE_NAME, v_id, lower(TG_OP),
          case when TG_OP='INSERT' then null else to_jsonb(old) end,
          case when TG_OP='DELETE' then null else to_jsonb(new) end);
  return coalesce(new, old);
end $$;

-- liga a trigger nas tabelas da obra
do $blk$
declare t text;
begin
  foreach t in array array[
    'obras','lotes','servicos','lote_servico','equipes','servico_precedencias','cenarios',
    'recursos','apontamento_recursos','apoio_admin','apoio_alocacao','producao_diaria',
    'medicoes','restricoes','planos_semanais','compromissos','obra_membros',
    'lote_estacas','estaca_quantidades','estaca_apontamentos'] loop
    if to_regclass('public.'||t) is null then continue; end if;
    execute format('drop trigger if exists trg_auditoria on public.%I;', t);
    execute format('create trigger trg_auditoria after insert or update or delete on public.%I for each row execute function public.tg_auditoria();', t);
  end loop;
end $blk$;

-- Limpeza (opcional): apaga o que tiver mais de 1 ano
--   delete from public.auditoria where em < now() - interval '1 year';
