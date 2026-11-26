-- 39 — Sugestões de melhoria
--
-- Por quê: quem usa o sistema todo dia é quem vê o que falta, e hoje isso se perde em conversa
-- de corredor. A tela de sugestões guarda o pedido junto com a obra e a tela de onde ele saiu,
-- que é o contexto sem o qual metade dos pedidos não se entende depois.
--
-- Quem escreve vê e apaga o que é seu. O desenvolvedor vê tudo e muda o estado. Qualquer membro
-- da obra lê as sugestões dela — ler o que os outros já pediram evita cinco pedidos iguais.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

create table if not exists public.sugestoes (
  id          uuid primary key default gen_random_uuid(),
  obra_id     uuid references public.obras(id) on delete cascade,
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  autor_nome  text,
  tela        text,
  titulo      text not null,
  detalhe     text,
  status      text not null default 'nova',
  resposta    text,
  created_at  timestamptz not null default now()
);

comment on table  public.sugestoes          is 'Sugestões de melhoria escritas por quem usa o sistema.';
comment on column public.sugestoes.tela     is 'Tela de onde a sugestão saiu — o contexto do pedido.';
comment on column public.sugestoes.status   is 'nova | analisando | feita | recusada';
comment on column public.sugestoes.resposta is 'O que o desenvolvedor respondeu.';

create index if not exists sugestoes_obra_idx on public.sugestoes(obra_id, created_at desc);
create index if not exists sugestoes_user_idx on public.sugestoes(user_id);

alter table public.sugestoes enable row level security;

-- Ler: o que é seu, ou o que é da obra em que você está. Desenvolvedor lê tudo.
drop policy if exists sugestoes_select on public.sugestoes;
create policy sugestoes_select on public.sugestoes for select using (
  user_id = auth.uid()
  or public.has_role(auth.uid(),'admin')
  or (obra_id is not null and public.is_obra_member(obra_id))
);

-- Escrever: em nome próprio, e só isso.
drop policy if exists sugestoes_insert on public.sugestoes;
create policy sugestoes_insert on public.sugestoes for insert with check (user_id = auth.uid());

-- Editar: o autor mexe no texto enquanto ninguém respondeu; o desenvolvedor mexe em tudo
-- (é ele quem muda o estado e responde).
drop policy if exists sugestoes_update on public.sugestoes;
create policy sugestoes_update on public.sugestoes for update using (
  public.has_role(auth.uid(),'admin') or user_id = auth.uid()
);

-- Apagar: quem escreveu, ou o desenvolvedor.
drop policy if exists sugestoes_delete on public.sugestoes;
create policy sugestoes_delete on public.sugestoes for delete using (
  public.has_role(auth.uid(),'admin') or user_id = auth.uid()
);

-- Conferência depois de rodar:
--   select id, titulo, status, tela, created_at from public.sugestoes order by created_at desc;
