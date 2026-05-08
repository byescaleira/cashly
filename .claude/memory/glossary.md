# Glossário — Domínio Cashly

> Gerado por `project-onboarder` em 2026-05-08 a partir de tipos extraídos de
> `CashlyKit/Sources/CashlyDomain/Models/`, `CashlyDomain/Entities/` e enums em `Utils/`.
>
> ⚠️ Definições marcadas com _(precisa revisão)_ foram inferidas de assinaturas/uso e
> precisam ser confirmadas pelo time. Onboarder não inventa significado.

## Convenções deste arquivo

- Termo em **negrito**, seguido de definição curta + arquivo de referência.
- Sinônimos e termos relacionados marcados explicitamente.
- "Model" = struct value-type usado entre camadas. "Entity" = `@Model` SwiftData persistido.

## Termos do domínio (financeiro)

### **User**
Pessoa que usa o app. Identificada por `id: String`, tem `name` e `photo` (URL ou referência).
Computed: `firstName`, `selfFirstName` (forma possessiva, ex: "Rafael's ").
- Model: `CashlyDomain/Models/User.swift`
- Entity: `CashlyDomain/Entities/UserEntity.swift`
- ⚠️ Não confundir com **Participant**: User é o titular; Participant é uma participação de um User numa Transaction específica.

### **Budget** (Orçamento)
Valor planejado de gastos para uma `Category` num determinado mês/data. Tem `amount: Double`, `category: Category`, `date: Int` (provavelmente `yearMonth`), `summary: String`. `user` é derivado de `category.user`.
- Model: `CashlyDomain/Models/Budget.swift`
- Entity: `CashlyDomain/Entities/BudgetEntity.swift`

### **Category** (Categoria)
Grupo de orçamento/transação (ex: "Alimentação", "Transporte"). Tem `id`, `user`, `name`, `color: String` (hex), `icon: String` (SF Symbol name).
- Model: `CashlyDomain/Models/Category.swift`
- Entity: `CashlyDomain/Entities/CategoryEntity.swift`

### **Transaction** (Transação)
Lançamento financeiro individual. Tem `id`, `participants: [Participant]`, `budget: Budget`, `amount: Double`, `date: TimeInterval`, `summary: String`, `status: TransactionStatus`, `splitMode: TransactionSplitMode?`, `splitValue: Double?`, `paymentsPlan: Int?` (parcelas).
- Model: `CashlyDomain/Models/Transaction.swift`
- Entity: `CashlyDomain/Entities/TransactionEntity.swift`

### **TransactionStatus**
Estado de uma transação. Enum `Int`-raw:
- `pendingToReceive = 3` — a receber (azul, ⬇)
- `pendingToPay = 2` — a pagar (laranja, ⬆)
- `settled = 0` — quitado (verde, ✓)
- `canceled = 1` — cancelado (vermelho, ✗)

### **TransactionSplitMode**
Modo de divisão de uma despesa entre participantes. Enum `Int`-raw:
- `equal = 0` — divide igualmente
- `fixedAmount = 1` — valor fixo por participante
- `percentage = 2` — distribui por percentual
- `payerBased = 3` — um paga, outros ficam devendo

### **Tag**
Marcador adicional aplicável a transações (ortogonal a Category). Tem `id`, `user`, `name`, `color`, `icon`. Estrutura idêntica a `Category`.
- Model: `CashlyDomain/Models/Tag.swift`
- Entity: `CashlyDomain/Entities/TagEntity.swift`
- ⚠️ ambíguo — Tag e Category têm a **mesma forma**: a distinção semântica entre os dois precisa ser confirmada pelo time. Hipótese atual: Category é hierarquia primária do orçamento; Tag é cross-cutting/filtragem.

### **Participant**
Participação de um `User` em uma `Transaction`. Tem `id`, `user: User`, `splitMode: TransactionSplitMode`, `splitValue: Double`, `status: TransactionStatus`, `transaction: String` (id da Transaction).
- Model: `CashlyDomain/Models/Participant.swift`
- Entity: `CashlyDomain/Entities/ParticipantEntity.swift`

### **Score**
Pontuação visual (provável uso em "saúde financeira" / dashboard). Tem `title`, `score: Int`, `min/max: Double`, `summary`, `color`. `isEnable` se score está dentro do intervalo.
- `CashlyDomain/Models/Score.swift`
- ⚠️ _(precisa revisão)_ contexto exato de uso: onde Score é apresentado e como é calculado.

### **FilterState**
Estado de filtragem aplicado em telas que listam dados. Tem `startDate`, `endDate?`, sets de `categories`, `tags`, `participants`, `transactionStatuses` selecionados, e `isFilteringByDate: Bool`. Também armazena `allCategories`, `allTags`, `allTransactions` como cache da população disponível para filtrar.
- `CashlyPresentation/States/FilterState.swift`

### **CashlyKey**
Chave composta para identificação de domínio. Cases:
- `.budget(category, date)` — produz `"<category>.<month>"`
- `.category(id)` — produz o id direto
- `CashlyDomain/Utils/CashlyKey.swift`

### **CashlyError**
Erro de domínio único. Cases: `.onFetch`, `.onSave`, `.onRemove`. ⚠️ `description = ""` — não carrega mensagem.
- `CashlyDomain/Utils/CashlyError.swift`

## Termos de Intelligence

### **CashlyIntelligence**
Enum dos modelos de ML disponíveis no app. Cases:
- `budgetValue` — "Smart Budget": prevê valor ideal de orçamento mensal por categoria (regressor tabular)
- `categoryName` — "Automatic Categorization": classifica transação em categoria a partir do `summary` (text classifier)
- `tagValue` — "Tag Spending Prediction": prevê gasto por tag para um mês (regressor tabular)
- `CashlyDomain/Utils/CashlyIntelligence.swift`

### **CashlyIntelligenceModel** / **CashlyPrediction** / **CashlyPredictionResult**
Aliases para `RyzeIntelligenceModel`, `RyzeIntelligencePrediction`, `RyzeIntelligencePredictionResult`. Wrappers de CreateML.

## Termos arquiteturais (alias de Ryze)

Esses não são termos de **negócio**, mas formam a linguagem técnica usada em todo o código:

- **CashlyState / CashlyAction / CashlyReducer / CashlyMiddleware / CashlyStore**: primitivos do padrão Redux/TCA herdado de `RyzeArchitecture`. Ver `architecture.md` para semântica.
- **CashlyView / CashlyHStack / CashlyVStack / CashlyList / ...**: aliases de `RyzeUI` para componentes SwiftUI estilizados.
- **CashlyEntity**: alias de `RyzeEntity` — protocolo base que tipos de domínio adotam (provavelmente exige `Identifiable` + `Codable`, a confirmar).
- **CashlyRoutable / CashlyRouter / CashlyNavigationStyle**: padrão de routing do Ryze.
- **CashlySystemMonitor**: dashboard em runtime (memória, CPU?), aparece em `IntelligenceScreen`.

## Pendências para o time preencher

1. Definir formalmente diferença **Tag vs Category** — hoje têm estrutura idêntica.
2. Confirmar onde **Score** é apresentado e como é calculado.
3. Documentar significado de **`Budget.date: Int`** e **`Transaction.date: TimeInterval`** — pareceriam tipos diferentes para a mesma ideia (data).
4. Definir semântica de **`Transaction.paymentsPlan`** (parcelas? recorrência? prazo?).
5. Resolver: **MainDeeplink** existe vazio — deeplinks planejados? quais URLs?
