# Migrações SQL — LPS Tripoloni

Rodar em ordem, uma vez cada, no SQL Editor do Supabase (projeto `vmseakjzavkqrkdqtzzp`). Todas são idempotentes (podem rodar de novo sem quebrar).

| Arquivo | O que faz | Status |
|---|---|---|
| `01_schema_supabase_proprio.sql` | Schema completo inicial (obras, servicos, lotes, RLS, etc.) | ✅ já rodado |
| `02_fix_obras_rls.sql` | Corrige a policy de INSERT de `obras` (bug do 403 ovo-e-galinha) | ✅ já rodado |
| `03_add_ajustes_manuais.sql` | Coluna `obras.ajustes_manuais` (ajuste manual do cronograma) | ✅ já rodado |
| `04_add_contrato_obra.sql` | Colunas `obras.cliente`, `valor_contrato`, `aditivos` | ⚠️ confirmar se já rodou |
| `05_add_histograma.sql` | Tabelas `recursos` e `apontamento_recursos` (aba Histograma) | ⚠️ confirmar se já rodou |
| `06_add_categoria_recurso.sql` | Coluna `recursos.categoria` (agrupamento na tabela Realizado) | ✅ já rodado |
| `07_add_cenarios.sql` | Tabela `cenarios` (rascunhos e linhas de base REV00/REV01/... do Tempo-Caminho) | ⚠️ novo — rodar |
| `08_add_producao_diaria.sql` | Tabela `producao_diaria` (lançamentos reais — alimenta o realizado da Curva S) | ⚠️ novo — rodar |

Novos arquivos de migração devem ser salvos aqui (não em Downloads), numerados em sequência.
