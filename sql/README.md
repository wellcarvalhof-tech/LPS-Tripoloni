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
| `07_add_cenarios.sql` | Colunas novas em `cenarios` (tabela já existia desde o `01`; agora com tipo/revisao/ativo/ajustes_manuais/ordem) | ⚠️ corrigido — rodar de novo |
| `08_add_producao_diaria.sql` | Confirma colunas usadas em `producao_diaria` (tabela já existia desde o `01`) | ⚠️ rodar (seguro repetir) |
| `09_add_pacote_contratual_lote.sql` | Coluna `lotes.pacote_contratual` (obra com vários contratos/lotes, cronograma integrado mas relatório separado) | ⚠️ novo — rodar |
| `10_add_estacas.sql` | Estaqueamento por lote (`lote_estacas`, `estaca_quantidades`, `estaca_apontamentos`) — controle de produção por estaca (corte/aterro/CFT/base…), sem mexer no cronograma | ⚠️ novo — rodar |
| `11_add_apoio_administrativo.sql` | Tabela `apoio_admin` — catálogo de mão de obra/recursos indiretos em 3 níveis (Apoio Administrativo) | ⚠️ novo — rodar |
| `12_add_apoio_alocacao.sql` | Tabela `apoio_alocacao` (quantidade + período por item) | ❌ substituída pela 13 — não precisa rodar |
| `13_add_apoio_config.sql` | Coluna `apoio_admin.config` — composição de funções/equipamentos por item (igual à equipe típica de serviço) | ⚠️ novo — rodar |
| `14_add_acessos.sql` | Acessos por obra: perfis planejador/gestor/visualizador, abas permitidas por membro (`obra_membros.permissoes`), convite por e-mail (`obra_convites` + `convidar_membro()` + trigger em `auth.users`), e RLS que só deixa planejador/gestor escrever. **Quem já era membro continua com acesso** (criador vira planejador; demais viram gestor com todas as abas). | ⚠️ novo — rodar **antes** de usar a tela Acessos |
| `15_add_recurso_aliases.sql` | Coluna `recursos.aliases` — de-para de nomes pra importar o realizado do histograma das abas "Dados EFETIVO DP" / "DADOS Realizado CEQ" da planilha de acompanhamento | ⚠️ novo — rodar antes de usar "Importar DP + CEQ" |
| `16_add_recurso_classe.sql` | Coluna `recursos.classe` — classificação da mão de obra (MOD direta / MOI indireta), usada no filtro do histograma e preenchida sozinha pela importação DP + CEQ | ⚠️ novo — rodar pra usar o filtro MOD/MOI |

Novos arquivos de migração devem ser salvos aqui (não em Downloads), numerados em sequência.
