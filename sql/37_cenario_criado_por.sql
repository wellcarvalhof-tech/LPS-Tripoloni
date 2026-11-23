-- 37 — Quem criou cada cenário
--
-- Por quê: a linha de base é o compromisso da obra. Apagar uma devia ser do desenvolvedor ou
-- de quem a gerou, e até aqui a tabela não guardava quem foi — então não havia como a tela
-- (nem o banco) saber. Esta migração cria a coluna e trava a exclusão no próprio banco, que é
-- onde a regra precisa valer: tela é conveniência, RLS é garantia.
--
-- Linhas antigas ficam com criado_por NULL: ninguém as "criou" do ponto de vista do app, e aí
-- só o desenvolvedor apaga. É o lado seguro do erro.
--
-- Rodar no SQL Editor do Supabase. Pode rodar mais de uma vez sem problema.

alter table public.cenarios
  add column if not exists criado_por uuid references auth.users(id) on delete set null;

comment on column public.cenarios.criado_por is
  'Quem criou o cenário. NULL = criado antes da migração 37; nesse caso só o desenvolvedor apaga.';

-- Índice só pra política não varrer a tabela quando a obra tem muitos cenários.
create index if not exists cenarios_criado_por_idx on public.cenarios(criado_por);

-- ---------------------------------------------------------------------------
-- Exclusão: rascunho segue a regra de sempre (quem edita a obra). Linha de base
-- só sai pelo desenvolvedor ou por quem a gerou.
-- ---------------------------------------------------------------------------
drop policy if exists "cenarios_delete" on public.cenarios;

create policy "cenarios_delete" on public.cenarios
for delete using (
  -- desenvolvedor: apaga qualquer um
  public.has_role(auth.uid(), 'admin')
  or (
    -- precisa, em qualquer caso, ter acesso de escrita à obra
    exists (
      select 1 from public.obra_membros m
      where m.obra_id = cenarios.obra_id
        and m.user_id = auth.uid()
        and coalesce(m.papel,'') in ('planejador','gestor')
    )
    and (
      coalesce(cenarios.tipo,'rascunho') <> 'baseline'   -- rascunho: pode
      or cenarios.criado_por = auth.uid()                -- linha de base: só quem gerou
    )
  )
);

-- Conferência rápida depois de rodar:
--   select id, nome, tipo, revisao, criado_por from public.cenarios order by ordem;
