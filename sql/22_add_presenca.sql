-- ============================================================
-- Presença: quem está usando o app agora.
--
-- Cada pessoa mantém UMA linha com o último "sinal de vida" (a cada minuto, enquanto
-- estiver com o app aberto), dizendo em que obra e em que tela está. Quem entra vê
-- quem mais está trabalhando.
--
-- Privacidade: você enxerga a sua própria linha, as pessoas que estão numa obra da
-- qual você participa, e o desenvolvedor (admin) enxerga todas. Ninguém escreve na
-- linha de outra pessoa.
-- ============================================================

create table if not exists public.presenca (
  user_id    uuid primary key,
  email      text,
  obra_id    uuid,
  obra_nome  text,
  tela       text,
  visto_em   timestamptz not null default now()
);
alter table public.presenca enable row level security;

drop policy if exists presenca_self_write on public.presenca;
create policy presenca_self_write on public.presenca for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists presenca_select on public.presenca;
create policy presenca_select on public.presenca for select to authenticated
  using (
    user_id = auth.uid()
    or public.has_role(auth.uid(),'admin')
    or (obra_id is not null and public.is_obra_member(obra_id))
  );

create index if not exists presenca_visto_em_idx on public.presenca (visto_em desc);
