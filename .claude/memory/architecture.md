# Arquitetura — Estado Real

> Gerado por `project-onboarder` em 2026-05-08. Esta é a arquitetura **observada**, não a desejada.
> O alvo (Clean Architecture descrita em CLAUDE.md original) está documentado em `migration/migration-plan.md`.

## Visão Geral

Cashly é um app de finanças pessoais (orçamentos, transações, categorias, tags, participantes) com sync via CloudKit e features de Intelligence (CreateML) para sugestão de orçamento, classificação automática de categoria e previsão de gasto por tag.

A arquitetura **já segue o espírito de Clean Architecture** (camadas Domain → Data → Presentation → UI separadas como targets SPM independentes), com **Redux/TCA-flavor unidirecional** para o fluxo de estado em vez de MVVM tradicional. **NÃO usa SwiftUI `@Observable`**: usa `@StateObject` + `EnvironmentObject` mais um padrão `Store<Reducer, Middleware>` herdado de `RyzeArchitecture`.

## Estrutura de pastas (observada)

```
cashly/
├── Cashly.xcworkspace/                     # raiz da workspace
├── Cashly/                                 # app (Xcode project shell)
│   ├── Cashly.xcodeproj/
│   └── Cashly/
│       ├── CashlyApp.swift                 # composition root + dispatcher de actions
│       ├── Assets.xcassets/                # AccentColor, AppIcon, CashlyIcon
│       ├── Info.plist
│       └── Cashly.entitlements             # iCloud, APS
└── CashlyKit/                              # toda a lógica vive aqui (SPM)
    ├── Package.swift
    ├── Sources/
    │   ├── CashlyDomain/                   # ⬛ camada Domain
    │   │   ├── Models/                     # structs imutáveis (Budget, Category, Tag, Transaction, User, Participant, Score)
    │   │   ├── Entities/                   # @Model SwiftData (BudgetEntity, ...) — CONVIVE com Domain
    │   │   ├── Use Cases/                  # protocolos *UseCase (BudgetUseCase, ..., AdapterUseCase)
    │   │   ├── Factories/                  # protocolos das factories (CashlyDataFactoryProtocol, CashlyPresentationFactoryProtocol)
    │   │   └── Utils/                      # CashlyError, CashlyKey, CashlyIntelligence
    │   ├── CashlyData/                     # ⬛ camada Data
    │   │   ├── CashlyDataFactory.swift     # cria ModelContainer (CloudKit) e instancia actors
    │   │   └── Actors/                     # @ModelActor por entidade (Budget/Category/Tag/Transaction/User/Participant/Adapter)
    │   ├── CashlyPresentation/             # ⬛ Redux/TCA layer (não MVVM)
    │   │   ├── CashlyPresentation.swift    # typealiases para Ryze* (State/Action/Reducer/Middleware/Store/Routable/...)
    │   │   ├── CashlyPresentationFactory.swift
    │   │   ├── States/                     # MainState, AddXState, FilterState
    │   │   ├── Actions/                    # MainAction, AddXAction, ApplicationAction
    │   │   ├── Reducers/                   # *Reducer: actor, função pura state+action -> state
    │   │   ├── Middlewares/                # *Middleware: actor, side-effects async retornando AsyncStream<Action>
    │   │   ├── Route/                      # MainRoute (enum CashlyRoutable), MainDeeplink (vazio)
    │   │   ├── Extensions/, Utils/         # CashlyDateFormatter, CashlySymbolCategory
    │   ├── CashlyUI/                       # ⬛ camada UI (SwiftUI puro)
    │   │   ├── Screens/                    # *Screen (HomeScreen, MainScreen, IntelligenceScreen, AddXScreen, etc.)
    │   │   ├── Components/                 # CashlyCardView, CashlyChart, CashlyCompareChart, CashlyMenuSelectionView
    │   │   ├── Views/                      # BalanceView, *VariationView, Empty*View, etc.
    │   │   ├── Items/                      # FilterItemView, UserItemView
    │   │   ├── Extensions/, Modifier/
    │   ├── CashlyMock/                     # ⬛ implementações in-memory + previews
    │   │   ├── MockCashlyFactory.swift
    │   │   ├── Actors/                     # Mock*Actor (in-memory, sem SwiftData)
    │   │   ├── Models/                     # fixtures
    │   │   ├── Views/                      # MockModifier para SwiftUI previews (.cashlyPreview())
    │   └── CashlyResource/                 # ⬛ assets/strings/JSON fixtures
    │       ├── Assets/
    │       └── Mocks/                      # MockBudgets.json, MockCategories.json, MockTransactions.json, ...
    └── Tests/
        └── CashlyTests/                    # Swift Testing (@Suite)
            ├── Actors/BudgetActorTests.swift
            └── Common/{CommonTestSuite, CommonScenario, CommonTags}.swift
```

## Diagrama de dependências entre targets

Conforme declarado em `Package.swift`:

```
CashlyDomain          (depende de: Ryze)
   ▲
   │
CashlyData            (depende de: CashlyDomain, Ryze)
   │
   ├─► CashlyPresentation  (CashlyDomain, CashlyData, Ryze)
   │       ▲
   │       │
CashlyMock (CashlyDomain, CashlyData, CashlyPresentation, Ryze, CashlyResource)
           ▲
           │
CashlyUI    (CashlyDomain, CashlyPresentation, CashlyMock, Ryze, CashlyResource)

CashlyResource (Ryze)

CashlyTests   (todos os targets acima)
```

⚠️ Observações sobre a Dependency Rule:
- **CashlyMock depende de CashlyData**: Mocks importam a camada concreta. Isso é justificável porque MockActors substituem `*Actor` reais; o Mock vive como peer da Data. Não viola Clean Architecture *strictly* porque CashlyMock é "test/preview infra", mas é um cheiro.
- **CashlyUI depende de CashlyMock**: `MainScreen()` usa `.cashlyPreview()` no entry point quando rodando no simulator. Acoplamento de produção→preview é não-convencional.
- **CashlyDomain importa Ryze**: viola a regra "Domain depende só de Foundation". `RyzeFoundation` traz tipos como `RyzeError`, `RyzeEntity` que o Domain consome. Domain não importa Apple frameworks UI, mas importa um framework terceiro pesado.

## Padrões em uso (observados)

### Padrão de apresentação: Redux unidirecional (Ryze-flavored)

Não é MVVM. Não é "MV with @Observable". É um Redux/TCA-style baseado em primitivos do Ryze:

- **`CashlyState` = `RyzeState`**: struct imutável, `Sendable`, contém todo o estado da feature
- **`CashlyAction` = `RyzeAction`**: enum de eventos
- **`CashlyReducer` = `RyzeReducer`**: `actor`, função pura `(state, action) async -> state`
- **`CashlyMiddleware` = `RyzeMiddleware`**: `actor`, executa side-effects, retorna `AsyncStream<Action>`
- **`CashlyStore<Reducer, Middleware>` = `RyzeStore`**: `class` `ObservableObject` injetada como `@StateObject` em `CashlyApp` e propagada por `@EnvironmentObject` + também o estado isolado via `@Environment` (ex: `\.mainState`, `\.action`)

**Stores existentes**: `mainStore`, `addCategoryStore`, `addBudgetStore`, `addTransactionStore`, `addUserStore`, `addTagStore` — instanciados em `CashlyApp.swift:25-30` via `CashlyPresentationFactory.shared`.

Dispatch central: `CashlyApp.handler(action: ApplicationAction)` (`CashlyApp.swift:67-78`) faz pattern-match em `ApplicationAction` (sub-enums por feature) e roteia para o store correto.

### Camada de dados: Repository = `@ModelActor` SwiftData

- Cada entidade tem um actor isolado: `BudgetActor`, `CategoryActor`, `TagActor`, `TransactionActor`, `UserActor`, `ParticipantActor`, mais um `AdapterActor` (mapeia `*Entity` → modelo de domínio).
- Cada actor implementa o protocolo correspondente em `CashlyDomain/Use Cases/*UseCase.swift`.
- Persistência via `ModelContainer` único, configurado com **CloudKit private database** (`iCloud.cashly`).
- Mocks (`CashlyMock/Actors/Mock*Actor.swift`) implementam os mesmos `*UseCase` mas in-memory, lendo `MockX.json` de `CashlyResource`.

### Modelo de domínio dual: Model (struct Sendable) ↔ Entity (@Model class)

Padrão consistente: para cada conceito existem **duas** representações:
- `CashlyDomain/Models/Transaction.swift` → `struct Transaction: CashlyEntity, Sendable`
- `CashlyDomain/Entities/TransactionEntity.swift` → `@Model class TransactionEntity`

A tradução é feita pelo `AdapterActor`. Models são imutáveis, atravessam camadas, são `Sendable`. Entities ficam confinadas ao SwiftData/`ModelContext`.

⚠️ Observação: as `*Entity` (com `@Model class`) vivem dentro de `CashlyDomain/Entities/`. Isso significa que **CashlyDomain importa SwiftData** (e CloudKit por consequência), o que é uma violação prática da Dependency Rule (Domain "puro").

### Navegação

- `CashlyRouter<MainRoute>` por feature (intelligenceRouter, categoryRouter, homeRouter, transactionRouter) — todos `MainState`'s próprios.
- `MainRoute` é um `enum CashlyRoutable` com casos para cada destino possível (`.addUser`, `.addCategory`, `.addBudget`, `.addTransaction`, `.addTag`, `.detailCategory`, `.category`, `.transaction`, `.home`, `.intelligence`).
- `MainDeeplink.swift` existe mas está vazio (esqueleto).
- Estilo: `navigationStyle = .push` para todos os casos hoje.
- ⚠️ ambíguo: existem 4 routers separados em `MainState`, mas a lógica que decide qual usar não está documentada. Pode haver duplicação ou intenção de roteamento contextual.

### Injeção de dependência

- **Composition root**: `CashlyApp` + `CashlyPresentationFactory.shared` (singleton `@MainActor`).
- DI **explícita por construtor** dentro dos middlewares (recebem `*UseCase` no init).
- DI **por singleton** no entry-point: `CashlyPresentationFactory.shared` é estático.
- DI **por property default** dentro dos actors: `BudgetActor` declara `let adapter: AdapterUseCase = CashlyDataFactory().makeAdapter()` (`CashlyData/Actors/BudgetActor.swift:14`) — ⚠️ acoplamento concreto a `CashlyDataFactory()` (cria nova ModelContainer? Não — provavelmente reutiliza, mas vale auditar) dentro de cada actor.

### Intelligence (feature recente)

- `CashlyIntelligence` (`CashlyDomain/Utils/CashlyIntelligence.swift`) é enum com 3 modelos: `budgetValue`, `categoryName`, `tagValue`.
- Treina em runtime via `RyzeTabularIntelligence` (CreateML regressor) e `RyzeTextIntelligence` (text classifier), com IDs scoped por usuário (`user.id + "_" + rawValue`).
- `IntelligenceScreen` deixa o usuário disparar treinamento; bloqueado se houver < 50 transações.
- Predições alimentam `MainState.predictedTransactionsAmount` e são consumidas por reducers `AddBudget*`, `AddTransaction*`, etc.

### Erros

- Tipo único `CashlyError: RyzeError` com 3 cases (`onFetch`, `onSave`, `onRemove`) e `description = ""`. ⚠️ erros genéricos, sem informação contextual.
- Não há mapeamento de erros por camada (sem `NetworkError → RepositoryError → UseCaseError → PresentationError`).
- Único ponto de tratamento: `MainAction.error(CashlyError)` que armazena em `MainState.error`.

### Logging / observabilidade

- Nenhum uso de `os.Logger` ou `Logger` detectado.
- Há `CashlySystemMonitorView` (alias de `RyzeSystemMonitor`) na `IntelligenceScreen` — provavelmente ferramenta de monitoring runtime do Ryze.
- Sem `OSSignposter`, sem analytics tracker.

### Acessibilidade & localização

- `defaultLocalization: "pt-BR"` declarado no Package.
- Strings em código aparentam estar em inglês (`"Pending to Receive"`, `"Smart Budget"`, "📊 Transactions: ..."), sem String Catalog detectado.
- Sem `.accessibilityLabel`, `.accessibilityHint` em volume notável (não pesquisado exaustivamente).

## Dívida arquitetural visível (sem juízo de valor — observação)

1. **Single point of failure: dependência única em Ryze**. Toda a stack arquitetural (Store, Reducer, Middleware, Routable, UI components, Intelligence) e até tipos básicos (`RyzeEntity`, `RyzeError`) vêm de Ryze. Trocar de framework é trabalho substancial.
2. **CashlyDomain não é puro**: importa `RyzeFoundation`, `SwiftData`, `RyzeIntelligence`, `SwiftUI` (em `Score.swift` para `Color`). Domain não é testável sem o ecossistema Ryze + Apple.
3. **3 arquivos > 450 linhas em UI**: `AddTransactionScreen.swift` (497), `CashlySymbolCategory.swift` (486 — table de 200+ ícones inline), `HomeScreen.swift` (466). Candidatos a god view.
4. **85 ocorrências de `!` em produção**: maioria provavelmente em `AnyView(...)` ou expressões lógicas, mas merece auditoria. (Sem `try!` nem `print()` — bom sinal.)
5. **Entities com `var` everywhere**: classes `@Model` declaram `public var id`, `public var participants`, etc. — necessário para SwiftData mas significa que mutabilidade vaza. Models (structs) seguem `var` também (não `let`), embora sejam value types.
6. **Default values nas Entities**: `id = ""`, `amount = 0`, `participants = []`. Útil para CloudKit migrations mas pode mascarar bugs (objetos com id vazio são "válidos" no compilador).
7. **`fatalError` em produção**: `CashlyDataFactory.swift:39` (`fatalError(error.localizedDescription)`) e `CashlyKey.swift:29` (`fatalError("🗓️ Failed to extract month from date.")`).
8. **Composition root parcialmente em singleton**: `CashlyPresentationFactory.shared`, `MockCashlyFactory.shared`. Convenção do projeto-alvo proíbe singletons exceto Logger/FeatureFlags.
9. **Sem testes de Reducer/Middleware**: apenas `BudgetActorTests.swift` existe. Camadas Presentation e UI não cobertas.
10. **Zero infra de qualidade**: sem SwiftLint, sem swift-format, sem CI, sem hooks.
11. **`@StateObject` em vez de `@Observable`**: padrão atual usa `ObservableObject` + `@StateObject` (porque `RyzeStore` é classe `ObservableObject`). Convenção-alvo prefere Observation framework.
12. **Discrepância Swift version**: `Package.swift` em swift-tools 6.2, app em `SWIFT_VERSION = 5.0`. Pode causar comportamentos diferentes entre o pacote (modo Swift 6) e o app (modo Swift 5).
