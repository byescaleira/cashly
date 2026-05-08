# Módulo: CashlyPresentation

## Identidade

- **Tipo**: Presentation layer — Redux/TCA-flavored state management (NÃO MVVM tradicional)
- **Path**: `CashlyKit/Sources/CashlyPresentation/`
- **Target SPM**: `CashlyPresentation`
- **Arquivos Swift**: 32
- **Dependências de target**: `CashlyDomain`, `CashlyData`
- **Dependências externas**: `Ryze` (`RyzeArchitecture`, `RyzeIntelligence`, `RyzeFoundation`)
- **Linkagem inversa**: `CashlyUI`, `CashlyMock`, `Cashly` (app), `CashlyTests`

## Responsabilidade aparente

Define o "cérebro" da aplicação no padrão Redux unidirecional de Ryze:

```
View → action(action:) → Store.dispatch
                            ├─► Reducer.reduce(state, action) → newState (puro)
                            └─► Middleware.run(state, action) → AsyncStream<Action> (side-effects)
```

- **`CashlyPresentation.swift`**: typealiases `CashlyState/Action/Reducer/Middleware/Store/Routable/NavigationStyle/Router` para os equivalentes `Ryze*`.
- **`CashlyPresentationFactory`**: composition root da camada — instancia stores cabíveis (`makeMainStore`, `makeAddBudgetStore`, `makeAddCategoryStore`, `makeAddTransactionStore`, `makeAddUserStore`, `makeAddTagStore`). Singleton via `static let shared` `@MainActor`.

### Sub-pastas

```
CashlyPresentation/
├── Actions/      (7) — *Action enums (incluindo ApplicationAction como agregado)
├── Reducers/     (6) — *Reducer actor
├── Middlewares/  (6) — *Middleware actor
├── States/       (7) — *State struct + FilterState
├── Route/        (2) — MainRoute (enum CashlyRoutable), MainDeeplink (vazio)
├── Extensions/
└── Utils/        — CashlyDateFormatter, CashlySymbolCategory (486 linhas)
```

## Stores existentes

| Store | Reducer | Middleware | State |
|---|---|---|---|
| MainStore | MainReducer | MainMiddleware | MainState |
| AddBudgetStore | AddBudgetReducer | AddBudgetMiddleware | AddBudgetState |
| AddCategoryStore | AddCategoryReducer | AddCategoryMiddleware | AddCategoryState |
| AddTransactionStore | AddTransactionReducer | AddTransactionMiddleware | AddTransactionState |
| AddUserStore | AddUserReducer | AddUserMiddleware | AddUserState |
| AddTagStore | AddTagReducer | AddTagMiddleware | AddTagState |

## Action agregada

`ApplicationAction` (em `Actions/ApplicationAction.swift`) é o enum top-level que `CashlyApp.handler(action:)` despacha:

```swift
case .addCategory(AddCategoryAction)
case .addBudget(AddBudgetAction)
case .addTransaction(AddTransactionAction)
case .addUser(AddUserAction)
case .addTag(AddTagAction)
case .main(MainAction)
```

## Observações / dívidas

1. **MainState contém 4 routers separados** (`intelligenceRouter`, `categoryRouter`, `homeRouter`, `transactionRouter`) — semântica não documentada.
2. **Predições de ML armazenadas no estado**: `MainState.predictedTransactionsAmount`, e o Middleware mantém `budgetValuePrediction`, `categoryNamePrediction`, `tagValuePrediction` como estado **dentro do actor middleware** (não no state) — modelo híbrido.
3. **`CashlySymbolCategory.swift` tem 486 linhas** — provavelmente uma tabela manual de SF Symbols organizada em categorias. Candidato a extrair para `CashlyResource` ou gerar a partir de JSON.
4. **`MainDeeplink.swift` está vazio** — esqueleto não implementado.
5. **Sem testes de Reducer ou Middleware** — toda a lógica de transição de estado e os side-effects estão sem cobertura.
