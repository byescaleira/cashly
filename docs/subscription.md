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

## Card do Cashly Pro por tela (`ProShowcaseSection`)

Desde 15/10/2026 (pedido do usuário), o convite é **por tela, não por seção**. Sem Pro, as seções Pro somem (`ProOnly { … }`), sem prévia desfocada, e cada tela que tinha recursos Pro ganha **um** card "Cashly Pro" (`ProShowcaseSection(.home | .data | .intelligence | .claudeCode)`, no `FeatureCore`):

- herói: coroa (`SymbolBadge` preenchido, mostarda, `.badgeXL`, `bounce` ao aparecer), título da tela em `.titleMedium` e uma frase descritiva que começa pelo que continua grátis ("Registrar continua grátis…", "Exportar continua grátis…");
- uma linha por recurso da tela (`ProPitch`): selo mostarda, título e frase do que ele entrega;
- o botão principal "Conhecer o Cashly Pro", que abre o paywall.

| Tela | Onde entra o card | Recursos listados |
| --- | --- | --- |
| Início | logo depois de "Disponível" | nota do mês, projeção, comparação com outros meses, fora do comum, próximos meses, planejado × gasto, tags |
| Ajustes › Dados e Backup | depois de Exportar | backups automáticos (aparelho e iCloud Drive), importar backup e planilha |
| Ajustes › Inteligência | a tela inteira | orçamento inteligente, categorização automática, previsão por tag, aprende só no aparelho |
| Ajustes › Claude Code | a tela inteira | perguntas sobre o dinheiro, análises, importar extratos numa conversa, aprovação de cada conexão |

Com Pro, o card some e as seções voltam.

## Paywall

- A tabela Grátis × Pro passa a mostrar o modelo novo: registrar e editar ✓/✓, Jornada ✓/✓, Widgets, Siri e exportação ✓/✓, Análises e previsões —/✓, Inteligência —/✓, Backups automáticos e importação "Só exportar"/✓, Claude Code —/✓. A linha "Ícones e avatares exclusivos" só entra com a fase 4, quando eles existirem.
- O herói diz o que o Pro soma: "Análises, inteligência e backups além de tudo o que é grátis".
- **Oferta automática:** depois do onboarding e, sem Pro, no máximo uma vez a cada 7 dias na abertura. O resto vem do contexto (cards por tela, cadeados, loja, Ajustes).

## Conquistas de tempo de Pro

- Grupo novo **Cashly Pro** com quatro conquistas: 1 mês (bronze), 6 meses (prata), 1 ano (ouro) e 2 anos (ouro). O tempo é acumulado (teste e assinatura contam; os intervalos são unidos, então um plano trocado não conta em dobro).
- Fonte: `StoreClient.history()` lê `Transaction.all` dos planos; o `StoreModel` calcula os meses cobertos e grava um `GameEvent` `.proMonth` por mês completo no perfil atual, com chave única `pro-month-<n>`. A conquista conta esses eventos, como os créditos da loja.
- Sem XP (nível não se compra) e fora das "próximas conquistas"; a ação "Conhecer o Cashly Pro" na folha só aparece para quem não é Pro.

## Exclusivos

- **Ícones Ouro:** coleção nova `gold` em `AppIcon` (4 ícones `CashlyIconGold*`), sem `ShopItem`; acesso por `PackAccess.pro`, que mostra o chip "Pro" e abre o paywall.
- **Avatares Ouro:** seção nova `gold` em `ProfileIllustration`, 20 bichos dourados do ipaslogo.com escolhidos pela aparência (filhote de leão, raposa, golden retriever, hamster, tigre, shiba, girafa, esquilo, pintinho, lulu, golem âmbar, corgi, patinho, abelha, urso-malaio, feneco, camelo, peixe amarelo, urso-mel e labrador), lista fixa em `design/avatars/select_gold.py`, mesmo acesso `PackAccess.pro`.
- Aparecem na loja? Não como item: o cartão do Pro na loja cita os exclusivos.

## Folha de conquista

`CelebrationScreen` passa para o padrão de guia (como `AchievementDetailScreen`): medalha animada da conquista ou o nível, título, frase, chip de XP e "Continuar". O fundo da folha ganha uma chuva curta de **moedas e notas** (`MoneyRainView`, `Canvas` + `TimelineView`, 2,5 s): moedas douradas girando no eixo Y e notas verdes balançando ao cair. Com Reduzir movimento não há chuva.

## Fases

1. **Portão freemium:** `ProAccess.isPro`, remoção dos bloqueios de escrita e da Jornada pausada, intents, notificações e deep links livres, backups, importação, inteligência e MCP no Pro, paywall novo e oferta semanal. Testes.
2. **Tapume:** `ProCurtain` e aplicação nos componentes. Revisão de design.
3. **Conquistas de tempo de Pro:** histórico do StoreKit, `GameEvent.proMonth`, grupo novo, textos e testes.
4. **Exclusivos:** ícones Ouro, avatares Ouro, `PackAccess.pro` e volta ao padrão ao perder o Pro.
5. **Folha de conquista** com a chuva de moedas e notas.
6. **Docs e verificação:** `decisions.md`, `gamification.md`, `roadmap.md`, `capture.md`, a referência `monetization.md` do apple-sdd, 10 idiomas, build das 3 plataformas, testes e conferência no iPhone.

## Troca de plano e perda do Cashly Pro (18/10/2026)

### Níveis do grupo

O grupo "Cashly Pro" tem dois níveis: **Anual no nível 1** (acima) e **Mensal no nível 2**. Está assim no `Cashly.storekit`; no App Store Connect a ordem ainda precisa ser conferida pela sessão principal com o ok do usuário. `ShopItem.planLevel` repete a ordem no domínio.

- **Mensal → Anual** é upgrade: vale na hora e a Apple reembolsa a parte não usada do mensal, proporcional.
- **Anual → Mensal** é downgrade: o Anual segue até a renovação e o Mensal começa nela (a troca fica agendada no `autoRenewPreference`).
- O app só compra o outro plano do grupo; quem decide e faz a troca é o StoreKit.

### Estado da assinatura

- `StoreClient.subscriptionStatuses()` lê `Product.SubscriptionInfo.status(for:)` do grupo (o ID do grupo vem do `subscriptionGroupID` da última transação de cada plano). Transação e `renewalInfo` passam pelo `VerificationResult`: sem transação verificada o status é descartado; sem `renewalInfo` verificado, os dados de renovação ficam vazios.
- O tipo do domínio é `ProSubscription` (`CashlyDomain`; `SubscriptionStatus` colide com um tipo do StoreKit): estado (`subscribed`, `expired`, `inGracePeriod`, `inBillingRetry`, `revoked`), plano atual, se renova, plano da próxima renovação, data de renovação ou expiração, fim da carência, motivo da expiração e se é teste grátis.
- `StoreClient.statusUpdates` escuta `Product.SubscriptionInfo.Status.updates` (ex.: renovação desligada no Ajustes do sistema) e o `StoreModel` refaz o estado a cada aviso.
- `StoreTransaction.isUpgraded`: transações substituídas por upgrade não contam como plano atual (continuam no tempo de Pro, porque os intervalos são unidos).

### A regra única de "é Pro"

`StoreState.load` (no `FeatureStore`) junta `currentEntitlements` e os status, e é usada pelo `StoreModel.refresh()` e pelo `ProRule.isPro(isEnforced:)`, que agora é o corpo do `CashlyServices.isPro()` (backup automático na abertura). Ordem:

1. flag `pro` desligada → Pro;
2. simulação do desenvolvedor (`StoreOverride`) → o que ela disser;
3. com status do grupo → `ProSubscription.grantsPro(at:)`: assinado até a expiração (com 1 dia de folga se a renovação está ligada, para uma renovação que chega atrasada não derrubar o Pro e resetar ícone e foto), carência até o fim da carência; nova tentativa de cobrança sem carência, expirada e revogada não são Pro;
4. sem status (offline ou nunca assinou) → a transação de assinatura em `currentEntitlements`, sem conferir a data, porque o StoreKit já só devolve assinado ou em carência.

Isso corrige o bug em que a janela mostrava Pro na carência (entitlement presente) mas o `CashlyServices.isPro()` exigia `expirationDate > now` e desligava backup e MCP.

### Expiração com o app aberto, primeiro plano e reembolso

- Depois de cada `refresh()`, o `StoreModel` agenda outro para o fim do acesso (`nextCheck`, fim da carência ou expiração, mais 1 s).
- A `MainScreen` chama `store.refresh()` ao voltar para o primeiro plano.
- Reembolso e revogação chegam por `Transaction.updates` (`handle` termina a transação e refaz o estado).
- Em todos esses casos o `entitlement` deixa de ser ativo, o `ProAccess.isPro` cai e o caminho "ao perder o Pro" roda como antes: `MainScreen` reseta ícone e fotos exclusivos (`dropProIcon`, `dropProPhotos`), o `MCPModel.isPro` desliga o servidor, o backup automático não roda na próxima abertura e as compras da loja ficam (`owned` não depende da assinatura).
- O lembrete do fim do teste é apagado quando o teste deixa de renovar (renovação desligada ou troca de plano).

### Ajustes › Cashly Pro

| Situação | Linha do plano | Extra |
| --- | --- | --- |
| Assinado, renova | "Active" · "Renews on …" | "Switch to Annual" (no Mensal) ou "Switch to Monthly" (no Anual) |
| Renovação desligada | "Active" · "Pro until … (renewal off)" | "Turn On Renewal" · "Keep Cashly Pro after …." (abre o Gerenciar assinatura); sem troca de plano, porque não há próxima renovação |
| Downgrade agendado | "Active" · "Switches to Monthly on …" | sem troca (já agendada) |
| Teste grátis | "Free Trial" · "Trial ends on …" | sem troca (fica no Gerenciar assinatura) |
| Carência | "Active" · "Pro until … while Apple retries the payment" | aviso "Update Payment Method", que abre o Gerenciar assinatura |
| Nova tentativa de cobrança | "On Hold" · "Pro returns once the payment goes through" | o mesmo aviso; sem "Subscribe" nem teste grátis |
| Expirada ou revogada | "Expired" · "Expired on …" | "Subscribe" |

- A troca abre uma confirmação que explica quando vale: no upgrade, "começa hoje" com o preço anual e o reembolso proporcional do mensal; no downgrade, até quando o Anual segue e o preço do Mensal a partir da renovação.
- No macOS o aviso e o Gerenciar assinatura abrem `apps.apple.com/account/subscriptions`.
- Identificadores para as capturas: `pro.switch`, `pro.payment` e `pro.renewal`.
- **Nova tentativa de cobrança fora da tela do Pro:** a pessoa continua assinante. A raiz de Ajustes troca o "Come Back to Cashly Pro" pela linha "Update Payment Method" (`pro.payment`), "Plan and Purchases" mostra "On Hold" e o chip do perfil também (tom de aviso). O `ProAccess` ganha `isOnHold`: os cards "Cashly Pro" por tela dizem "Update Payment Method" e o `present()` abre o Gerenciar assinatura (`CashlyNavigation.isManagingSubscription`) em vez do paywall; a oferta semanal da abertura não aparece; o cartão do Pro na loja mostra "On Hold".
- **Teste grátis só para quem nunca assinou:** `trialDays(for:)` devolve nada quando há qualquer status de assinatura, inclusive nos cards do paywall.
- **Ask to Buy aprovado** pelo `Transaction.updates` limpa o `pending` do item.
- **Sem "Expired" no futuro:** o `lapsed()` usa a data de revogação quando houver e ignora datas futuras; sem data passada, o estado é `.none`.
- Texto e lógica ficam no `StoreModel+Subscription` (`planTitle`, `planDetail`, `paymentNotice`, `canSubscribe`, `planSwitch`, `switchPlan()`); a `ProSection` só desenha.

### Simulação do desenvolvedor

Ajustes › Desenvolvedor › Loja ganha quatro estados para as capturas: **Renewal Off** (Anual sem renovar), **Downgrade Scheduled** (Anual com Mensal na renovação), **Grace Period** (Anual na carência por 13 dias) e **Billing Retry** (Anual em nova tentativa, sem Pro). O "Pro" simulado passa a ser Mensal, para mostrar o "Switch to Annual". A simulação monta um `ProSubscription` e o `Entitlement` sai da mesma regra.

### Testes

- `CashlyDomainTests/ProSubscriptionTests`: Pro por estado, folga da renovação, carência, nova tentativa, revogada e expirada, teste grátis, troca agendada, escolha entre vários status e níveis.
- `FeatureStoreTests/ProPlanChangeTests` (com o `FakeStoreClient`): carência é Pro na janela e no `ProRule` (o bug), nova tentativa sem carência não é, revogada e expirada não são, flag e simulação vêm antes do StoreKit, expiração com o app aberto derruba o Pro na data, renovação desligada e reembolso chegam enquanto o `start()` escuta, transação de upgrade é ignorada, upgrade e downgrade com textos e compra, teste sem troca e sem lembrete ao desligar a renovação, e os estados simulados.
- Também cobrem: nova tentativa sem teste grátis, renovação desligada sem troca e com "Turn On Renewal", Ask to Buy aprovado limpando o `pending`, `lapsed()` sem data futura, o chip "On Hold" (`GeneralSettingsTests`) e o `presentPro(isOnHold:)` (`ProAccessTests`).
- Os testes com `SKTestSession` ficam com a frente do StoreKit Testing no Xcode Cloud.
