# Jornada e loja

A Jornada transforma o hábito de cuidar do dinheiro em progresso visível: nível, sequência, conquistas e desafios. A Loja reúne os planos do Cashly Pro e itens comprados com dinheiro real (ícones, personalização, ajudas de jogo e conteúdo financeiro). Este documento define as regras, o catálogo e a construção. Decidido em 12/10/2026.

## Princípios

1. **Progresso vem dos dados, não de cliques.** Nível, sequência e conquistas são calculados a partir das transações, dos orçamentos e de um registro pequeno de eventos. O cálculo é uma função pura e testada, igual em todos os aparelhos.
2. **Nunca incentivar gastar.** A sequência conta dias em que a pessoa *acompanhou* as finanças, não dias em que gastou: registrar algo ou marcar "hoje não gastei" mantém a sequência. Nenhum XP depende do valor gasto.
3. **Sem pagar para vencer.** O que se compra é cosmético, conteúdo ou conveniência. Nível e conquistas não se compram.
4. **Privado.** Tudo fica no aparelho e no iCloud da pessoa. Sem ranking, sem Game Center, sem terceiros. A Jornada pode ser desligada em Ajustes.
5. **Comemorar com discrição.** Efeitos de SF Symbols, `sensoryFeedback` e uma chuva curta de moedas e notas, respeitando "Reduzir movimento".

## Onde fica

Uma aba própria, **Jornada** (ícone `trophy`), proeminente no fim da barra, no lugar da antiga Busca (removida em 12/10/2026):

- **Topo:** título do nível em chip, "Nível n" em número grande e o XP total; dentro do grupo, "x de y XP" na cor de destaque, o XP que falta e a barra do nível entre os chips do nível atual e do próximo (preenche ao abrir); embaixo, o próximo título com uma barra de 5 segmentos (os níveis do título atual) e "faltam n níveis". Sem anel circular: o app usa barras lineares.
- **Sequência:** chama cheia que pulsa quando o dia está feito (contorno quando ainda não está), contagem com troca numérica animada e a situação do dia logo abaixo; faixa dos últimos sete dias (chama = acompanhado, floco = coberto por congelamento, círculo vazio = perdido, tracejado = hoje ainda não) que entra em cascata; recorde e congelamentos lado a lado; a próxima marca (7, 30, 100 ou 365 dias, as conquistas de constância) com barra e os dias que faltam; e o botão "Hoje não gastei".
- **Missões da semana:** três tarefas curtas, renovadas toda segunda; chip "feitas/3" no título, recompensa "+25 XP" sempre visível (cinza até concluir, oliva depois), barra que preenche ao abrir com "feito/meta", troca de símbolo e vibração ao concluir, e "Missões novas em n dias" no rodapé.
- **Desafios:** sem desafio, a seção sugere três tipos (um fácil, um médio e um difícil, entre os liberados, trocando a cada semana) com símbolo na cor do tema, frase, chips de duração, dificuldade e XP, e o botão "Ver todos os desafios". O seletor é uma folha com pilha de navegação: no topo, quantos desafios existem e a regra de custo; depois uma seção por tema (Gastar menos, Limites, Hábitos, Orçamentos) com cabeçalho colorido e frase do tema, e cada tipo com símbolo, título, regra, chips e, quando não dá para começar, o motivo com cadeado; no fim, os desafios recentes (concluídos com "+XP", perdidos com "Perdido"). Tocar num tipo abre a configuração: herói com o símbolo animado, título, regra e chips; cartão de categoria (escolhida ou, em "Corte no maior gasto", a maior do mês passado) com o gasto do mês passado e, no teto, o campo de valor com a sugestão; cartão de resumo na cor do tema com a meta ("Até R$ 640 com Restaurantes neste mês"), o período ("De hoje até domingo, 18 de out."), a recompensa, o custo (grátis, troca ou sem trocas), o aviso de que encerra o desafio atual e o bloqueio; e o botão "Começar desafio" (ou "Obter trocas", que abre o item da loja na própria folha). O desafio ativo mostra símbolo e XP na cor do tema, a frase com a meta, a barra, os dias que faltam e a legenda da medida do tipo (dias sem gasto, dias acompanhados, gastos etiquetados, "R$ x de R$ y", nota…); nos desafios de gasto a barra ganha o marcador do período e o ritmo (do mês ou da semana).
- **Conquistas:** barra geral de desbloqueadas, as três mais próximas (bloqueadas, não secretas, por progresso) com barra, "x de y" e XP, e uma grade por grupo (Primeiros passos, Constância, No azul…) com a contagem de cada grupo; bloqueadas em silhueta, as começadas tingidas na cor do nível com uma barrinha, e secretas como "?". A folha de detalhe segue o padrão dos guias (título e critério, medalhão animado em SwiftUI, até três linhas com estado, recompensa e dica, e "Concluído" com uma ação que leva à tela certa).
- **Comemoração** (refeita em 15/10/2026): folha no padrão de guia (`GuideSheet` + `GuidePage`), com título e frase em cima, a medalha animada da conquista (`AchievementMedallion`) ou a do nível (`LevelMedallion`, número sobre o degradê), chip "+XP" só quando há XP e "Continuar"; vibração de sucesso e chuva curta de moedas e notas no fundo da folha (`MoneyRainView`, `Canvas`, 60 peças por 2,5 s: moedas douradas girando no eixo vertical com o cifrão só de frente, notas verdes balançando); sem chuva com "Reduzir movimento".
- **Loja:** os dois planos no alto e as vitrines (destaques do mês, ícones, personalização, ajudas, conteúdo). Toque abre o item; "Ver loja" mostra tudo.

No iPhone deitado e no iPad, a aba usa o `AdaptiveList` como as outras.

## Mecânicas

### XP e níveis

| Ação | XP | Limite |
| --- | --- | --- |
| Registrar uma transação | 10 | 10 por dia |
| Primeiro acompanhamento do dia (registro ou "hoje não gastei") | 5 | 1 por dia |
| Criar o orçamento de uma categoria no mês | 30 | 1 por categoria e mês |
| Fechar o mês com pontuação de saúde ≥ 895 (nível saudável, dentro do orçado) | 200 | 1 por mês |
| Fechar o mês com pontuação 1.000 | +100 | 1 por mês |
| Concluir um guia | 20 | 1 por guia |
| Concluir uma missão da semana | 25 | 3 por semana |
| Concluir um desafio | 75 a 300 | conforme o desafio |
| Desbloquear uma conquista | 50 a 500 | conforme o nível da conquista |

- Apagar uma transação tira o XP dela, porque o XP é recalculado dos dados. Isso evita criar e apagar para subir.
- **Níveis:** passar do nível *n* para o *n + 1* pede `50 × n × (n + 1)` XP acumulado (nível 2 com 100, nível 3 com 300). São 50 níveis, com títulos a cada 5: Iniciante, Organizado, Planejador, Estrategista, Investidor, Mestre, Lenda (e variações até o 50).
- Subir de nível mostra uma folha curta de comemoração e pode liberar um item (por exemplo, uma moldura de avatar).

### Sequência

- Conta dias seguidos com acompanhamento: pelo menos uma transação registrada naquele dia ou o toque em "Hoje não gastei".
- **Congelamento:** cobre um dia sem acompanhamento e é usado sozinho. A pessoa ganha 1 por mês ao manter a sequência por 14 dias e pode comprar mais na loja.
- **Recuperar sequência:** até 48 h depois de perder, por compra na loja. O motor guarda a última sequência perdida (`Streak.restorable`) e a seção só oferece o botão enquanto ela vale.
- **Trocas de desafio:** o primeiro desafio começado no mês é grátis; cada começo a mais no mesmo mês gasta uma troca (`GameProgress.rerolls`). Sem troca, o botão mostra cadeado e abre o item na loja.
- Marcos de 7, 30, 100 e 365 dias viram conquistas.

### Conquistas

Cerca de 40, em grupos e com níveis bronze, prata e ouro:

- **Primeiros passos:** primeira transação, categoria, orçamento, tag, divisão e backup (a de importação saiu em 15/10/2026, quando importar virou Pro).
- **Constância:** sequência de 7, 30, 100 e 365 dias.
- **No azul:** mês no nível saudável (≥ 895); 3, 6 e 12 meses seguidos; pontuação 1.000.
- **Volume:** 100, 500, 1.000 e 5.000 transações.
- **Organização:** 5 tags em uso; um orçamento para cada categoria no mês; todos os guias concluídos.
- **Juntos:** 10 e 50 despesas divididas.
- **Cashly Pro** (15/10/2026): 1 mês (bronze), 6 meses (prata), 1 ano e 2 anos (ouro) de Pro acumulado, teste grátis incluído e com pausas no meio. Só medalha, sem XP (nível não se compra), e fora das "próximas conquistas". É a única diferença da Jornada entre grátis e Pro.
- **Secretas:** registrar exatamente 42,00 ou 1.234,56; registrar em 31/10 ou em 1/1; registrar às 4h44. Ligam-se aos easter eggs do roadmap.

Conquistas não dão itens de presente: a ideia do ícone "Ouro" para 365 dias de sequência caiu em 15/10/2026, quando a coleção Ouro virou exclusiva do Cashly Pro.

### Desafios

A pessoa escolhe um desafio ativo por vez. São 16 tipos em quatro temas, com duração de fim de semana, semana (sete dias a partir de hoje) ou mês, três níveis de dificuldade e XP de 75 a 300. Tudo sai dos dados que o app já tem e é recalculado a cada leitura; nada é gravado além do código do desafio.

| Tema | Tipo (código) | Regra | Duração | Dif. | XP |
| --- | --- | --- | --- | --- | --- |
| Gastar menos | Fim de semana sem gastos (`noSpendWeekend`) | Nenhum gasto no sábado e no domingo; começado no meio da semana, vale o próximo fim de semana; no domingo, só o domingo | Fim de semana | Fácil | 75 |
| Gastar menos | Três dias tranquilos (`quietDays`) | Três dias acompanhados e sem nenhum gasto; conclui assim que chega a três | Semana | Fácil | 100 |
| Gastar menos | Semana sem… (`noSpendWeek`) | Nenhum gasto numa categoria | Semana | Médio | 100 |
| Gastar menos | Fim de semana mais leve (`weekendLighter`) | Média diária de sábado e domingo menor que a dos dias úteis (sem gasto no fim de semana também vale) | Semana | Médio | 150 |
| Limites | Abaixo da sua média (`belowAverage`) | Gastar até a média semanal dos 28 dias anteriores | Semana | Médio | 150 |
| Limites | Teto (`cap`) | Até um valor numa categoria no mês | Mês | Médio | 150 |
| Limites | Menos que o mês passado (`lessThanLastMonth`) | Categoria abaixo do mês anterior | Mês | Médio | 150 |
| Limites | Corte no maior gasto (`cutBiggest`) | Maior categoria do mês passado com 20% a menos | Mês | Difícil | 250 |
| Hábitos | Sete dias de registro (`trackWeek`) | Acompanhar todos os dias | Semana | Fácil | 75 |
| Hábitos | Semana etiquetada (`tagWeek`) | Todo gasto com etiqueta, pelo menos três | Semana | Fácil | 100 |
| Hábitos | Registro no mesmo dia (`sameDay`) | Todos os dias acompanhados e nenhum gasto da semana registrado depois do dia em que aconteceu | Semana | Médio | 150 |
| Hábitos | Todo dia (`everyDay`) | Acompanhar todos os dias até o fim do mês | Mês | Difícil | 300 |
| Orçamentos | Planeje cada categoria (`planEveryCategory`) | No fim da semana, toda categoria com gasto no mês tem orçamento | Semana | Fácil | 75 |
| Orçamentos | Semana no orçamento (`weeklyBudget`) | Gastar até 7/dias do mês do total orçado | Semana | Médio | 125 |
| Orçamentos | Mês no azul (`blueMonth`) | Terminar no nível saudável (≥ 895) | Mês | Difícil | 200 |
| Orçamentos | Todos os orçamentos no azul (`allBudgetsBlue`) | Nenhuma categoria orçada passa do valor | Mês | Difícil | 250 |

- **Código.** O evento `challengeStarted` guarda `tipo|categoria|limite`. Os cinco tipos antigos mantêm o mesmo código e o mesmo XP; códigos desconhecidos são ignorados.
- **Avaliação.** `ChallengeRun` calcula o período (`Challenge.Kind.period`), a situação (ativo com progresso, concluído, perdido, abandonado) e a medida (`ChallengeMeasure`: valor, alvo e unidade). Os de limite perdem assim que passam do alvo; os de contagem (dias tranquilos) concluem ao chegar ao alvo; os demais se decidem no fim do período. Conta o gasto com data dentro do período até o fim do dia de hoje (um gasto lançado para mais tarde hoje já conta), no fuso do aparelho; a meia-noite seguinte ao período já fica de fora.
- **Bloqueios.** `ChallengeHints` (no `GameProgress`) diz o que falta para cada tipo: categoria, semanas de histórico, gasto no mês passado, orçamento no mês, etiqueta ou "todas as categorias já têm orçamento". Também traz a média mensal por categoria (base da sugestão do teto, 90% arredondado para baixo), o gasto do mês passado por categoria, a média semanal e a parte semanal do orçamento.
- **Recentes.** `GameProgress.recentChallenges` lista os cinco últimos concluídos ou perdidos, do mais novo para o mais antigo.

Desafios temáticos extras (Natal no azul, Férias planejadas, Volta às aulas) vêm em pacotes da loja.

### Missões da semana

Três por semana, sorteadas de forma determinística pela semana e pelo perfil (o mesmo resultado em todos os aparelhos). Exemplos: registrar 5 transações, revisar os orçamentos, usar uma tag, conferir a previsão do mês, fazer um backup.

### Por perfil

O Cashly tem vários perfis por aparelho. A Jornada (XP, sequência, conquistas, desafios) é de cada perfil. As compras pertencem ao Apple ID e valem para todos os perfis do aparelho.

## Loja

### Regras

- Itens são compras no app com dinheiro real: **não consumíveis** para o que é permanente e **consumíveis** para ajudas de jogo.
- O que foi comprado é da pessoa para sempre e funciona com ou sem assinatura. Desde 15/10/2026 a Jornada é igual com ou sem o Pro (ver [subscription.md](subscription.md)), e ícones, cores e conteúdos comprados continuam usáveis.
- Compartilhamento Familiar ligado nos não consumíveis.
- Botão "Restaurar compras" na loja e em Ajustes › Cashly Pro.
- Itens sem conteúdo pronto (molduras, comemorações e sons) ficam com `isAvailable = false` e fora das vitrines até existirem; os produtos já estão no App Store Connect e no `Cashly.storekit`.
- Os preços abaixo estão em reais, já revisados para cima em 12/10/2026 (mais que o dobro da primeira proposta). Os valores finais saem dos níveis de preço do App Store Connect.

### Catálogo

**Planos**

| Item | Tipo | Produto | Preço |
| --- | --- | --- | --- |
| Cashly Pro Mensal | assinatura | `cashly.pro.monthly` | R$ 14,90/mês, 7 dias grátis |
| Cashly Pro Anual | assinatura | `cashly.pro.yearly` | R$ 99,90/ano, 7 dias grátis |

**Ícones do app.** Clássico e Cores continuam grátis.

| Item | Produto | Preço |
| --- | --- | --- |
| Moda, Países, Esportes, Anos 80, Verão, Carnaval, Festa Junina, Halloween, Natal (um pacote cada) | `cashly.icons.<coleção>` | R$ 11,90 |
| Todos os ícones, inclusive os que vierem depois | `cashly.icons.all` | R$ 44,90 |

**Avatares ilustrados** (ipaslogo.com; Gatos, Cachorros e Floresta são grátis)

| Item | Produto | Preço |
| --- | --- | --- |
| Fazenda, Oceano, Aves, Selva, Bichinhos, Fantasia (uma seção de 20 a 24 cada) | `cashly.avatars.<seção>` | R$ 9,90 |
| Todos os avatares, inclusive as seções que vierem depois | `cashly.avatars.all` | R$ 34,90 |

**Personalização**

| Item | Produto | Preço |
| --- | --- | --- |
| Cores metálicas de destaque (Ouro, Prata, Bronze, Cobre) | `cashly.accent.metallic` | R$ 11,90 |
| Cores neon de destaque | `cashly.accent.neon` | R$ 11,90 |
| Molduras de avatar (6) | `cashly.avatar.frames` | R$ 11,90 |
| Sons e vibrações (caixa registradora ao salvar, moeda ao concluir) | `cashly.sounds` | R$ 7,90 |

**Ajudas de jogo** (consumíveis)

| Item | Produto | Preço |
| --- | --- | --- |
| 3 congelamentos de sequência | `cashly.freeze.3` | R$ 6,90 |
| 10 congelamentos de sequência | `cashly.freeze.10` | R$ 16,90 |
| Recuperar sequência perdida (até 48 h) | `cashly.streak.restore` | R$ 9,90 |
| 3 trocas de desafio | `cashly.challenge.reroll` | R$ 4,90 |

**Conteúdo financeiro.** Entra na loja conforme o conteúdo da fase 12 fica pronto; a primeira versão da loja sai com ícones, personalização e ajudas.

| Item | Produto | Preço |
| --- | --- | --- |
| Trilhas: Reserva de emergência, Sair das dívidas, 50/30/20, Primeiro investimento | `cashly.trail.<tema>` | R$ 22,90 cada |
| Todas as trilhas | `cashly.trails.all` | R$ 59,90 |
| Calculadoras avançadas (aposentadoria, financiamento SAC e Price, CET) | `cashly.calculators` | R$ 19,90 |
| Modelos de orçamento (universitário, família, casal, autônomo/MEI, viagem): criam categorias e orçamentos prontos | `cashly.templates` | R$ 11,90 |
| Pacotes de desafios temáticos | `cashly.challenges.<tema>` | R$ 9,90 |

**Outras ideias**

- **Gorjeta ao desenvolvedor:** "Pague um café", em três valores consumíveis (`cashly.tip.small`, `.medium`, `.large`: R$ 9,90, R$ 19,90 e R$ 49,90). Simples, comum na App Store e sem efeito no app além de um agradecimento.
- **Cofrinho, o mascote:** um porquinho que evolui com a sequência e o nível e veste acessórios comprados na loja. Esforço maior; fica para depois da primeira versão.
- **Retrospectiva do ano ("Cashly Wrapped"):** resumo anual compartilhável. Sugestão: incluir no Pro, porque ajuda na renovação anual.
- **Skins de widget:** vitrines para os widgets da fase 9.
- **XP em dobro por uma semana:** deixado de fora de propósito, porque vende progresso, o que vai contra o princípio 3.

## Construção

### Camadas

| Peça | Onde | O que faz |
| --- | --- | --- |
| `CashlyGame` | target novo, depende de `CashlyDomain` e `CashlyAnalytics` | Motor puro: `GameSnapshot` (transações, orçamentos, saúde por mês, eventos), `GameEngine.progress(_:) -> GameProgress` com XP, nível, sequência, conquistas, missões e desafios. Testado como o `CashlyAnalytics`. |
| Domínio | `CashlyDomain` | `GameEvent` (marcou "não gastei", concluiu guia, escolheu desafio, usou congelamento, compra creditada), `ShopItem`, `ShopCatalog`, `Entitlement` (teste, ativo, expirado), `EntitlementProviding` e `PurchaseProviding`. |
| Dados | `CashlyData` | Schema V4 com `GameEventEntity` sincronizada pelo CloudKit, mais o repositório e a origem do `GameSnapshot`. Resolve o item "Eventos de negócio duráveis" do backlog. |
| Loja | target `FeatureStore` | `StoreModel` (`@Observable`): produtos, compra, `Transaction.updates`, `currentEntitlements` (itens e Pro), crédito único de consumíveis pelo `transaction.id` e restauração. Paywall com `SubscriptionStoreView` (`PaywallScreen`). |
| Jornada | target `FeatureJourney` | `JourneyModel` e as telas: topo, missões, desafios, conquistas e loja. |
| Bloqueios | `FeatureCore` | `ProAccess` no ambiente (`\.pro`): `canWrite` e `perform { }` nas ações de escrita abrem o paywall sem assinatura; as rotas de editor são barradas na `MainScreen`. `ShopAccess` no ambiente (`\.shop`) diz o que já é da pessoa e abre a folha do item (`CashlyNavigation.shopItem`). Ícones e cores metálicas/neon (`PremiumColor`) mostram cadeado e abrem o item na loja. |

### Testes

- **Motor:** XP, níveis, sequência com congelamento, limites diários, conquistas e desafios contra retratos fixos.
- **Loja:** `StoreModel` com um `StoreClient` falso para compra, restauração, reembolso e crédito único de consumíveis; o `Cashly.storekit` tem todos os produtos para o simulador. `SKTestSession` só funciona em testes hospedados pelo app (ver backlog).
- **Entitlement:** teste, ativo, expirado e reembolsado com um provedor falso.

### O que fica com você (App Store Connect)

- Contrato de apps pagos, dados bancários e fiscais.
- Grupo de assinatura com os dois planos e o teste de 7 dias.
- Os produtos da tabela acima, com nomes e descrições nos 10 idiomas, capturas para a revisão e o Compartilhamento Familiar nos não consumíveis.

## Ordem de entrega

| Etapa | Entrega |
| --- | --- |
| 8.1 | Motor `CashlyGame`, eventos duráveis (schema V4) e testes — feita |
| 8.2 | Aba Jornada: nível, sequência, "hoje não gastei", missões, desafios, conquistas e comemorações — feita |
| 8.3 | StoreKit: `StoreModel`, catálogo, `Cashly.storekit`, compras, restauração e crédito de consumíveis — feita |
| 8.4 | Loja na Jornada e itens bloqueados nos Ajustes (ícones e cores) — feita |
| 8.5 | Cashly Pro: `Entitlement`, paywall, teste grátis, modo leitura, Ajustes › Cashly Pro, oferta no fim do onboarding — feita |
| 8.6 | TipKit e documentação — feita |
