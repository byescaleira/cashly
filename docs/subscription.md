# Cashly Pro freemium (15/10/2026)

Substitui o modelo "teste grátis e depois modo leitura" (decisões de 09/10 e 12/10/2026). O Cashly passa a ser **freemium**: registrar e editar é grátis para sempre e o Pro vende análise, inteligência, segurança dos dados, o Claude Code e itens exclusivos.

## O que é grátis e o que é Pro

| Grátis para sempre | Cashly Pro |
| --- | --- |
| Registrar, editar e excluir transações, categorias, orçamentos, tags e perfis | **Análises do motor** na aba Início: Projeção do mês, Histórico e Incomuns, Futuro, Variação, Tags e Pontuação (e o `run_analysis` do MCP) |
| Resolver conflito de orçamento, converter capturas, Siri, Atalhos, widgets e controles | **Inteligência**: sugestões (botões de raio), tela Inteligência e o que vier (LLM no aparelho) |
| Jornada completa: sequência, desafios, XP, conquistas e loja | **Backup automático**, pasta no iCloud Drive, restaurar backup e importar planilha |
| Aba Início básica: Disponível, Maiores gastos e Resumo do mês | **Claude Code (MCP)**: ligar o servidor e todas as ferramentas |
| Exportar JSON e CSV, apagar tudo, sincronizar pelo iCloud | **Exclusivos** (fase 4): coleção de ícones Ouro e seção de avatares Ouro |
| Itens comprados na loja | Conquistas de tempo de Pro (as demais são iguais para todos) |

- **Os dados nunca ficam presos.** Exportar continua livre (diretriz da Apple e regra do projeto).
- **Planos iguais:** `cashly.pro.monthly` R$ 14,90 e `cashly.pro.yearly` R$ 99,90, os dois com 7 dias grátis.
- **Jornada igual para todos.** Some a "Jornada pausada"; o Pro só acrescenta as conquistas de tempo de assinatura.

## Portão

- `ProPitch` (`FeatureCore`): um caso por componente bloqueado (projeção, outros meses, fora do comum, próximos meses, planejado × gasto, tags, pontuação, inteligência, backup, importar, Claude Code), com seção, título, frase de incentivo, símbolo e cor.
- `ProAccess` (`\.pro`): `isPro` (teste, assinatura ativa ou flag `pro` desligada), `present()` e `perform(_:)` só para ações de recursos Pro. Saem `canWrite`, `Route.requiresPro`, o portão de rotas da `MainScreen`, o de deep links, notificações e App Intents, e o `PausedSection`.
- Fora da janela, `CashlyServices.isPro()` substitui `canWrite()` e vale para o backup automático na abertura e para o MCP.
- **Ao perder o Pro:** o backup automático para (os arquivos ficam, exportar segue livre), o servidor MCP desliga, ícone e foto exclusivos em uso voltam ao padrão (ícone Cores; iniciais na cor sugerida), e o que foi comprado na loja continua.

## Tapume (`ProCurtain`)

`ProCurtainSection(pitch) { conteúdo } preview: { prévia }` no `FeatureCore`. Sem Pro, o componente aparece com as formas reais e sem os valores (`.redacted(reason: .placeholder)` + desfoque, sem toque e escondido do VoiceOver). Por cima da prévia fica o `SymbolBadge` preenchido do recurso, em mostarda; embaixo, título, frase de incentivo do componente e o botão principal "Conhecer o Cashly Pro", que abre o paywall. Cada componente diz o que entrega, por exemplo: Projeção → "Saiba onde o mês vai fechar antes de chegar lá". Com Pro o modificador não faz nada. Com Reduzir transparência a prévia não aparece; fica só o selo do recurso.

Onde entra: as seis seções do motor na Início, a tela Inteligência e os botões de raio (que abrem o paywall), as seções de backup automático, iCloud Drive e backups salvos, as linhas de importar, e a seção do Claude Code nos Ajustes.

## Paywall

- A tabela Grátis × Pro passa a mostrar o modelo novo: registrar e editar ✓/✓, Jornada ✓/✓, Widgets, Siri e exportação ✓/✓, Análises e previsões —/✓, Inteligência —/✓, Backups automáticos e importação "Só exportar"/✓, Claude Code —/✓. A linha "Ícones e avatares exclusivos" só entra com a fase 4, quando eles existirem.
- O herói diz o que o Pro soma: "Análises, inteligência e backups além de tudo o que é grátis".
- **Oferta automática:** depois do onboarding e, sem Pro, no máximo uma vez a cada 7 dias na abertura. O resto vem do contexto (tapumes, cadeados, loja, Ajustes).

## Conquistas de tempo de Pro

- Grupo novo **Cashly Pro** com quatro conquistas: 1 mês (bronze), 6 meses (prata), 1 ano (ouro) e 2 anos (ouro). O tempo é acumulado (teste e assinatura contam; os intervalos são unidos, então um plano trocado não conta em dobro).
- Fonte: `StoreClient.history()` lê `Transaction.all` dos planos; o `StoreModel` calcula os meses cobertos e grava um `GameEvent` `.proMonth` por mês completo no perfil atual, com chave única `pro-month-<n>`. A conquista conta esses eventos, como os créditos da loja.
- Sem XP (nível não se compra) e fora das "próximas conquistas"; a ação "Conhecer o Cashly Pro" na folha só aparece para quem não é Pro.

## Exclusivos

- **Ícones Ouro:** coleção nova `gold` em `AppIcon` (4 ícones `CashlyIconGold*`), sem `ShopItem`; acesso por `PackAccess.pro`, que mostra o chip "Pro" e abre o paywall.
- **Avatares Ouro:** seção nova `gold` em `ProfileIllustration`, 20 bichos dourados do ipaslogo.com escolhidos pela aparência (filhote de leão, raposa, golden retriever, hamster, tigre, shiba, girafa, esquilo, pintinho, lulu, golem âmbar, corgi, patinho, abelha, urso-malaio, feneco, camelo, peixe amarelo, urso-mel e labrador), lista fixa em `design/avatars/select_gold.py`, mesmo acesso `PackAccess.pro`.
- Aparecem na loja? Não como item: o cartão do Pro na loja cita os exclusivos.

## Folha de conquista

`CelebrationScreen` passa para o padrão de guia (como `AchievementDetailScreen`): medalha animada da conquista ou o nível, título, frase, chip de XP e "Continuar". O fundo ganha uma chuva de **moedas e notas** (`MoneyConfettiView`, `Canvas` + `TimelineView`): moedas douradas girando no eixo Y e notas verdes balançando ao cair, por ~3 s. Com Reduzir movimento não há chuva.

## Fases

1. **Portão freemium:** `ProAccess.isPro`, remoção dos bloqueios de escrita e da Jornada pausada, intents, notificações e deep links livres, backups, importação, inteligência e MCP no Pro, paywall novo e oferta semanal. Testes.
2. **Tapume:** `ProCurtain` e aplicação nos componentes. Revisão de design.
3. **Conquistas de tempo de Pro:** histórico do StoreKit, `GameEvent.proMonth`, grupo novo, textos e testes.
4. **Exclusivos:** ícones Ouro, avatares Ouro, `PackAccess.pro` e volta ao padrão ao perder o Pro.
5. **Folha de conquista** com a chuva de moedas e notas.
6. **Docs e verificação:** `decisions.md`, `gamification.md`, `roadmap.md`, `capture.md`, a referência `monetization.md` do apple-sdd, 10 idiomas, build das 3 plataformas, testes e conferência no iPhone.
