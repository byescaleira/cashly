# Módulo: CashlyData

## Identidade

- **Tipo**: Data layer (implementação de repositórios via SwiftData + CloudKit)
- **Path**: `CashlyKit/Sources/CashlyData/`
- **Target SPM**: `CashlyData` (`CashlyKit/Package.swift:23-30`)
- **Arquivos Swift**: 8
- **Dependências de target**: `CashlyDomain`
- **Dependências externas**: `Ryze` (`RyzeFoundation`)
- **Linkagem inversa**: `CashlyPresentation`, `CashlyMock`, `CashlyTests`, `Cashly` (app)

## Responsabilidade aparente

Implementação concreta dos `*UseCase` do Domain via SwiftData/CloudKit:

- **`CashlyDataFactory`** (`CashlyDataFactory.swift`): cria o `ModelContainer` com schema explícito (Budget/Category/Transaction/User/Tag/Participant Entities) e configuração CloudKit `private("iCloud.cashly")`. Implementa `CashlyDataFactoryProtocol`. Em erro de inicialização, **`fatalError(error.localizedDescription)`** (linha 39).
- **Actors** (`Actors/`): um `@ModelActor` por entidade:
  - `BudgetActor: BudgetUseCase`
  - `CategoryActor: CategoryUseCase`
  - `TagActor: TagUseCase`
  - `TransactionActor: TransactionUseCase`
  - `UserActor: UserUseCase`
  - `ParticipantActor: ParticipantUseCase`
  - `AdapterActor: AdapterUseCase` — converte `*Entity` em modelos do Domain.

## Padrões internos

- Cada `*Actor` é `@ModelActor`, o que dá acesso a `modelContext` confinado a um isolated context.
- `BudgetActor` declara `let adapter: AdapterUseCase = CashlyDataFactory().makeAdapter()` (linha 14) — ⚠️ instancia uma `CashlyDataFactory` nova por actor; a menos que `ModelContainer` seja idempotente, isso pode criar containers paralelos. Auditar.
- Operações expressas em `Predicate<T>` + `FetchDescriptor` (SwiftData puro). Sem queries SQL custom.

## Observações / dívidas

1. **Acoplamento `BudgetActor → CashlyDataFactory()` concreto** — quebra DI por construtor.
2. **`fatalError` no init do factory** — fail-stop em caso de problema com CloudKit (sem fallback offline).
3. **Sem retry, sem cache, sem migration plan** documentado para mudanças de schema.
4. Sync com CloudKit é "automático" via `cloudKitDatabase: .private(...)` — comportamento offline/conflicting writes não está coberto por testes.

## Cobertura de testes

- `CashlyTests/Actors/BudgetActorTests.swift` — único teste real do projeto. Cobre o BudgetActor (escopo a confirmar).
- Demais actors: 0 testes.
