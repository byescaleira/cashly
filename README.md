# Cashly

iOS / macOS / visionOS personal-finance app. Budgets, transactions,
tags, categories, multi-user splits, on-device CreateML category +
budget prediction, and a StoreKit 2 Pro subscription that unlocks
unlimited entities and AI features.

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

360 tests across 57 suites — reducers, middlewares, state computed
properties, DesignSystem tokens, snapshots, composition factories,
subscription/feature-gate contract, paywall reducer.
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
`CashlyPresentationFactory` at launch, injects 7 stores (5 Add*
+ Main + Paywall) into `MainScreen` via `@Environment`. The
StoreKit `Transaction.updates` listener and a status-stream
observer are launched as long-lived `.task`s on the root scene.
No singletons.

### Subscription & feature gating

`SubscriptionUseCase` (Domain) is the only contract UI sees; the
concrete `StoreKitSubscriptionService` (Data) drives Product
loading, verified purchases, restore, refund handling and the
ongoing `Transaction.updates` listener. `FeatureGateUseCase`
combines the active tier with live entity counts to answer
"can the user do X right now?" — Free is capped at 1 user / 3
categories / 5 budgets and excludes AI; Pro short-circuits to
allowed. Add-flow middlewares emit
`.error(.domain(.featureGated(...)))` on block; the
`cashlyErrorAlert` modifier routes that case to the
`PaywallScreen` via the active router instead of an alert.

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
