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
| `17_add_admin_desenvolvedor.sql` | Registra a sua conta como **desenvolvedor (admin global)**: enxerga e edita todas as obras, inclusive as criadas por outras pessoas. Troque o e-mail no topo do arquivo antes de rodar. | ⚠️ novo — rodar com o seu e-mail |
| `18_limita_criacao_de_obras.sql` | Só desenvolvedor (ilimitado) e planejador (uma obra do zero) podem criar obra; gestor e visualizador não criam | ⚠️ novo — rodar depois da 17 |
| `19_add_realizado_terceiro.sql` | Coluna `apontamento_recursos.quantidade_terceiro` — parcela de terceiros dentro do realizado (total = próprio + terceiro); preenchida pela coluna Locador na importação CEQ | ⚠️ novo — rodar pra separar próprio × terceiro |
| `20_add_linha_balanco.sql` | Coluna `obras.linha_balanco` — estudo de linha de balanço (lotes, atividades, início, duração e ritmo), independente do Tempo-Caminho | ⚠️ novo — rodar pra usar a tela Linha de Balanço |
| `21_add_perfil_controle.sql` | Novo perfil **Controle** (edita só nas abas liberadas, igual ao gestor) nos membros, convites e na RLS | ⚠️ novo — rodar pra usar o perfil Controle |
| `22_add_presenca.sql` | Tabela `presenca` — mostra quem está usando o app agora (obra e tela), com sinal de vida a cada minuto | ⚠️ novo — rodar pra ver quem está online |
| `23_add_auditoria.sql` | Tabela `auditoria` + triggers nas tabelas da obra — registra quem alterou o quê e quando (antes/depois), lido em Cadastro → Histórico de alterações | ⚠️ novo — rodar pra ter o histórico |
| `24_programacao_semanal.sql` | Campos novos nos `compromissos` (grupo, etapa, lote final, detalhamento, origem, ordem) — Programação Semanal com sugestões do Tempo-Caminho e da Linha de Balanço | ⚠️ novo — rodar pra usar a Programação Semanal |
| `25_fix_views_security_invoker.sql` | Põe `security_invoker` nas views `vw_ppc_semanal` e `vw_curva_s` — sem isso elas ignoravam a RLS e mostravam dados de todas as obras (aviso crítico do Advisor) | ⚠️ novo — rodar pra fechar a falha |
| `26_restricoes_acompanhamento.sql` | Restrições com código (R-001), prazo original, data de conclusão, histórico de revisões e status `cancelada` — base do acompanhamento e do dashboard de IRR/TMD/TMR | ⚠️ novo — rodar pra usar o Médio Prazo |
| `27_restricoes_pacote_local.sql` | Campos livres `pacote` e `local` nas restrições — o que a planilha da obra já traz e não cabia em serviço/lote | ⚠️ novo — rodar pra importar a planilha de restrições |
| `28_restricoes_data_impacto.sql` | Separa `data_impacto` (quando atrapalha a obra, base do prazo e do IRR) da `data_prazo` (previsão de remoção, revisável) | ⚠️ novo — rodar junto com a 26 e a 27 |
| `29_estacas_geometria.sql` | Largura, volumes de projeto e espessura por estaca, "não se aplica" e código/EAP do serviço — base da importação do controle de produção | ⚠️ novo — rodar pra importar os informes de produção |

Pra saber **o que já rodou neste banco**, cole `CHECK_migracoes.sql` no SQL Editor do Supabase: ele lista cada migração com rodou/falta, sem alterar nada.

Novos arquivos de migração devem ser salvos aqui (não em Downloads), numerados em sequência.
