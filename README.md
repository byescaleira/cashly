# Cashly

iOS / macOS / visionOS personal-finance app. Budgets, transactions,
tags, categories, multi-user splits, on-device CreateML category +
budget prediction.

## Requirements

- Xcode 26+
- iOS 26 / macOS 26 / visionOS 26 SDK
- Swift 6.3 toolchain
- A `prism` checkout sibling to `cashly/`:

  ```
  /your/dev/dir/
  ├── cashly/
  └── prism/
  ```

  `CashlyKit/Package.swift` consumes Prism via the local path
  `../../prism`.

## Quickstart

```bash
git clone https://github.com/byescaleira/cashly.git
git clone https://github.com/rafaelesantos/prism.git
open cashly/Cashly/Cashly.xcodeproj
```

Build/run **Production** on iPhone 17 simulator.

### Tests

```bash
cd cashly/CashlyKit
xcodebuild test \
  -scheme CashlyKit-Package \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

336 tests across 54 suites — reducers, middlewares, state computed
properties, DesignSystem tokens, snapshots, and composition factories.
Snapshot baselines live in
`CashlyKit/Tests/CashlyTests/Snapshots/__Snapshots__/`.

### CI

GitHub Actions on `macos-26`. See `.github/workflows/ci.yml`. The
workflow checks out both `cashly/` and `prism/` so the SPM local path
resolves on the runner.

## Architecture

Clean Architecture across 7 SPM targets in `CashlyKit/`:

```
CashlyDomain        pure Swift: Models, Use Case protocols, Errors,
                    Intelligence enums.

CashlyData          SwiftData @ModelActor persistence + CloudKit sync
                    + CashlyIntelligenceService training pipeline.

CashlyResource      Localizable.xcstrings, mock JSON fixtures, Logger,
                    Signpost, AnalyticsTracker.

CashlyDesignSystem  Cashly-owned SwiftUI vocabulary (Text / Stack /
                    Button / Color / Shape / Spacing / Router /
                    NavigationView / SystemMonitor / Confetti).
                    Pure SwiftUI — zero external deps.

CashlyPresentation  Redux-style Stores / Reducers / Middlewares built
                    on Prism. Store binding seam
                    (cashlyBinding / cashlyMutate / cashlyReplace).

CashlyMock          Test + preview fixtures (DEBUG-only at use sites).

CashlyUI            SwiftUI Screens, Items, Views, Components.
```

Composition root: `Cashly/Cashly/CashlyApp.swift`. Builds
`CashlyPresentationFactory` at launch, injects 6 stores into
`MainScreen` via `@Environment`. No singletons.

### State management

Each feature ships a `CashlyStore<State, Action>` (= `PrismStore`,
`@MainActor @Observable`). Reducers are
`@MainActor struct: PrismReducer` with
`reduce(into:action:) -> PrismEffect<Action>` — pure, no async.
Middlewares are `struct: PrismMiddleware` returning
`PrismEffect.run { send in ... }` for side effects against
domain use case protocols implemented by SwiftData `@ModelActor`s.

`PrismStore.state` is `private(set)`. Views write through
`store.cashlyBinding(_:)` / `store.cashlyMutate(_:_:)` /
`store.cashlyReplace(_:)` — every helper dispatches a
`Action.replace(State)` case (via the `CashlyReplaceableAction`
protocol) so the reducer remains the single source of truth.

## Observability

- `CashlyLogger` exposes per-subsystem `os.Logger` instances
  (`.data`, `.domain`, `.presentation`, `.ui`, `.intelligence`,
  `.app`). Filter in Console.app by `subsystem:com.cashly.app`.
- `CashlySignpost.withInterval(_:_:)` wraps hot paths (visible in
  Instruments → Signposts).
- `AnalyticsTracker` is a protocol; the composition root injects
  a concrete implementation. Lower layers take only the protocol.

## Internationalization

Strings live in
`CashlyKit/Sources/CashlyResource/Localizable.xcstrings`. en (source)
+ pt-BR. Access via `CashlyL10n.string("Key")` everywhere.

## Accessibility

- VoiceOver labels on every icon-only toolbar button.
- Chart data summarized as readable text for VO users.
- Reduced-motion-aware animations via
  `View.cashlyAnimation(_:value:)`.
- All localized strings double as VO content.

## DocC

Each target ships a DocC catalog in
`CashlyKit/Sources/<Target>/<Target>.docc`. Preview locally with
`swift package --disable-sandbox preview-documentation --target
<Target>`.

## License

Proprietary. See `LICENSE` if present.
