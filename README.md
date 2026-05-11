# Cashly

iOS/macOS/visionOS personal finance app. Budgets, transactions, tags,
categories, multi-user splits, AI-powered category prediction and budget
forecasting (CreateML on-device).

## Requirements

- Xcode 16+
- iOS 26 / macOS 26 / visionOS 26 SDK
- Swift 6.3 toolchain

## Quickstart

```bash
git clone https://github.com/byescaleira/cashly.git
cd cashly
open Cashly.xcworkspace
```

Build/run **Production** scheme on iPhone 17 simulator (or device).

### Tests

```bash
xcodebuild test \
  -workspace Cashly.xcworkspace \
  -scheme Core \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=latest'
```

15 tests: actor smoke tests + UI screen snapshots. Snapshot baselines
live in `CashlyKit/Tests/CashlyTests/Snapshots/__Snapshots__/`.

### CI

GitHub Actions on `macos-15`. Builds Production scheme + runs full
test suite on every push/PR to `main`. See `.github/workflows/ci.yml`.

## Architecture

Clean Architecture, 6 SPM targets in `CashlyKit/`:

```
CashlyDomain      ← pure Swift: Models, Use Cases, Errors
   ↑
CashlyData        ← SwiftData persistence + CloudKit sync
   ↑
CashlyPresentation← Redux-style Stores, Reducers, Middlewares (via Ryze)
   ↑
CashlyUI          ← SwiftUI Screens, Items, Views, Components
   ↑
CashlyMock        ← test/preview fixtures (DEBUG-only in production builds)

CashlyResource    ← Localizable.xcstrings, mock JSON, Logger, Image helpers
```

Composition root: `Cashly/Cashly/CashlyApp.swift`. Builds
`CashlyPresentationFactory` once at app launch, injects 6 stores into
`MainScreen` via `@Environment`.

State management: Ryze (Redux-flavored). Each feature has its own
Store<Reducer, Middleware>. Reducers are pure; middlewares produce
async side effects via Use Case protocols implemented by SwiftData
@ModelActors in CashlyData.

## Project memory

`.claude/memory/` holds onboarding artifacts and migration plan:

- `architecture.md` — layer rules + module map
- `tech-stack.md` — versions, frameworks, libs
- `conventions.md` — code style, naming, testing rules
- `glossary.md` — domain terms (Budget, Transaction, Tag, etc.)
- `migration/migration-plan.md` — 9-wave migration roadmap
- `migration/gap-analysis.md` — all gaps, severity, target wave
- `adr/` — architectural decision records

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
en (source) + pt-BR currently. Access via `CashlyL10n.string("Key")`.
~75 keys covering UI surfaces + a11y labels.

## Accessibility

- VoiceOver labels on all icon-only toolbar buttons
- Chart data summarized as readable text for VO users
- `View.cashlyAnimation(_:value:)` modifier respects `Reduce Motion`
- All localized strings double as VO content

## Status

Migration in progress. Wave 7 (god-files + i18n + a11y core) complete.
Wave 5 (Ryze→Prism) blocked by API redesign — see G033 in
`gap-analysis.md`.

## License

Proprietary. See `LICENSE` if present.
