# ADR-0002: Wave 5 Ryze→Prism Migration — Spike Findings

**Status**: Proposed (spike-only; full migration deferred)
**Date**: 2026-05-10
**Deciders**: Rafael Escaleira

## Context

Cashly depends on Ryze (pinned at `2b619d8`, the last commit before the
upstream rename to Prism + Reducer/Middleware API redesign). Migrating
to Prism is tracked as G022 (transversal) plus G033 (Reducer API
incompatibility, discovered during a first spike attempt).

This ADR records a second spike attempt that swapped the Package.swift
dependency from pinned-Ryze to local Prism (`../../prism`), bulk-renamed
all `Ryze*` symbols to `Prism*`, and tried to port the 6 Reducers and
6 Middlewares end-to-end. Goal: validate the Prism API mapping and
size the real migration.

## Mapping table validated

| Ryze (pinned 2b619d8)                                  | Prism (HEAD as of 2026-05-10)                                  |
|--------------------------------------------------------|----------------------------------------------------------------|
| `actor RyzeReducer: Sendable`                          | `@MainActor protocol PrismReducer: Sendable`                   |
| `func reduce(state: State, action: Action) async -> State` | `func reduce(into state: inout State, action: Action) -> PrismEffect<Action>` |
| `actor RyzeMiddleware`                                 | `protocol PrismMiddleware: Sendable` (struct conformer)        |
| `func run(state:action:) async -> AsyncStream<Action>` | `func run(state:action:) -> PrismEffect<Action>`               |
| `RyzeStore<R, M>` (custom)                             | `PrismStore<State, Action> @Observable @MainActor`             |
| `init(state:reducer:middleware:)`                      | `init(initialState:reducer:middleware:)`                       |
| `func dispatch(action:) async throws`                  | `func dispatch(action:) async` (non-throwing)                  |
| Side-effect: `AsyncStream` w/ `continuation.yield`     | `PrismEffect.run { send in ... }`                              |

Cashly's `Store.dispatch` call sites already match (no `try` needed —
already removed in Wave 6).

## What blocks the full migration

1. **State Sendability**: 5 of 6 States hold SwiftUI `Color` (e.g.
   `AddCategoryState.color`, `AddTagState.color`,
   `AddTransactionState`). `Color` is `@MainActor`-bound and isn't
   `Sendable` in cross-isolation contexts. `PrismMiddleware.run` is
   `Sendable` and its `PrismEffect.run` body is a `@Sendable` closure
   that captures `state`. State must become Sendable. Two options:
   - **(a)** Drop `Color` from state, use `String` (hex) and let the
     view convert at the boundary. Pure refactor, low risk.
   - **(b)** Mark relevant states as `@MainActor` and confine all
     middleware effect bodies to MainActor. Trade-off: backpressure
     on long-running side-effects.

2. **PrismUI gaps**: still present per onboarder findings (no
   `PrismView`, `PrismText`, `PrismLabel`, `PrismHorizontalList`,
   `PrismBrowserView`, `PrismSystemMonitor`). Wave 5b/CashlyDesignSystem
   work, out of scope for 5a.

3. **PrismSecurity has upstream bug** (`import UIKit` missing in
   `PrismIntegrityChecker.swift`). Avoided by using Prism submodule
   products (`PrismFoundation`, `PrismArchitecture`, `PrismIntelligence`,
   `PrismUI`) rather than the umbrella `Prism`.

4. **MockCashlyFactory** instantiates Reducers in `@MainActor` context;
   Reducers becoming `@MainActor struct` should be compatible but
   needs validation. Stores must also be created on the main actor —
   already the case in `CashlyApp.init()` and `MockModifier.init()`.

## Decision

**Defer full Wave 5a** until the State-Sendability decision is taken
(option a vs b above) and at least one State + Reducer + Middleware
trio is migrated end-to-end as a validating example. Pre-requisite for
the next attempt:

- Decide State-Sendability strategy (recommend **a** — drop `Color`,
  use hex strings).
- Write the example port for `AddUser*` (smallest, no Color in state)
  on a feature branch and validate at runtime.
- Only then plan the bulk port of the remaining 5 trios.

## Consequences

- Cashly stays on pinned Ryze `2b619d8` for now.
- Reducers/Middlewares retain `actor` + async-State signature.
- All Wave 0-4 and Wave 6-8 improvements remain landed; only Wave 5
  is gated by this ADR.
- New gap registered: **G034 — State Sendability for Wave 5** (see
  `gap-analysis.md`).

## Spike artifact

The local `migration/wave-5a-prism` branch was created, modified, and
deleted during this spike. No code from the spike landed on `main`.
Findings are recorded here.

## 2026-05-11 attempt #4 — additional blockers discovered (post Wave 5b)

After Wave 5b shipped (CashlyDesignSystem owns vocabulary), a fourth
attempt at the Package.swift swap surfaced **deeper API-shape blockers
beyond State Sendability**:

1. **`$store.state.x` two-way bindings everywhere.** Cashly screens
   (FilterItemView, MockModifier, several Add* screens) write directly
   to `store.state` via `@Bindable var store = store` and bind
   `$store.state.field` to Toggle/Picker/TextField. PrismStore exposes
   `state` as `private(set)`, mutation only via `send(action:)` /
   `dispatch(action:)`. Every direct-mutation site needs a new
   Action case + reducer arm. Rough count: ~25 binding sites across
   8 screen files.

2. **`Self: RyzeView` static `mocked()` ergonomics gap.** PrismMock has
   no View constraint — refactor of `cashlyPreview()` already landed
   in Wave 5b but assumes Cashly-owned `CashlyView` protocol still
   in place after the swap. Compatible, but worth noting.

3. **`.ryze(...)` modifier residue.** Wave 5b lifted color/tint/clip/
   alignment/background/systemMonitor/clip to native, but 8 modifiers
   still forward to Ryze: `ryze(font:weight:design:)`, `ryze(if:)`,
   `ryze(item:)`, `ryzeConfetti`, `ryzeSymbol`, `ryzeBackgroundRow`,
   plus internal helpers. Each needs native rewrite or PrismUI
   equivalent before the Package swap.

4. **Domain references `RyzeFileManager`/`RyzeTabularIntelligence`/
   `RyzeTextIntelligence`.** PrismFoundation/PrismIntelligence rename
   these to `Prism*` directly. Bulk sed handles it cleanly. New issue:
   `CashlyDataFactoryProtocol` was non-isolated, but PrismStore is
   `@MainActor`, so the protocol must be `@MainActor` too. Same for
   `CashlyDataFactory` and `MockCashlyFactory`. Compatible but
   touches Domain.

5. **`Category`/`Tag`/`User`/`TransactionStatus` Identifiable.**
   `CashlyMenuSelectionView` and ForEach call sites in
   `FilterItemView`/`ParticipantRowView` require these to be
   Identifiable. Already are in some cases, but the loss of
   `RyzeIdentifiable` default conformance reveals gaps.

6. **Concurrency conformance crosses.** `MockCashlyFactory` marked
   `@MainActor` conflicts with `CashlyDataFactoryProtocol` if the
   latter isn't `@MainActor`. Both must align.

### Revised pre-requisites

Before another attempt, all 6 items above need a defined plan:
- Refactor direct `$store.state.x` bindings into actions, OR
- Adopt PrismDerivedStore/PrismStore.scope to create writable child
  stores for binding (PrismStore has this — see `scope(state:action:)`).
- Drop residual `.ryze(...)` modifiers to native equivalents.
- Mark Cashly factory protocols `@MainActor`.
- Audit Identifiable conformance on Domain models.

### Decision

**Defer Wave 5a real merge again.** Post Wave 5b unblocks the
vocabulary layer but the binding/mutation surface remains the
blocker. Recommended path: a dedicated mini-wave 5a' that ports
binding sites to actions (zero Prism work, prepares the seam), then
the actual Package swap becomes mechanical.
