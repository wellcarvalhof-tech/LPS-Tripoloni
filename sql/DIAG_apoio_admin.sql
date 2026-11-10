-- ============================================================
-- Diagnóstico: por que a importação do Apoio Administrativo bateu em
-- "duplicate key value violates unique constraint apoio_admin_pkey"?
--
-- Não altera nada — só lê. Rode no SQL Editor do Supabase e me mande o
-- resultado dos três blocos.
--
-- O que estamos procurando: pela migração 11, apoio_admin_pkey é a chave
-- primária da coluna "id", que o app preenche com um uuid novo a cada
-- inserção — e um uuid novo não colide com nada. Então ou a tabela no
-- banco não é a da migração, ou o mesmo item foi gravado duas vezes.
-- ============================================================

-- 1) Quais restrições a tabela tem de verdade, e sobre quais colunas.
--    Se apoio_admin_pkey não aparecer como "PRIMARY KEY (id)", achamos a causa.
select con.conname                                as restricao,
       con.contype                                as tipo,   -- p = primária, u = única
       pg_get_constraintdef(con.oid)              as definicao
from pg_constraint con
join pg_class rel on rel.oid = con.conrelid
join pg_namespace ns on ns.oid = rel.relnamespace
where ns.nspname = 'public' and rel.relname = 'apoio_admin'
order by con.contype, con.conname;

-- 2) O id tem default? Sem o default, uma inserção que não mande id
--    explicitamente tentaria gravar nulo/repetido.
select column_name as coluna, data_type as tipo, is_nullable as aceita_nulo,
       column_default as valor_padrao
from information_schema.columns
where table_schema = 'public' and table_name = 'apoio_admin'
order by ordinal_position;

-- 3) Existe item repetido (mesmo Nível 1+2+3 na mesma obra)? Se existir,
--    a importação pode ter rodado duas vezes antes da correção.
select obra_id, nivel1, nivel2, nivel3, count(*) as vezes,
       array_agg(id) as ids
from public.apoio_admin
group by obra_id, nivel1, nivel2, nivel3
having count(*) > 1
order by vezes desc, nivel1, nivel2, nivel3;
