# Módulo: CashlyDomain

## Identidade

- **Tipo**: Domain layer (modelos de domínio + protocolos de use cases)
- **Path**: `CashlyKit/Sources/CashlyDomain/`
- **Target SPM**: `CashlyDomain` (definido em `CashlyKit/Package.swift:23-30`)
- **Arquivos Swift**: 26
- **Dependências de target**: nenhuma (é o nó-folha do grafo)
- **Dependências externas**: `Ryze` (importa `RyzeFoundation`, `RyzeIntelligence`)
- **Linkagem inversa**: importado por `CashlyData`, `CashlyPresentation`, `CashlyUI`, `CashlyMock`, `CashlyResource` (indireto), `CashlyTests`

## Responsabilidade aparente

Concentra TODOS os tipos e protocolos do domínio Cashly:
- **Models** (`Models/`): structs `Sendable` que atravessam camadas — `Budget`, `Category`, `Tag`, `Transaction`, `User`, `Participant`, `Score`.
- **Entities** (`Entities/`): `@Model` SwiftData persistidas — `BudgetEntity`, `CategoryEntity`, `TagEntity`, `TransactionEntity`, `UserEntity`, `ParticipantEntity`.
- **Use Cases** (`Use Cases/`): protocolos `*UseCase` (BudgetUseCase, CategoryUseCase, TagUseCase, TransactionUseCase, UserUseCase, ParticipantUseCase, AdapterUseCase) — todos `Sendable`, métodos `async throws`.
- **Factories** (`Factories/`): protocolos `CashlyDataFactoryProtocol`, `CashlyPresentationFactoryProtocol` que definem como instanciar use cases / stores.
- **Utils**: `CashlyError`, `CashlyKey` (chave composta), `CashlyIntelligence` (catálogo dos modelos ML).

## Sub-pastas

```
CashlyDomain/
├── Entities/    (6 arquivos — @Model SwiftData)
├── Factories/   (2 arquivos — protocolos de factory)
├── Models/      (7 arquivos — structs Sendable)
├── Use Cases/   (7 arquivos — protocolos *UseCase)
└── Utils/       (3 arquivos — CashlyError, CashlyKey, CashlyIntelligence)
```

## Observações / dívidas

1. **Não é um Domain "puro"**: importa `SwiftData`, `RyzeFoundation`, `RyzeIntelligence`, e `SwiftUI` em `Score.swift` (para `Color`). Não é testável sem o ecossistema Apple completo nem sem o Ryze.
2. **Dual representation Model↔Entity dentro do mesmo target**: structs e classes `@Model` convivem. A regra para qual usar onde depende do contexto (in-memory vs persistido), mediada pelo `AdapterUseCase`/`AdapterActor`.
3. **`CashlyError` é genérico**: 3 cases (`onFetch`/`onSave`/`onRemove`), `description = ""`. Não carrega contexto.
4. **`fatalError` em `CashlyKey.swift:29`** ("🗓️ Failed to extract month from date.").
5. **`CashlyIntelligence` faz IO/treino**: `train(...)` é `async`, instancia `RyzeTabularIntelligence`/`RyzeTextIntelligence`. Mistura de domínio + side-effect de ML treinamento dentro do mesmo enum.

## Cobertura de testes

Sem testes diretos no Domain. Os testes de `BudgetActor` em `CashlyTests/Actors/` exercitam indiretamente o protocolo `BudgetUseCase`.

## Quem chama

- `CashlyData/Actors/*Actor.swift` — implementam os protocolos `*UseCase`.
- `CashlyPresentation/Middlewares/*Middleware.swift` — consomem use cases.
- `CashlyUI/Screens/*.swift` — leem Models via state.
- `CashlyMock/Actors/Mock*Actor.swift` — implementam `*UseCase` in-memory.
