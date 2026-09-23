-- ============================================================
-- Perfil DESENVOLVEDOR (admin global do sistema).
--
-- Quem tiver esse papel enxerga e edita TODAS as obras, inclusive as criadas por
-- outras pessoas, e nunca depende de estar em obra_membros. As funções de segurança
-- que a RLS usa já consideram isso desde o schema inicial:
--   is_obra_member / is_obra_editor / is_obra_planejador  ->  ... or has_role(auth.uid(),'admin')
-- Faltava só registrar o seu usuário como admin — é o que este arquivo faz.
--
-- COMO RODAR: troque o e-mail abaixo pelo da SUA conta (a que você usa pra entrar no
-- app) e execute no SQL Editor do Supabase. Pode rodar de novo sem problema.
-- Pra dar o mesmo poder a outra pessoa depois, é só rodar de novo com o e-mail dela
-- (pense bem: esse perfil vê e apaga qualquer obra).
-- ============================================================

do $$
declare
  _email text := 'well.carvalhof@gmail.com';   -- <<<<<< troque aqui se a sua conta for outra
  _uid   uuid;
begin
  select id into _uid from auth.users where lower(email) = lower(trim(_email)) limit 1;
  if _uid is null then
    raise exception 'Nenhuma conta com o e-mail % . Crie/entre com essa conta no app antes de rodar este arquivo.', _email;
  end if;

  insert into public.user_roles (user_id, role)
  values (_uid, 'admin')
  on conflict do nothing;

  raise notice 'Perfil desenvolvedor (admin) concedido a % (%).', _email, _uid;
end $$;

-- Confere quem é admin hoje:
--   select u.email, r.role from public.user_roles r join auth.users u on u.id = r.user_id;

-- Pra REMOVER o perfil de alguém:
--   delete from public.user_roles r using auth.users u
--    where u.id = r.user_id and lower(u.email) = lower('email@dapessoa') and r.role = 'admin';
