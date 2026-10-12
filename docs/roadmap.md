# Roadmap

O que o Cashly pode ganhar depois da reestruturação, com a assinatura como eixo. O motor de análise dos dados (passado, presente e previsões) está em [analytics.md](analytics.md). Cada item diz o que entrega e a tecnologia; tudo faz parte do Cashly Pro. Os pré-requisitos técnicos estão no [backlog.md](backlog.md).

## Onde o app está

**Já faz:**
- **Registro:** transações com parcelas e status.
- **Divisão:** entre participantes.
- **Planejamento:** categorias com orçamento, tags e perfis.
- **Relatórios:** previsão e saúde financeira (pontuação de 200 a 1.000).
- **Busca.**
- **Inteligência local:** sugestão de categoria (Naive Bayes) e médias.
- **Dados:** iCloud, backup JSON/CSV e backup automático.
- **Lembretes:** de vencimento.
- **Ajustes:** ícones alternativos e tema.

**Ainda não usa:** App Intents, WidgetKit, ActivityKit, Foundation Models, LocalAuthentication nem Core Spotlight. StoreKit 2 e TipKit entraram na fase 8.

**Lacunas de produto:**
- contas e cartões (com fatura);
- recorrências (contas fixas, salário, assinaturas);
- metas de economia;
- acerto de contas entre participantes.

## 1. Assinatura: Cashly Pro (principal)

### Modelo

Teste grátis e depois pago: tudo liberado no período de teste e, depois, o app exige a assinatura. Decidido em 09/10/2026. O app ainda não foi publicado, então não há usuários antigos a preservar.

- **Teste grátis de 7 dias:** oferta introdutória do StoreKit nos dois planos. A Apple controla a elegibilidade (uma vez por Apple ID no grupo de assinatura) e a cobrança começa sozinha no fim do teste, a menos que a pessoa cancele.
- **Depois que expira:** os dados continuam visíveis em modo leitura, e exportar (JSON e CSV) segue liberado. Registrar, editar e os recursos avançados pedem a assinatura. Prender os dados da pessoa gera avaliação ruim e risco na revisão.
- **Sem limite artificial durante o teste:** a pessoa vê o app inteiro, inclusive IA, widgets e relatórios.
- **Itens da loja são à parte:** o que for comprado na loja da Jornada continua da pessoa com ou sem assinatura. Sem o Pro, a Jornada só pausa.

### Planos

- **Cashly Pro Mensal e Cashly Pro Anual**, no mesmo grupo de assinatura (`cashly.pro.monthly`, `cashly.pro.yearly`). O anual tem desconto equivalente de cerca de 40%.
- **Preço:** R$ 14,90/mês e R$ 99,90/ano, ajustável depois no App Store Connect.
- **Compartilhamento Familiar** ligado, porque finanças da casa são um uso natural.
- **Ofertas sem servidor:**
  - códigos de oferta para parcerias e influenciadores;
  - ofertas de reconquista para quem cancelou, configuradas no App Store Connect.

### Implementação (StoreKit 2, sem servidor)

- **Domínio:** `Entitlement` (teste, ativo, expirado) e o protocolo `EntitlementProviding`. As features perguntam `entitlement.canWrite` e não conhecem StoreKit.
- **Target `FeatureStore`:**
  - `StoreModel` (`@Observable`) escuta `Transaction.updates` desde a abertura do app, lê `Transaction.currentEntitlements` e carrega os `Product`.
  - O paywall é a `SubscriptionStoreView(groupID:)` nativa, com o cabeçalho de marketing do Cashly. Botões de restaurar e resgatar código via `.storeButton(.visible, for: .restorePurchases, .redeemCode)`, links de termos e privacidade via `.subscriptionStorePolicyDestination`.
  - `.subscriptionStatusTask(for:)` na raiz mantém o status atualizado.
  - Gerenciar assinatura via `.manageSubscriptionsSheet`.
- **Bloqueio:** um modificador `.requiresPro()` nas ações de escrita mostra o paywall quando não há assinatura ativa. As telas de leitura e a exportação continuam abertas.
- **Ajustes > Cashly Pro:** status, renovação, gerenciar, restaurar e resgatar código.
- **Status para widgets e intents:** uma cópia só de leitura no App Group. A fonte de verdade continua sendo o StoreKit, que valida o JWS no aparelho.
- **Testes:**
  - arquivo `Cashly.storekit` no esquema para o simulador;
  - `SKTestSession` (StoreKitTest) para compra, renovação, expiração e reembolso;
  - testes do estado de assinatura (teste, ativo, expirado, reembolsado) com um provedor falso.
- **Métricas:** pelo App Store Connect (conversão do teste grátis, retenção, cancelamentos). Sem SDK de terceiros, mantendo o selo de privacidade "Dados não coletados".

### Onde o paywall aparece

- **No fim do onboarding**, oferecendo o teste grátis: "Experimente 7 dias grátis".
- **Ao abrir o app sem assinatura ativa**, depois do teste ou de um cancelamento, sobre os dados em modo leitura.
- **Ao tentar registrar ou editar sem assinatura.**
- **Em Ajustes > Cashly Pro**, com status, gerenciar, restaurar e resgatar código.

### O que fica com você

- **No App Store Connect:**
  - aceitar o contrato de apps pagos e preencher dados bancários e fiscais;
  - criar o grupo e os produtos (`cashly.pro.monthly`, `cashly.pro.yearly`) com o teste grátis e textos em pt-BR;
  - capturar a tela do paywall para a revisão;
  - criar testadores sandbox.
- **No `Info.plist`:** preencher `CashlyTermsURL` e `CashlyPrivacyURL`. A diretriz 3.1.2 exige termos (EULA) e privacidade no paywall e na descrição da loja.

## 2. Onboarding e dicas de uso

- **Onboarding de 3 a 4 telas:**
  - o que o Cashly faz;
  - criar o perfil;
  - escolher a moeda e as categorias sugeridas;
  - definir o primeiro orçamento.
  - Opção "Explorar com dados de exemplo" (o `SampleData` já existe).
  - As permissões são pedidas no momento de uso; a de notificações, por exemplo, só ao ligar um lembrete.
- **TipKit** (feito na fase 8.6): dicas contextuais com regras por evento (`CashlyTips.transactionSaved`, `journeyOpened`) e parâmetros, no máximo uma por dia, estado sincronizado pelo iCloud. Dicas de Siri e widgets entram com a fase 9.
- **Ajuda no app:** perguntas frequentes locais e a tela de Novidades, que já existe.

## 3. Integrações com o sistema

**Pré-requisitos:**
- a composição fora da janela ("Serviços fora da janela" no backlog);
- um App Group.

Os widgets leem um retrato pequeno (JSON) que o app grava no App Group a cada mudança. Isso evita mover o banco SwiftData de lugar, o que exigiria migração.

| Recurso | O que entrega | Tecnologia |
| --- | --- | --- |
| Siri e Atalhos | "Adicionar gasto", "Quanto gastei este mês?", "Quanto sobra em Mercado?", "Marcar conta como paga"; aparecem no Spotlight e no app Atalhos sem configuração | App Intents, `AppShortcutsProvider`, `AppEntity` para categoria, tag e perfil |
| Automação do Wallet | Ao pagar com Apple Pay, o Atalhos envia valor e estabelecimento para "Adicionar gasto"; o Cashly oferece o atalho pronto e um passo a passo | Automação "Transação" do Atalhos + App Intent |
| Botão de Ação e Central de Controle | "Novo gasto" num toque | `ControlWidget` + App Intent |
| Widgets | Saldo do mês, orçamento por categoria (`Gauge`), próximos vencimentos, botão "marcar como pago"; Tela Bloqueada, StandBy, Mac e visionOS | WidgetKit, widgets interativos |
| Live Activities | "Fatura vence hoje" com ação de pagar; modo viagem com gasto da tag em tempo real | ActivityKit (atualização local) |
| Notificações | Alertas de orçamento em 80% e 100%, resumo semanal, ações "Marcar paga" e "Adiar 1 dia", vencimento como Sensível ao Tempo | UserNotifications (categorias e ações) |
| Face ID | Bloqueio opcional, modo discreto que oculta valores, desfoque no seletor de apps | LocalAuthentication |
| Spotlight | Transações e categorias pesquisáveis no sistema | `IndexedEntity` |
| Calendário | Vencimentos e parcelas no Calendário | EventKit (acesso só de escrita) |
| Contatos | Escolher participantes dos Contatos | `ContactAccessButton` |
| Comprovante | Fotografar recibo ou nota e preencher valor, data e estabelecimento | Vision (reconhecimento de documento) + Foundation Models |
| Foundation Models | Texto livre vira transação ("almoço 45 com João ontem"); resumo do mês; "Pergunte ao Cashly" com ferramentas que consultam o banco local | `LanguageModelSession`, `@Generable`, `Tool`; fallback quando `SystemLanguageModel.default` não está disponível |
| Importação | Extratos OFX/CSV com sugestão de categoria | `fileImporter` + parser |
| Mac | Adicionar pela barra de menus, atalhos de teclado | `MenuBarExtra`, `keyboardShortcut` |
| Apple Watch | Complicação de saldo e gasto por voz | watchOS + App Intents |

Fora de alcance sem servidor:
- **Open Finance (conexão automática com bancos):** exige um agregador contratado e um backend.
- **FinanceKit:** pelo que a documentação mostrava até agora, não cobre contas brasileiras (a confirmar).

### Etapas da fase 9

| Etapa | Entrega |
| --- | --- |
| 9.1 | Base fora da janela: App Group, `CashlyServices` (composição sem tela, com perfil e banco como parâmetros), retrato JSON do mês gravado no App Group a cada mudança — feita |
| 9.2 | App Intents: "Adicionar gasto", "Quanto gastei este mês?", "Quanto sobra em <categoria>?", "Marcar conta como paga"; `AppEntity` de categoria, tag e perfil; `AppShortcutsProvider`; Spotlight com `IndexedEntity` — feita |
| 9.3 | Widgets: saldo do mês, orçamento por categoria, próximos vencimentos (toque abre a conta no app); Tela Bloqueada, StandBy, Mac e visionOS — feita |
| 9.4 | Central de Controle e Botão de Ação ("Novo gasto"); automação do Wallet com o atalho pronto e o passo a passo — feita |
| 9.5 | Notificações com ação: alertas de orçamento em 80% e 100%, resumo semanal, "Marcar paga" e "Adiar 1 dia", vencimento Sensível ao Tempo |
| 9.6 | Face ID: bloqueio opcional, modo discreto e desfoque no seletor de apps |

## 4. Features de finanças que faltam

- **Recorrências:** contas fixas, salário e assinaturas geram lançamentos e vencimentos sozinhos. O app detecta assinaturas pelo padrão de gastos e mostra "Suas assinaturas: R$ X/mês".
- **Metas (caixinhas):** objetivo, prazo, aporte mensal sugerido e progresso. Ligam-se à gamificação e ao conteúdo.
- **Acerto de contas:** resolve o P1 "Quem pagou" do backlog. Mostra quem deve a quem e gera a cobrança (seção 7).
- **Contas e cartões:** saldo por conta; cartão com fechamento, vencimento e fatura; transferências. É a maior mudança de domínio e anda junto com os itens de competência e `Obligation` do backlog.
- **Patrimônio:** saldos de investimentos informados à mão (sem cotação) e evolução do patrimônio líquido.
- **Dívidas:** plano bola de neve ou avalanche, com data de quitação.

## 5. Jornada e loja

Gamificação (nível, sequência, conquistas, desafios e missões) e a loja de itens comprados com dinheiro real ficam na aba Jornada. Regras, catálogo, preços e construção estão em [gamification.md](gamification.md). Antecipada para a fase 8 em 12/10/2026, junto com a assinatura.

## 6. Conteúdo e investimentos

- **Pílulas de educação financeira:**
  - textos curtos dentro do app, opcionalmente atualizados por um arquivo remoto;
  - trilhas: reserva de emergência, sair das dívidas, 50/30/20, primeiro investimento.
- **Calculadoras com os dados reais:**
  - reserva de emergência pela média de gastos dos últimos meses, o diferencial em relação a calculadoras genéricas;
  - juros compostos;
  - quanto guardar por mês para uma meta;
  - CDI contra poupança, com Selic, CDI e IPCA da API pública do Banco Central (SGS, gratuita) ou digitados.
- **Dicas a partir dos dados:** por exemplo, "Delivery subiu 30% em relação à sua média". Usam estatística local e, quando disponível, texto do Foundation Models.
- **Cuidado regulatório:** recomendar ativos específicos é atividade regulada pela CVM (analista ou consultor credenciado). O app fica em educação e simulação, com o aviso "não é recomendação de investimento". Parcerias com corretoras só depois de análise jurídica.

## 7. Compartilhamento de dados

- **Relatório do mês** como imagem ou PDF, com `ImageRenderer` + `ShareLink`.
- **Cobrança de divisão:**
  - mensagem pronta com o valor e um Pix Copia e Cola gerado no aparelho (BR Code estático com a chave Pix da pessoa);
  - lembrete para cobrar de novo.
- **Orçamento da casa compartilhado:**
  - compartilhamento do CloudKit (`CKShare`) com parceiro ou família.
  - **Investigar antes:** se o SwiftData já expõe o banco compartilhado. Se não, a parte compartilhada usa `NSPersistentCloudKitContainer` ou `CKSyncEngine`. É o item de maior risco desta lista.
- **Exportação para o contador:** o CSV já existe; falta filtrar por período e categoria.

## 8. Easter eggs

Pequenas surpresas que reforçam a identidade retrô sem atrapalhar o uso. Todas ficam no aparelho, não afetam dados e não aparecem em fluxos de conferência ou importação.

- **Ícones secretos:** um ícone extra no seletor que só aparece depois de algo raro, como fechar três meses seguidos dentro do orçamento ou tocar sete vezes no ícone atual em Ajustes › Ícone.
- **Pontuação 1.000:** ao atingir a pontuação máxima, o número brilha com um efeito de SF Symbols e uma vibração curta, uma vez por mês.
- **Datas:** confete no primeiro dia do ano, morcegos passando no Início no dia 31 de outubro, neve discreta no dia 25 de dezembro.
- **Valores curiosos:** registrar exatamente R$ 42,00 ou R$ 1.234,56 mostra uma mensagem divertida no rodapé da transação.
- **Cifrão do ícone:** segurar o cifrão na tela de boas-vindas faz ele girar como uma moeda.
- **Créditos escondidos:** puxar a tela "Sobre" além do fim revela os créditos no estilo de fim de filme.
- **Regras:** respeitar "Reduzir movimento" e "Reduzir transparência", nunca bloquear uma ação, aparecer no máximo uma vez por sessão e ter um interruptor em Ajustes › Desenvolvimento para testar.

## Ordem sugerida

| Fase | Entrega | Por quê |
| --- | --- | --- |
| 8 | **Jornada, loja e Cashly Pro:** motor de gamificação e eventos duráveis, aba Jornada, StoreKit com itens e planos, paywall com teste grátis, modo leitura após expirar, Ajustes › Cashly Pro, onboarding, TipKit (etapas em [gamification.md](gamification.md)) | É a prioridade e vai ao ar com o primeiro lançamento |
| 9 | **Captura rápida:** App Group, composição compartilhada, App Intents, automação do Wallet, Central de Controle, widgets, notificações com ação, Face ID e modo discreto | Registrar rápido é o que mantém a pessoa no app depois do teste |
| 10 | **Finanças essenciais:** recorrências, metas, acerto de contas com Pix | Fecha as lacunas que concorrentes já cobrem |
| 11 | **Inteligência:** Foundation Models (texto livre, resumo, perguntas), comprovante, relatório em PDF, Live Activities | Diferencial que justifica o preço |
| 12 | **Engajamento:** conteúdo e calculadoras (que entram na loja como itens), dicas pelos dados, easter eggs | Retenção e renovação |
| 13 | **Expansão:** contas e cartões com fatura, orçamento compartilhado, importação OFX, Apple Watch, Mac na barra de menus | Maior esforço e risco de domínio |
