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

## Vocabulário de componentes

Os tipos visuais (`CashlyView`, `CashlyText`, `CashlyHStack`, etc.) eram typealiases de `RyzeUI` em `CashlyUI/CashlyUI.swift`. **Após Wave 5b**, essas definições migram para o módulo `CashlyDesignSystem` — ver `.claude/memory/modules/CashlyDesignSystem.md` para a lista completa e estratégia de migração.

Enquanto Wave 5b não conclui, o vocabulário visual ainda vive como `typealias Cashly* = Ryze*` em `CashlyUI.swift`.

## Padrão de uso

Cada Screen segue o padrão (pós Wave 6 — migrado de `@EnvironmentObject`):

```swift
public struct HomeScreen: CashlyView {
    @Environment(MainStore.self) var store
    @Environment(\.mainState) var state
    @Environment(\.action) var action
    @Environment(\.prismTheme) var theme    // renomeado de \.theme em Wave 5a spike
    public init() {}
    public var body: some View {
        @Bindable var store = store  // necessário para $store.state.x bindings (G032)
        ...
    }
}
```

- `@Environment(T.self)` substitui `@EnvironmentObject` (Wave 6, G018 fechado).
- `@Bindable var store = store` em body/computed para reativar `$store.x` bindings (G032 fechado).
- `\.mainState`, `\.action` são `EnvironmentValues` customizados injetados em `CashlyApp.swift`.
- View dispara mudanças via `action(.main(.fetch))`.

## Observações / dívidas

1. **God screens (parcialmente refatoradas)**: `AddTransactionScreen` (497), `HomeScreen` (466), `TransactionScreen` (282). Decomposição parcial em Wave 7 (G019 parcial). Alvo ≤200 linhas por arquivo.
2. **`CashlyView` é alias de `RyzeView`** — pós Wave 5b passará a ser protocolo próprio em `CashlyDesignSystem`. Ver `modules/CashlyDesignSystem.md`.
3. **CashlyUI depende de CashlyMock** (G007 parcial): `MainScreen` usa `.cashlyPreview()` via `CashlyMock`. G031 fechado (default `mocked()` extension). Separação formal de target ainda pendente.
4. **i18n (G020 parcial)**: String Catalog criado, ~50 strings migradas. ~60 strings hardcoded remanescentes em body Text/section headers.
5. **Acessibilidade (parcial)**: `accessibilityLabel` + `isButton` trait em 11 botões icon-only. `cashlyAnimation(_:value:)` respeita Reduce Motion. Pendente: sweep de 35 `.animation(...)` sites, Dynamic Type audit, VoiceOver pass em forms.
6. **Sem testes de UI sistemáticos**: snapshot tests iniciados em Wave 7 mas cobertura ainda baixa (G014/G017 parciais).
