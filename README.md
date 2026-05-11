# Cashly

iOS/macOS/visionOS personal finance app. Budgets, transactions, tags,
categories, multi-user splits, AI-powered category prediction and budget
forecasting (CreateML on-device).

## Requirements

- Xcode 26+
- iOS 26 / macOS 26 / visionOS 26 SDK
- Swift 6.3 toolchain
- Local `prism` checkout next to `cashly/` (sibling directory) — see
  `INSTALL.md`

## Quickstart

```bash
git clone https://github.com/byescaleira/cashly.git
cd cashly
open Cashly/Cashly.xcodeproj
```

Build/run **Production** scheme on iPhone 17 simulator (or device).

### Tests

```bash
cd Cashly
xcodebuild test \
  -scheme Production \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

15 tests: actor smoke tests + UI screen snapshots. Snapshot baselines
live in `CashlyKit/Tests/CashlyTests/Snapshots/__Snapshots__/`.

### CI

GitHub Actions on `macos-26`. Builds Production scheme + runs full
test suite on every push/PR to `main`. See `.github/workflows/ci.yml`.

## Architecture

Clean Architecture, 7 SPM targets in `CashlyKit/`:

```
CashlyDomain         ← pure Swift: Models, Use Cases, Errors, Intelligence enums
   ↑
CashlyData           ← SwiftData persistence + CloudKit sync + IntelligenceService
   ↑
CashlyResource       ← Localizable.xcstrings, mock JSON, Logger, Image helpers
   ↑
CashlyDesignSystem   ← Cashly-owned UI vocabulary (Text/Stack/Button/Color/Shape/…)
   ↑                   + Router + NavigationView + SystemMonitor + ConfettiOverlay
CashlyPresentation   ← Redux-style Stores/Reducers/Middlewares (via Prism)
   ↑                   + CashlyStore binding helpers (cashlyBinding / cashlyMutate)
CashlyUI             ← SwiftUI Screens, Items, Views, Components
   ↑
CashlyMock           ← test/preview fixtures (DEBUG-only in production builds)
```

Composition root: `Cashly/Cashly/CashlyApp.swift`. Builds
`CashlyPresentationFactory` once at app launch, injects 6 stores into
`MainScreen` via `@Environment`. No singletons.

### State management

Prism (Redux-flavored, post Wave 5a). Each feature has its own
`CashlyStore<State, Action>` (= `PrismStore<State, Action>`,
`@MainActor @Observable`). Reducers are `@MainActor struct: PrismReducer`
with `reduce(into:action:) -> PrismEffect<Action>` — pure, no async.
Middlewares are `struct: PrismMiddleware` returning
`PrismEffect.run { send in ... }` for side effects against Use Case
protocols implemented by SwiftData `@ModelActor` actors in CashlyData.

`PrismStore.state` is `private(set)`. Views write through
`store.cashlyBinding(_:)` / `store.cashlyMutate(_:_:)` /
`store.cashlyReplace(_:)`, all of which dispatch a
`Action.replace(State)` case (via the `CashlyReplaceableAction`
protocol) and resolve through the reducer.

## Project memory

`.claude/memory/` holds onboarding artifacts and migration plan:

- `architecture.md` — layer rules + module map
- `tech-stack.md` — versions, frameworks, libs
- `conventions.md` — code style, naming, testing rules
- `glossary.md` — domain terms (Budget, Transaction, Tag, etc.)
- `migration/migration-plan.md` — 9-wave migration roadmap
- `migration/gap-analysis.md` — all gaps, severity, target wave
- `adr/` — architectural decision records (0001 onboard, 0002 Prism
  spike, 0003 CashlyDesignSystem)

Read these before non-trivial work.

## Observability

`CashlyLogger` exposes per-subsystem `os.Logger` instances (`.data`,
`.domain`, `.presentation`, `.ui`, `.intelligence`, `.app`). Filter in
Console.app by `subsystem:com.cashly.app`.

Hot paths use `CashlySignpost.withInterval(_:_:)` — visible in
Instruments under the Signposts track.

Analytics: `AnalyticsTracker` protocol. Composition root injects a
concrete implementation; modules below take the protocol.

## Internationalization

Strings live in `CashlyKit/Sources/CashlyResource/Localizable.xcstrings`.
en (source) + pt-BR. Access via `CashlyL10n.string("Key")`.

## Accessibility

- VoiceOver labels on all icon-only toolbar buttons
- Chart data summarized as readable text for VO users
- `View.cashlyAnimation(_:value:)` modifier respects `Reduce Motion`
- All localized strings double as VO content

## Status

Migration complete. All 36 gaps from `gap-analysis.md` closed except
docs/god-files/a11y tail (G016 README — this file, G019 residual god
files, G020 i18n/a11y tail). Cashly is on Prism. Domain is pure (no
SwiftUI, no SwiftData). DI at composition root.

## License

Proprietary. See `LICENSE` if present.
