-- ============================================================
-- Equipe típica dimensionada por MACRO-GRUPO.
--
-- Hoje a equipe típica é cadastrada por serviço e acompanha as equipes
-- ativas semana a semana. Em frentes como OAE isso não descreve a obra:
-- a mesma equipe responde por todos os serviços do grupo e permanece
-- mobilizada do início do primeiro serviço ao término do último.
--
-- Guarda, por obra:
--   { "OAE": { "ativo": true,
--              "crew": [ { "resourceId": "...", "qty": 2,
--                          "mob": 12, "demob": 48 } ] } }
--
-- ativo = true faz os serviços daquele macro-grupo PARAREM de contar a
-- equipe típica própria: quem conta é a equipe do grupo.
-- mob/demob são semanas de calendário (opcionais) que cortam as pontas
-- da permanência; sem elas vale a janela do macro-grupo inteira.
--
-- O macro-grupo de cada serviço fica em servicos.grupo (migração 29).
-- ============================================================

alter table public.obras add column if not exists equipe_macro jsonb;

comment on column public.obras.equipe_macro is
  'Equipe típica por macro-grupo (servicos.grupo): {grupo: {ativo, crew:[{resourceId,qty,mob,demob}]}}';
