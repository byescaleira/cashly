# ADR-0007: Reducer + Middleware composition shape

**Status**: Accepted
**Date**: 2026-05-13
**Deciders**: Rafael Escaleira

## Context

The Presentation layer is built on Prism (PrismStore + PrismReducer +
PrismMiddleware + PrismEffect). After 7 feature stores (Main + 6
Add* + Paywall), the team needed an explicit contract for how
reducers and middlewares compose so that:

1. New screens follow the same shape without case-by-case decisions.
2. Middleware effects can be tested without spinning a live store.
3. Action vocabulary stays small per feature — no cross-feature
   action leakage.

The shape settled organically across A–H eixos; this ADR captures it.

## Decision

### 1. One reducer per feature, pure

- Reducer takes `(inout State, Action) -> Void`.
- Pure. No I/O, no async. Computes the next State synchronously.
- State conforms to `CashlyReplaceableAction`-friendly equality and
  is `Sendable` by value-type construction.

### 2. Middleware = effects layer, factory-injected

- Middleware closure: `(State, Action) async -> PrismEffect<Action>`.
- Holds no mutable state itself. All collaborators (use cases,
  loggers, platform services) are captured at composition time via
  the factory.
- Returns one of: `.none`, `.action(_)`, `.actions(_)`, `.stream(_)`.

### 3. Action surface

- Each feature owns its own `XxxAction` enum.
- `MainAction` is the only one that carries deep-link / navigation
  routes (`.route(MainRoute)`).
- Cross-feature signals travel through Domain-level streams
  (Spotlight, Reachability, SyncStatus) and re-enter middleware via
  AsyncStream observation — never via direct action emission from one
  feature into another.

### 4. Composition root

`CashlyPresentationFactory` builds:

- Use cases from `CashlyDataFactoryProtocol` (production or mock).
- Middleware closures by capturing those use cases.
- The `PrismStore<State, Action>` for each feature.

The factory itself is `@MainActor` because PrismStore is bound to
MainActor. Use cases are actors or `Sendable` structs and are passed
across the actor boundary at capture time.

### 5. Effect kinds

```
.none                 // reducer-only response
.action(.foo)         // single follow-up action
.actions([...])       // ordered follow-ups
.stream { yield in    // long-running observations
  for await event in source {
    yield(.didReceive(event))
  }
}
```

Streams MUST be cancellable from the store; middleware never
captures the store itself, only the use cases.

## Diagram

```
┌────────────────── SwiftUI Screen ───────────────────┐
│                                                      │
│        store.send(.userTappedSave)                  │
│                       │                              │
└───────────────────────┼──────────────────────────────┘
                        ▼
                  ┌───────────┐
                  │ PrismStore │ (MainActor)
                  └─────┬─────┘
                        │
              ┌─────────┴──────────┐
              ▼                    ▼
        ┌──────────┐         ┌─────────────┐
        │ Reducer  │         │ Middleware  │
        │  (pure)  │         │  (async)    │
        └────┬─────┘         └──────┬──────┘
             │                      │
       new state                  effect
             │                      │
             │              ┌───────┴────────┐
             │              ▼                ▼
             │       ┌────────────┐  ┌────────────┐
             │       │ Use Case   │  │ Async       │
             │       │ (CashlyData)│  │ Stream      │
             │       └─────┬──────┘  └─────┬───────┘
             │             │               │
             │            yield           yield
             │             │               │
             │             └───────┬───────┘
             │                     ▼
             │             store.handle(action)
             │                     │
             └─────────────► state.replace
                                   │
                                   ▼
                              View re-renders
```

## Consequences

**Positive**

- Adding a feature = 4 files (State, Action, Reducer, Middleware) +
  factory wires. No surprises.
- Middlewares testable in isolation: feed `(state, action)`,
  inspect `PrismEffect` shape and recorded use-case calls.
- Strict-concurrency clean: reducers value-only, middlewares hold
  Sendable captures only.

**Negative**

- Cross-feature notifications require a Domain stream + middleware
  observer pair. Heavier than a direct action send, but keeps the
  action surface small.

**Neutral**

- AppDelegate / scenePhase bridges (Quick Actions, AppIntents) live
  outside this loop and re-enter via `routeExternal(_)` →
  `MainAction.route(_)`. ADR-0006 covers the router extraction half.

## References

- ADR-0002 (Prism migration spike)
- ADR-0006 (MainState router extraction)
- CashlyDomain.docc/Architecture.md
