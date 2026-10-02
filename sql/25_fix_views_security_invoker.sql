-- ============================================================
-- Corrige o aviso CRÍTICO do Advisor do Supabase: "Security Definer View"
-- nas views public.vw_ppc_semanal e public.vw_curva_s.
--
-- O problema: por padrão, uma view no Postgres roda com os privilégios de QUEM A CRIOU
-- (o dono, normalmente o postgres), e não de quem está consultando. Como a RLS das
-- tabelas de baixo (planos_semanais, compromissos, medicoes) é avaliada como o dono,
-- ela simplesmente não filtra nada: qualquer usuário logado que consultasse essas views
-- veria o PPC e a curva S de TODAS as obras, inclusive das que ele não participa.
--
-- A correção: security_invoker = on faz a view rodar com os privilégios de quem
-- consulta, então a RLS das tabelas de baixo volta a valer normalmente — cada um
-- enxerga só as obras em que é membro.
--
-- Hoje o app não usa nenhuma das duas views (os cálculos de PPC e curva S são feitos
-- no próprio navegador), então rodar isso não muda nada na tela. É só fechar a porta.
-- ============================================================

alter view public.vw_ppc_semanal set (security_invoker = on);
alter view public.vw_curva_s     set (security_invoker = on);

-- Alternativa, se preferir eliminar de vez em vez de corrigir (o app não as usa):
--   drop view if exists public.vw_ppc_semanal;
--   drop view if exists public.vw_curva_s;
