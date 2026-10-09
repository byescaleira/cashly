# Roadmap

O que o Cashly pode ganhar depois da reestruturação, com a assinatura como eixo. Cada item diz o que entrega, a tecnologia e se fica no plano grátis ou no Pro. Os pré-requisitos técnicos estão no [backlog.md](backlog.md).

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

**Ainda não usa:** StoreKit, App Intents, WidgetKit, ActivityKit, TipKit, Foundation Models, LocalAuthentication nem Core Spotlight.

**Lacunas de produto:**
- contas e cartões (com fatura);
- recorrências (contas fixas, salário, assinaturas);
- metas de economia;
- acerto de contas entre participantes.

## 1. Assinatura: Cashly Pro (principal)

### Modelo

O modelo é freemium: o plano grátis cria o hábito de registrar, e o Pro vende **tempo** (captura por IA e leitura de comprovante), **visão** (relatórios completos, previsão e patrimônio), **colaboração** (família) e **personalização**.

Um bloqueio total logo na entrada afasta quem ainda não viu valor, e em finanças o valor só aparece depois de algumas semanas de registro.

**Princípios:**
- **Quem já usa não perde nada:** o que está na versão publicada continua grátis para todos.
- **Fora do paywall:** segurança (Face ID), exportar os próprios dados e registrar gastos (inclusive pela Siri). Esses três itens também puxam engajamento.
- **Lançamento com valor:** a assinatura só vai ao ar com pelo menos dois recursos Pro fortes prontos (por exemplo, IA de texto livre e relatórios completos). Antes disso, a infraestrutura pode existir desligada.

| Área | Grátis | Pro |
| --- | --- | --- |
| Registro | Manual, ilimitado; Siri, Atalhos e automação do Wallet | Texto livre com IA, leitura de comprovante, importação OFX |
| Planejamento | Orçamentos por categoria, recorrências, 1 meta | Metas ilimitadas, orçamento por tag (viagem, evento) |
| Relatórios | Mês atual e anterior | Histórico completo, ano contra ano, previsão, relatório em PDF |
| Inteligência | Sugestão de categoria (atual) | Resumo do mês, perguntas sobre os gastos, detecção de assinaturas |
| Widgets | Saldo do mês (pequeno) | Todos os tamanhos, Tela Bloqueada, Live Activities |
| Família | Participantes e divisão | Orçamento compartilhado da casa via iCloud |
| Personalização | Ícone padrão | Ícones alternativos |
| Engajamento | Gamificação, conteúdo, calculadoras | — |

### Planos

- **Mensal e anual** no mesmo grupo de assinatura. O anual tem desconto equivalente de cerca de 40% e 7 dias grátis (oferta introdutória só no anual, que é onde a retenção compensa).
- **Vitalício (opcional):** compra não consumível de 2,5 a 3 vezes o anual. Atende quem rejeita assinatura.
- **Preço de partida para validar:** R$ 14,90/mês e R$ 99,90/ano. Antes de fechar, comparar com os apps nacionais do segmento e ajustar à grade da App Store.
- **Compartilhamento Familiar** ligado, porque finanças da casa são um uso natural.
- **Ofertas sem servidor:**
  - códigos de oferta para parcerias e influenciadores;
  - ofertas de reconquista para quem cancelou, configuradas no App Store Connect.

### Implementação (StoreKit 2, sem servidor)

- **Domínio:** `ProFeature` (enum dos recursos pagos) e o protocolo `EntitlementProviding`. As features perguntam `entitlements.allows(.aiEntry)` e não conhecem StoreKit.
- **Target `FeatureStore`:**
  - `StoreModel` (`@Observable`) escuta `Transaction.updates` desde a abertura do app, lê `Transaction.currentEntitlements` e carrega os `Product`.
  - O paywall é a `SubscriptionStoreView(groupID:)` nativa, com o cabeçalho de marketing do Cashly. Botões de restaurar e resgatar código via `.storeButton(.visible, for: .restorePurchases, .redeemCode)`, links de termos e privacidade via `.subscriptionStorePolicyDestination`.
  - `.subscriptionStatusTask(for:)` na raiz mantém o status atualizado.
  - Gerenciar assinatura via `.manageSubscriptionsSheet`.
- **Gate contextual:** um modificador `.proFeature(.aiEntry)` mostra o paywall daquele recurso quando a pessoa toca nele.
- **Ajustes > Cashly Pro:** status, renovação, gerenciar, restaurar e resgatar código.
- **Status para widgets e intents:** uma cópia só de leitura no App Group. A fonte de verdade continua sendo o StoreKit, que valida o JWS no aparelho.
- **Testes:**
  - arquivo `Cashly.storekit` no esquema para o simulador;
  - `SKTestSession` (StoreKitTest) para compra, renovação, expiração e reembolso;
  - testes do mapeamento produto → recursos com um provedor falso.
- **Métricas:** pelo App Store Connect (conversão do teste grátis, retenção, cancelamentos). Sem SDK de terceiros, mantendo o selo de privacidade "Dados não coletados".

### Onde o paywall aparece

- No fim do onboarding, pulável ("Começar grátis").
- Ao tocar num recurso Pro, mostrando aquele recurso.
- Em Ajustes > Cashly Pro.
- Nunca durante o registro de um gasto, e sem pop-up recorrente.

### O que fica com você

- **No App Store Connect:**
  - aceitar o contrato de apps pagos e preencher dados bancários e fiscais;
  - criar o grupo e os produtos (`cashly.pro.monthly`, `cashly.pro.yearly`, `cashly.pro.lifetime`) com textos em pt-BR;
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
- **TipKit:**
  - dicas contextuais: deslizar para marcar como pago, usar a Siri, adicionar o widget, dividir um gasto, buscar;
  - regras `#Rule` por evento (por exemplo, sugerir o Atalho depois da 5ª transação manual);
  - status das dicas sincronizado pelo iCloud.
- **Ajuda no app:** perguntas frequentes locais e a tela de Novidades, que já existe.

## 3. Integrações com o sistema

**Pré-requisitos:**
- a composição fora da janela ("Serviços fora da janela" no backlog);
- um App Group.

Os widgets leem um retrato pequeno (JSON) que o app grava no App Group a cada mudança. Isso evita mover o banco SwiftData de lugar, o que exigiria migração.

| Recurso | O que entrega | Tecnologia | Plano |
| --- | --- | --- | --- |
| Siri e Atalhos | "Adicionar gasto", "Quanto gastei este mês?", "Quanto sobra em Mercado?", "Marcar conta como paga"; aparecem no Spotlight e no app Atalhos sem configuração | App Intents, `AppShortcutsProvider`, `AppEntity` para categoria, tag e perfil | Grátis |
| Automação do Wallet | Ao pagar com Apple Pay, o Atalhos envia valor e estabelecimento para "Adicionar gasto"; o Cashly oferece o atalho pronto e um passo a passo | Automação "Transação" do Atalhos + App Intent | Grátis |
| Botão de Ação e Central de Controle | "Novo gasto" num toque | `ControlWidget` + App Intent | Grátis |
| Widgets | Saldo do mês, orçamento por categoria (`Gauge`), próximos vencimentos, botão "marcar como pago"; Tela Bloqueada, StandBy, Mac e visionOS | WidgetKit, widgets interativos | Pequeno grátis, demais Pro |
| Live Activities | "Fatura vence hoje" com ação de pagar; modo viagem com gasto da tag em tempo real | ActivityKit (atualização local) | Pro |
| Notificações | Alertas de orçamento em 80% e 100%, resumo semanal, ações "Marcar paga" e "Adiar 1 dia", vencimento como Sensível ao Tempo | UserNotifications (categorias e ações) | Grátis |
| Face ID | Bloqueio opcional, modo discreto que oculta valores, desfoque no seletor de apps | LocalAuthentication | Grátis |
| Spotlight | Transações e categorias pesquisáveis no sistema | `IndexedEntity` | Grátis |
| Calendário | Vencimentos e parcelas no Calendário | EventKit (acesso só de escrita) | Grátis |
| Contatos | Escolher participantes dos Contatos | `ContactAccessButton` | Grátis |
| Comprovante | Fotografar recibo ou nota e preencher valor, data e estabelecimento | Vision (reconhecimento de documento) + Foundation Models | Pro |
| Foundation Models | Texto livre vira transação ("almoço 45 com João ontem"); resumo do mês; "Pergunte ao Cashly" com ferramentas que consultam o banco local | `LanguageModelSession`, `@Generable`, `Tool`; fallback quando `SystemLanguageModel.default` não está disponível | Pro |
| Importação | Extratos OFX/CSV com sugestão de categoria | `fileImporter` + parser | Pro |
| Mac | Adicionar pela barra de menus, atalhos de teclado | `MenuBarExtra`, `keyboardShortcut` | Grátis |
| Apple Watch | Complicação de saldo e gasto por voz | watchOS + App Intents | Pro (fase final) |

Fora de alcance sem servidor:
- **Open Finance (conexão automática com bancos):** exige um agregador contratado e um backend.
- **FinanceKit:** pelo que a documentação mostrava até agora, não cobre contas brasileiras (a confirmar).

## 4. Features de finanças que faltam

- **Recorrências:** contas fixas, salário e assinaturas geram lançamentos e vencimentos sozinhos. O Pro detecta assinaturas pelo padrão de gastos e mostra "Suas assinaturas: R$ X/mês". Plano grátis.
- **Metas (caixinhas):** objetivo, prazo, aporte mensal sugerido e progresso. Ligam-se à gamificação e ao conteúdo.
- **Acerto de contas:** resolve o P1 "Quem pagou" do backlog. Mostra quem deve a quem e gera a cobrança (seção 7).
- **Contas e cartões:** saldo por conta; cartão com fechamento, vencimento e fatura; transferências. É a maior mudança de domínio e anda junto com os itens de competência e `Obligation` do backlog.
- **Patrimônio:** saldos de investimentos informados à mão (sem cotação) e evolução do patrimônio líquido. Plano Pro.
- **Dívidas:** plano bola de neve ou avalanche, com data de quitação.

## 5. Gamificação

**Pré-requisito:** eventos de negócio duráveis (backlog). Hoje o `CashlyChangeHub` só invalida a tela.

- **Sequência** de dias com registro, com um "congelamento" por semana.
- **Conquistas locais**, por exemplo:
  - primeiro orçamento;
  - mês inteiro dentro do orçamento;
  - 30 dias seguidos;
  - primeira meta concluída;
  - reserva de emergência completa.
- **Desafios mensais** que a pessoa escolhe (semana sem delivery, 52 semanas, teto de lazer).
- **Evolução da pontuação de saúde** (já existe, de 200 a 1.000) com histórico e próximos passos.
- **Celebração discreta:** efeitos de SF Symbols e `sensoryFeedback` ao fechar o mês no azul.
- **Privacidade:**
  - tudo fica no aparelho, e pode ser desligado nos Ajustes;
  - Game Center não é recomendado, porque exporia hábitos financeiros.

## 6. Conteúdo e investimentos

- **Pílulas de educação financeira:**
  - textos curtos dentro do app, opcionalmente atualizados por um arquivo remoto;
  - trilhas: reserva de emergência, sair das dívidas, 50/30/20, primeiro investimento.
- **Calculadoras com os dados reais:**
  - reserva de emergência pela média de gastos dos últimos meses, o diferencial em relação a calculadoras genéricas;
  - juros compostos;
  - quanto guardar por mês para uma meta;
  - CDI contra poupança, com Selic, CDI e IPCA da API pública do Banco Central (SGS, gratuita) ou digitados.
- **Dicas a partir dos dados:** por exemplo, "Delivery subiu 30% em relação à sua média". Usam estatística local e, no Pro, texto do Foundation Models.
- **Cuidado regulatório:** recomendar ativos específicos é atividade regulada pela CVM (analista ou consultor credenciado). O app fica em educação e simulação, com o aviso "não é recomendação de investimento". Parcerias com corretoras só depois de análise jurídica.

## 7. Compartilhamento de dados

- **Relatório do mês** como imagem para compartilhar (grátis) ou PDF (Pro), com `ImageRenderer` + `ShareLink`.
- **Cobrança de divisão:**
  - mensagem pronta com o valor e um Pix Copia e Cola gerado no aparelho (BR Code estático com a chave Pix da pessoa);
  - lembrete para cobrar de novo.
- **Orçamento da casa compartilhado (Pro):**
  - compartilhamento do CloudKit (`CKShare`) com parceiro ou família.
  - **Investigar antes:** se o SwiftData já expõe o banco compartilhado. Se não, a parte compartilhada usa `NSPersistentCloudKitContainer` ou `CKSyncEngine`. É o item de maior risco desta lista.
- **Exportação para o contador:** o CSV já existe; falta filtrar por período e categoria.

## Ordem sugerida

| Fase | Entrega | Por quê |
| --- | --- | --- |
| 8 | **Base da assinatura:** App Group, composição compartilhada, `EntitlementProviding`, `FeatureStore` com paywall, Ajustes > Cashly Pro, onboarding, TipKit | É a prioridade; fica pronta e testada, ainda sem cobrar |
| 9 | **Captura rápida:** App Intents, automação do Wallet, Central de Controle, widgets, notificações com ação, Face ID e modo discreto | Agiliza o registro, que sustenta todo o resto; quase tudo grátis, para atrair usuários |
| 10 | **Finanças essenciais:** recorrências, metas, acerto de contas com Pix | Fecha as lacunas que concorrentes já cobrem |
| 11 | **Pro forte:** Foundation Models (texto livre, resumo, perguntas), comprovante, relatórios completos, PDF, widgets Pro e Live Activities. **A assinatura vai ao ar aqui** | O Pro estreia com valor claro |
| 12 | **Engajamento:** gamificação, conteúdo, calculadoras, dicas pelos dados | Retenção depois da conversão |
| 13 | **Expansão:** contas e cartões com fatura, orçamento compartilhado, importação OFX, Apple Watch, Mac na barra de menus | Maior esforço e risco de domínio |
