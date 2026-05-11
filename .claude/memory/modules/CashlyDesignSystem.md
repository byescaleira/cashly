# Módulo: CashlyDesignSystem

## Identidade

- **Tipo**: Design system layer (wrappers SwiftUI + tokens de estilo)
- **Path**: `CashlyKit/Sources/CashlyDesignSystem/` _(a criar em Wave 5b)_
- **Target SPM**: `CashlyDesignSystem` _(não existe ainda — criado em Wave 5b)_
- **Status**: Planejado. Criação é o objetivo central de G035 / Wave 5b.
- **Dependências planejadas**: `SwiftUI` apenas (zero dependência de Ryze ou Prism)
- **Linkagem inversa planejada**: `CashlyUI` (substitui typealiases `Cashly* = Ryze*`)

## Responsabilidade

Centralizar os ~14 tipos visuais e ~10+ view modifiers que existiam em `RyzeUI` mas não têm equivalente direto em `PrismUI`. Permite que `CashlyUI` use `CashlyDesignSystem` sem depender de Ryze nem de Prism para a camada visual.

### Tipos a implementar (originados de G035)

| Typealias atual (CashlyUI) | Origem Ryze | Implementação CashlyDesignSystem |
|---|---|---|
| `CashlyView` | `RyzeView` | protocolo `CashlyView: View` + `.mock` default |
| `CashlyText` | `RyzeText` | wrapper `struct CashlyText: View` sobre `Text` |
| `CashlyLabel` | `RyzeLabel` | wrapper `struct CashlyLabel: View` sobre `Label` |
| `CashlySymbol` | `RyzeSymbol` | wrapper `struct CashlySymbol: View` sobre `Image(systemName:)` |
| `CashlyHStack` | `RyzeHStack` | `typealias CashlyHStack = HStack` ou wrapper fino |
| `CashlyVStack` | `RyzeVStack` | `typealias CashlyVStack = VStack` ou wrapper fino |
| `CashlyZStack` | `RyzeZStack` | `typealias CashlyZStack = ZStack` ou wrapper fino |
| `CashlyList` | `RyzeList` | wrapper sobre `List` com estilo Cashly |
| `CashlyHorizontalList` | `RyzeHorizontalList` | `ScrollView(.horizontal)` + `LazyHStack` |
| `CashlyBrowserView` | `RyzeBrowserView` | `SFSafariViewController` interop via `UIViewControllerRepresentable` |
| `CashlySystemMonitor` | `RyzeSystemMonitor` | wrapper sobre métricas de processo (`ProcessInfo`, `os.proc`) |
| `CashlyColor` / tokens | `RyzeColor/Size/Spacing/Shape` | `enum CashlyToken` com design tokens Cashly |
| `CashlyCurrencyTextField` | `RyzeCurrencyTextField` | `TextField` com formatter de moeda |

### Modifiers a implementar

View modifiers que existem em Ryze e são chamados em CashlyUI:
- `.ryze(...)` → `.cashly(...)` (theme/styling principal)
- `.ryzePadding` → `.cashlyPadding`
- `.ryzeSymbol` → `.cashlySymbol`
- `.ryzeBackgroundRow` → `.cashlyBackgroundRow`
- E demais com prefixo `ryze*`

## Estratégia de migração (Wave 5b)

1. Criar target `CashlyDesignSystem` em `CashlyKit/Package.swift`.
2. Implementar os tipos mais simples primeiro (typealiases diretos: HStack/VStack/ZStack).
3. Implementar wrappers de wrapper (CashlyText, CashlyLabel, CashlySymbol).
4. Implementar CashlyBrowserView (UIViewControllerRepresentable).
5. Implementar tokens de design (CashlyColor/Spacing/Shape).
6. Validar com `AddUserScreen` (menor screen) antes de ripple para demais.
7. Atualizar `CashlyUI/CashlyUI.swift` — trocar `typealias Cashly* = Ryze*` por `import CashlyDesignSystem`.
8. Remover dependência de Ryze de `CashlyUI`.

## Pontos de atenção

- Este módulo **não deve depender de Ryze ou Prism** — é o ponto de desacoplamento do framework externo para a camada visual.
- `CashlyBrowserView` exige interop com UIKit (`UIViewControllerRepresentable`) — testar em iOS/macOS.
- `CashlySystemMonitor` (aparece em `IntelligenceScreen`) usa métricas de runtime; avaliar se `ProcessInfo` é suficiente ou se `PrismCapabilities/Metrics` seria mais rico.
- Tokens de design devem ser consistentes com o que `PrismUI/Theme` oferece (para não duplicar indefinidamente em Wave 5d).

## ADR relacionado

- **ADR-0002**: wave-5-prism-migration-spike — contexto do porquê CashlyDesignSystem é necessário.
- **ADR-0003**: a criar quando Wave 5b decidir a estratégia final (wrappers SwiftUI próprios vs. contribuição upstream para PrismUI).

## Status de testes

- Sem testes ainda (módulo não existe).
- Alvo: smoke tests de renderização por tipo + snapshot tests dos tokens visuais.
