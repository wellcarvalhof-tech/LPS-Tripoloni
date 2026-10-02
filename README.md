# LPS Tripoloni

Planejamento e acompanhamento de obras rodoviárias — tempo-caminho, linha de balanço,
histograma de recursos, curva S e Last Planner.

O app inteiro é o `index.html` (JS puro, sem build). Os dados ficam no Supabase, com
acesso por conta e RLS por obra.

- **Publicado em:** GitHub Pages, a partir deste repositório.
- **Banco:** as migrações ficam em [`sql/`](sql/) e são rodadas à mão no SQL Editor do
  Supabase, em ordem. Pra saber o que já rodou, use [`sql/CHECK_migracoes.sql`](sql/CHECK_migracoes.sql).

## Instalar no celular

O app é um PWA: abre offline e pode ficar com ícone na tela inicial, sem loja de aplicativos.

1. Abra o endereço do app no Chrome (Android) ou Safari (iPhone).
2. Android: menu **⋮ → Instalar aplicativo**. iPhone: **Compartilhar → Adicionar à Tela de Início**.
3. Pronto — abre em tela cheia, sem barra de navegador.

**Modo campo.** No celular o app mostra as telas de consulta e acompanhamento (Torre de
Controle, Matriz, Linha de Balanço, Histograma, Cenários, Curva S, Medições e as telas do
Last Planner) e uma barra fixa embaixo com os atalhos. As telas de cadastro avisam antes de
abrir — funcionam, mas foram feitas pra monitor.

**Sem sinal.** O app abre pelo retrato da última vez que a obra foi carregada com internet,
em modo só leitura (uma faixa no topo diz de quando é). Cronograma, histograma e cenários
funcionam; as telas que buscam dados na hora (programação semanal, médio prazo, PPC e
medições) precisam de conexão.

## Arquivos

| Arquivo | O que é |
|---|---|
| `index.html` | O app inteiro |
| `manifest.webmanifest` | Dados de instalação do PWA (nome, ícone, cor) |
| `sw.js` | Service worker — guarda o app pra abrir offline |
| `icons/` | Ícones do app instalado |
| `sql/` | Migrações do banco, em ordem |
