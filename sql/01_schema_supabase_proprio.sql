-- ============================================================================
-- LPS TRIPOLONI · Schema completo para o SEU projeto Supabase
-- Rode este arquivo inteiro no SQL Editor do seu projeto (uma vez).
-- Idempotente: pode rodar de novo sem quebrar.
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- 0) PAPÉIS / has_role  (base para a RLS)
-- ----------------------------------------------------------------------------
do $$ begin
  create type public.app_role as enum ('admin','user');
exception when duplicate_object then null; end $$;

create table if not exists public.user_roles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null,
  role       public.app_role not null,
  created_at timestamptz not null default now(),
  unique (user_id, role)
);
alter table public.user_roles enable row level security;

create or replace function public.has_role(_user_id uuid, _role public.app_role)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.user_roles where user_id = _user_id and role = _role);
$$;

drop policy if exists user_roles_self on public.user_roles;
create policy user_roles_self on public.user_roles for select
  using (user_id = auth.uid() or public.has_role(auth.uid(),'admin'));

-- ----------------------------------------------------------------------------
-- ENUMS do domínio
-- ----------------------------------------------------------------------------
do $$ begin create type public.status_restricao   as enum ('aberta','em_tratativa','removida','atrasada'); exception when duplicate_object then null; end $$;
do $$ begin create type public.status_compromisso as enum ('planejado','concluido','nao_concluido','parcial'); exception when duplicate_object then null; end $$;
do $$ begin create type public.tipo_precedencia   as enum ('FS','SS','FF','SF'); exception when duplicate_object then null; end $$;

-- ----------------------------------------------------------------------------
-- 1) CADASTRO BASE
-- ----------------------------------------------------------------------------
create table if not exists public.obras (
  id                uuid primary key default gen_random_uuid(),
  nome              text not null,
  codigo            text,
  rodovia           text,
  km_inicial        numeric,
  km_final          numeric,
  data_inicio       date,
  data_fim_prevista date,
  dias_uteis        int[] not null default '{1,2,3,4,5}',
  feriados          jsonb not null default '[]'::jsonb,
  created_by        uuid default auth.uid(),
  created_at        timestamptz not null default now()
);

create table if not exists public.obra_membros (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  user_id    uuid not null,
  papel      text not null default 'membro',
  created_at timestamptz not null default now(),
  unique (obra_id, user_id)
);

create table if not exists public.lotes (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  nome       text not null,
  ordem      int  not null default 0,
  km_inicial numeric,
  km_final   numeric,
  created_at timestamptz not null default now()
);
create index if not exists idx_lotes_obra on public.lotes(obra_id);

-- Serviços já com as colunas do app (teams, produtividade, lag, config jsonb).
create table if not exists public.servicos (
  id            uuid primary key default gen_random_uuid(),
  obra_id       uuid not null references public.obras(id) on delete cascade,
  nome          text not null,
  unidade       text,
  cor           text,
  ordem         int  not null default 0,
  teams         int  not null default 1,
  produtividade numeric not null default 0,
  lag_semanas   int  not null default 0,
  config        jsonb not null default '{}'::jsonb,
  created_at    timestamptz not null default now()
);
create index if not exists idx_servicos_obra on public.servicos(obra_id);
-- Se a tabela já existir sem essas colunas, garante-as:
alter table public.servicos add column if not exists teams int not null default 1;
alter table public.servicos add column if not exists produtividade numeric not null default 0;
alter table public.servicos add column if not exists lag_semanas int not null default 0;
alter table public.servicos add column if not exists config jsonb not null default '{}'::jsonb;

create table if not exists public.lote_servico (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  lote_id    uuid not null references public.lotes(id) on delete cascade,
  servico_id uuid not null references public.servicos(id) on delete cascade,
  quantidade numeric not null default 0,
  unidade    text,
  created_at timestamptz not null default now(),
  unique (lote_id, servico_id)
);
create index if not exists idx_lote_servico_obra on public.lote_servico(obra_id);

create table if not exists public.equipes (
  id            uuid primary key default gen_random_uuid(),
  obra_id       uuid not null references public.obras(id) on delete cascade,
  servico_id    uuid references public.servicos(id) on delete set null,
  nome          text not null,
  produtividade numeric not null default 0,
  data_inicio   date,
  data_fim      date,
  created_at    timestamptz not null default now()
);
create index if not exists idx_equipes_obra on public.equipes(obra_id);

create table if not exists public.servico_precedencias (
  id             uuid primary key default gen_random_uuid(),
  obra_id        uuid not null references public.obras(id) on delete cascade,
  servico_id     uuid not null references public.servicos(id) on delete cascade,
  predecessor_id uuid not null references public.servicos(id) on delete cascade,
  tipo           public.tipo_precedencia not null default 'FS',
  defasagem_dias int not null default 0,
  created_at     timestamptz not null default now(),
  unique (servico_id, predecessor_id),
  check (servico_id <> predecessor_id)
);
create index if not exists idx_precedencias_obra on public.servico_precedencias(obra_id);

-- ----------------------------------------------------------------------------
-- 2) CRONOGRAMA
-- ----------------------------------------------------------------------------
create table if not exists public.cenarios (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  nome        text not null,
  is_baseline boolean not null default false,
  descricao   text,
  created_at  timestamptz not null default now()
);
create index if not exists idx_cenarios_obra on public.cenarios(obra_id);

create table if not exists public.atividades (
  id            uuid primary key default gen_random_uuid(),
  obra_id       uuid not null references public.obras(id) on delete cascade,
  cenario_id    uuid references public.cenarios(id) on delete cascade,
  servico_id    uuid not null references public.servicos(id) on delete cascade,
  lote_id       uuid not null references public.lotes(id) on delete cascade,
  equipe_id     uuid references public.equipes(id) on delete set null,
  quantidade    numeric not null default 0,
  data_inicio   date, data_fim date, semana_inicio int, semana_fim int, duracao_dias int,
  es date, ef date, ls date, lf date,
  folga_total   int default 0, folga_livre int default 0, critico boolean not null default false,
  created_at    timestamptz not null default now()
);
create index if not exists idx_atividades_obra on public.atividades(obra_id);
create index if not exists idx_atividades_cenario on public.atividades(cenario_id);

-- ----------------------------------------------------------------------------
-- 3) REALIZADO
-- ----------------------------------------------------------------------------
create table if not exists public.medicoes (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  servico_id uuid not null references public.servicos(id) on delete cascade,
  lote_id    uuid references public.lotes(id) on delete cascade,
  data       date not null default current_date,
  quantidade numeric not null default 0,
  percentual numeric, valor numeric,
  created_at timestamptz not null default now()
);
create index if not exists idx_medicoes_obra on public.medicoes(obra_id);

create table if not exists public.producao_diaria (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid not null references public.obras(id) on delete cascade,
  data       date not null default current_date,
  servico_id uuid references public.servicos(id) on delete set null,
  lote_id    uuid references public.lotes(id) on delete set null,
  equipe_id  uuid references public.equipes(id) on delete set null,
  quantidade numeric not null default 0,
  observacao text,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now()
);
create index if not exists idx_producao_obra on public.producao_diaria(obra_id);
create index if not exists idx_producao_data on public.producao_diaria(obra_id, data);

-- ----------------------------------------------------------------------------
-- 4) LAST PLANNER
-- ----------------------------------------------------------------------------
create table if not exists public.restricoes (
  id                 uuid primary key default gen_random_uuid(),
  obra_id            uuid not null references public.obras(id) on delete cascade,
  descricao          text not null,
  servico_id         uuid references public.servicos(id) on delete set null,
  lote_id            uuid references public.lotes(id) on delete set null,
  categoria          text,
  setor              text,
  responsavel        text,
  data_identificacao date not null default current_date,
  data_prazo         date,
  status             public.status_restricao not null default 'aberta',
  created_at         timestamptz not null default now()
);
create index if not exists idx_restricoes_obra on public.restricoes(obra_id);

create table if not exists public.causas_nao_cumprimento (
  id         uuid primary key default gen_random_uuid(),
  obra_id    uuid references public.obras(id) on delete cascade,
  nome       text not null,
  categoria  text,
  created_at timestamptz not null default now()
);

create table if not exists public.planos_semanais (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid not null references public.obras(id) on delete cascade,
  semana_iso  text not null,
  data_inicio date, data_fim date,
  created_at  timestamptz not null default now(),
  unique (obra_id, semana_iso)
);

create table if not exists public.compromissos (
  id                   uuid primary key default gen_random_uuid(),
  obra_id              uuid not null references public.obras(id) on delete cascade,
  plano_id             uuid not null references public.planos_semanais(id) on delete cascade,
  servico_id           uuid references public.servicos(id) on delete set null,
  lote_id              uuid references public.lotes(id) on delete set null,
  descricao            text not null,
  responsavel          text,
  quantidade_prevista  numeric, quantidade_realizada numeric,
  status               public.status_compromisso not null default 'planejado',
  causa_id             uuid references public.causas_nao_cumprimento(id) on delete set null,
  created_at           timestamptz not null default now()
);
create index if not exists idx_compromissos_obra on public.compromissos(obra_id);
create index if not exists idx_compromissos_plano on public.compromissos(plano_id);

-- ----------------------------------------------------------------------------
-- 5) SEGURANÇA (is_obra_member + trigger + RLS)
-- ----------------------------------------------------------------------------
create or replace function public.is_obra_member(_obra_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.obra_membros m where m.obra_id = _obra_id and m.user_id = auth.uid())
         or public.has_role(auth.uid(), 'admin');
$$;

create or replace function public.tg_obra_add_criador()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.obra_membros (obra_id, user_id, papel)
  values (new.id, coalesce(new.created_by, auth.uid()), 'gestor')
  on conflict (obra_id, user_id) do nothing;
  return new;
end; $$;

drop trigger if exists trg_obra_add_criador on public.obras;
create trigger trg_obra_add_criador after insert on public.obras
  for each row execute function public.tg_obra_add_criador();

alter table public.obras                 enable row level security;
alter table public.obra_membros          enable row level security;
alter table public.lotes                 enable row level security;
alter table public.servicos              enable row level security;
alter table public.lote_servico          enable row level security;
alter table public.equipes               enable row level security;
alter table public.servico_precedencias  enable row level security;
alter table public.cenarios              enable row level security;
alter table public.atividades            enable row level security;
alter table public.medicoes              enable row level security;
alter table public.producao_diaria       enable row level security;
alter table public.restricoes            enable row level security;
alter table public.causas_nao_cumprimento enable row level security;
alter table public.planos_semanais       enable row level security;
alter table public.compromissos          enable row level security;

drop policy if exists obras_select on public.obras;
create policy obras_select on public.obras for select using (public.is_obra_member(id));
drop policy if exists obras_insert on public.obras;
create policy obras_insert on public.obras for insert with check (auth.uid() is not null);
drop policy if exists obras_update on public.obras;
create policy obras_update on public.obras for update using (public.is_obra_member(id));
drop policy if exists obras_delete on public.obras;
create policy obras_delete on public.obras for delete using (
  public.has_role(auth.uid(),'admin') or exists (
    select 1 from public.obra_membros m where m.obra_id = obras.id and m.user_id = auth.uid() and m.papel='gestor'));

drop policy if exists membros_select on public.obra_membros;
create policy membros_select on public.obra_membros for select using (public.is_obra_member(obra_id));
drop policy if exists membros_all on public.obra_membros;
create policy membros_all on public.obra_membros for all using (
  public.has_role(auth.uid(),'admin') or exists (
    select 1 from public.obra_membros m where m.obra_id = obra_membros.obra_id and m.user_id = auth.uid() and m.papel='gestor'))
  with check (
  public.has_role(auth.uid(),'admin') or exists (
    select 1 from public.obra_membros m where m.obra_id = obra_membros.obra_id and m.user_id = auth.uid() and m.papel='gestor'));

do $blk$
declare t text;
begin
  foreach t in array array['lotes','servicos','lote_servico','equipes','servico_precedencias','cenarios','atividades','medicoes','producao_diaria','restricoes','planos_semanais','compromissos'] loop
    execute format('drop policy if exists %I_member_all on public.%I;', t, t);
    execute format('create policy %I_member_all on public.%I for all using (public.is_obra_member(obra_id)) with check (public.is_obra_member(obra_id));', t, t);
  end loop;
end $blk$;

drop policy if exists causas_select on public.causas_nao_cumprimento;
create policy causas_select on public.causas_nao_cumprimento for select using (obra_id is null or public.is_obra_member(obra_id));
drop policy if exists causas_write on public.causas_nao_cumprimento;
create policy causas_write on public.causas_nao_cumprimento for all
  using (obra_id is not null and public.is_obra_member(obra_id))
  with check (obra_id is not null and public.is_obra_member(obra_id));

-- ----------------------------------------------------------------------------
-- 6) VIEWS + causas globais padrão
-- ----------------------------------------------------------------------------
create or replace view public.vw_ppc_semanal as
select p.id as plano_id, p.obra_id, p.semana_iso, p.data_inicio, p.data_fim,
  count(c.*) as total,
  count(*) filter (where c.status='concluido') as concluidos,
  round(100.0*count(*) filter (where c.status='concluido')/nullif(count(c.*),0),1) as ppc_pct
from public.planos_semanais p
left join public.compromissos c on c.plano_id = p.id
group by p.id, p.obra_id, p.semana_iso, p.data_inicio, p.data_fim;

create or replace view public.vw_curva_s as
select m.obra_id, m.data, sum(m.quantidade) as qtd_dia,
  sum(sum(m.quantidade)) over (partition by m.obra_id order by m.data) as qtd_acumulada
from public.medicoes m
group by m.obra_id, m.data;

insert into public.causas_nao_cumprimento (obra_id, nome, categoria) values
 (null,'Falta de projeto / detalhamento','projeto'),
 (null,'Projeto com erro ou incompatibilidade','projeto'),
 (null,'Falta de material','material'),
 (null,'Atraso de fornecedor / suprimento','material'),
 (null,'Falta de mão de obra','mao_obra'),
 (null,'Baixa produtividade da equipe','mao_obra'),
 (null,'Equipamento indisponível / quebrado','equipamento'),
 (null,'Condição climática (chuva)','clima'),
 (null,'Licença / liberação ambiental','licenca'),
 (null,'Desapropriação / interferência','licenca'),
 (null,'Pré-requisito (tarefa anterior não concluída)','planejamento'),
 (null,'Reprogramação / decisão gerencial','planejamento'),
 (null,'Interferência de terceiros / concessionárias','externo'),
 (null,'Outros','outro')
on conflict do nothing;

-- ============================================================================
-- FIM — schema pronto. Habilite Auth (Email) no painel: Authentication → Providers.
-- Para o login funcionar sem confirmar e-mail: Authentication → Providers → Email
-- → desligue "Confirm email".
-- ============================================================================
