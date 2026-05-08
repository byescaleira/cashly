# Módulo: CashlyUI

## Identidade

- **Tipo**: UI layer (SwiftUI puro, screens + componentes)
- **Path**: `CashlyKit/Sources/CashlyUI/`
- **Target SPM**: `CashlyUI`
- **Arquivos Swift**: 32
- **Dependências de target**: `CashlyDomain`, `CashlyPresentation`, `CashlyMock`, `CashlyResource`
- **Dependências externas**: `Ryze` (`RyzeUI`, `RyzeArchitecture`)
- **Linkagem inversa**: `Cashly` (app), `CashlyTests`

## Responsabilidade aparente

Toda a interface gráfica do app, incluindo:

- **Screens** (11): top-level views por feature.
  - `MainScreen` (entry point após App)
  - `HomeScreen` (466 linhas — dashboard com BalanceView, available section, variance, biggest transaction, tags, spending forecast)
  - `IntelligenceScreen` (treina modelos ML, mostra system monitor)
  - `CategoryScreen`, `DetailCategoryScreen`
  - `TransactionScreen` (282 linhas)
  - `AddBudgetScreen`, `AddCategoryScreen`, `AddTagScreen`, `AddTransactionScreen` (497 linhas), `AddUserScreen`
- **Components**: `CashlyCardView`, `CashlyChart`, `CashlyCompareChart`, `CashlyMenuSelectionView`
- **Views**: `BalanceView`, `CategoryBalanceView`, `CategoryVariationView`, `TransactionBalanceView`, `ParticipantRowView`, `Empty*View`, `SystemMonitorView`
- **Items**: `FilterItemView` (251 linhas), `UserItemView`
- **Modifier**: ViewModifiers internos
- **Extensions**: extensions de SwiftUI

## Padrão de uso

Cada Screen segue o padrão:

```swift
public struct HomeScreen: CashlyView {
    @EnvironmentObject var store: CashlyStore<MainReducer, MainMiddleware>
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.router) var router
    public init() {}
    public var body: some View { ... }
}
```

- `@EnvironmentObject` recebe o Store.
- `\.mainState`, `\.action`, `\.router` são `EnvironmentValues` customizados injetados em `CashlyApp.swift:45-52`.
- View dispara mudanças via `action(.main(.fetch))`.

## Observações / dívidas

1. **3 god screens**: `AddTransactionScreen` (497), `HomeScreen` (466), `TransactionScreen` (282). Candidatos óbvios a decomposição.
2. **`CashlyView` é alias de `RyzeView`** — protocolo possivelmente exigindo conformidade `View` + algum método, a confirmar.
3. **CashlyUI depende de CashlyMock**: `MainScreen` usa `.cashlyPreview()` (de `CashlyMock`) condicionado a `#if targetEnvironment(simulator)` em `CashlyApp.swift:36`. Acoplamento de produção ↔ preview infra.
4. **Strings hardcoded em inglês**: ex. `.navigationTitle("Intelligence")` em `IntelligenceScreen`. Apesar de `defaultLocalization: pt-BR`, não há String Catalog detectado. Sem L10n estruturada.
5. **Sem testes de UI**: zero snapshot tests, zero XCUITest.
6. **Acessibilidade**: nenhum `.accessibilityLabel`/`Hint` notável (não exaustivamente checado).
