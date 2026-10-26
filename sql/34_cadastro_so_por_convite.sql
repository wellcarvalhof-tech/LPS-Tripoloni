-- ============================================================
-- Cadastro só por convite.
--
-- Até aqui qualquer pessoa que abrisse o endereço do app podia clicar em
-- "Criar conta" e ter uma conta no banco. Ela não via obra nenhuma (a RLS
-- cuida disso), mas a conta existia, e dava pra criar quantas quisesse —
-- inclusive chamando a API do Supabase direto, sem passar pela tela, já que
-- a chave anônima está no index.html por natureza.
--
-- Agora a criação de conta só passa se o e-mail já tiver sido convidado por
-- um planejador (obra_convites) ou já for membro de alguma obra
-- (obra_membros). O bloqueio é no BANCO, antes da linha nascer em
-- auth.users: vale pro app, pra API e pra qualquer cliente.
--
-- Quem já tem conta não é afetado — a trava é só na criação.
--
-- Como liberar alguém: convide o e-mail em Cadastro → Acessos (é o fluxo
-- normal). Se precisar liberar à mão, basta uma linha em obra_convites.
--
-- Como destravar tudo de novo, se um dia precisar:
--   drop trigger if exists trg_cadastro_so_por_convite on auth.users;
-- ============================================================

create or replace function public.email_liberado_para_cadastro(_email text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.obra_convites where lower(email) = lower(_email))
      or exists (select 1 from public.obra_membros  where lower(email) = lower(_email));
$$;

-- Ninguém chama essa função de fora: ela existe pra trigger. Sem este revoke, qualquer
-- visitante poderia perguntar "fulano@x.com está convidado?" pela API e ir descobrindo
-- e-mails da obra um a um.
revoke all on function public.email_liberado_para_cadastro(text) from public, anon, authenticated;

create or replace function public.tg_cadastro_so_por_convite()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if public.email_liberado_para_cadastro(new.email) then
    return new;
  end if;
  raise exception 'Este e-mail não está convidado. Peça ao planejador da obra para liberar o seu acesso em Cadastro → Acessos.'
    using errcode = 'P0001';
end $$;

drop trigger if exists trg_cadastro_so_por_convite on auth.users;
create trigger trg_cadastro_so_por_convite before insert on auth.users
  for each row execute function public.tg_cadastro_so_por_convite();

-- A trigger que aplica o convite continua rodando depois do insert (migração 14),
-- então quem foi convidado entra já com o papel e as abas que o planejador definiu.
