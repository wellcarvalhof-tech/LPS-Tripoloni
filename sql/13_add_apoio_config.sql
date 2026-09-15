-- ============================================================
-- Substitui a ideia da migração 12 (apoio_alocacao: quantidade fixa +
-- período por item). O jeito certo é igual à "Equipe típica do
-- serviço": cada item de Nível 3 do Apoio Administrativo recebe uma
-- composição de funções/equipamentos com quantidade — mesma lógica de
-- servicos.config->crew, só que guardada aqui em apoio_admin.config.
-- A tabela apoio_alocacao (migração 12) não é mais usada pelo app —
-- pode rodar essa migração mesmo sem ter rodado a 12 antes.
-- ============================================================

alter table public.apoio_admin add column if not exists config jsonb not null default '{}'::jsonb;
