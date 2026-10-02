-- ============================================================
-- Restrições: pacote de trabalho e local (texto livre).
--
-- A planilha que a obra já usa tem duas colunas que não cabem no que existia:
--
--   pacote -> "Pacote de Trabalho" (Usina, Pavimento Flexível, Contenções, OAE - Geral…).
--             Quando o nome bate com um serviço cadastrado, a importação também preenche
--             servico_id; quando não bate, o texto fica aqui em vez de se perder.
--   local  -> "Local" (R1000 KM 249, OAE 257, Unidade Industrial, Obra Geral…). É mais fino
--             que o lote e nem sempre corresponde a um — por isso texto livre, com lote_id
--             preenchido só quando o nome casa com um lote cadastrado.
--
-- Os dois são livres de propósito: a obra escreve como escreve, e o histórico importado
-- precisa entrar inteiro, não numa gaveta que só aceita o que o app já conhece.
-- ============================================================

alter table public.restricoes add column if not exists pacote text;
alter table public.restricoes add column if not exists local  text;
