# ADR-0006: Extract MainState Routers to MainScreen @State

**Status**: Accepted
**Date**: 2026-05-11
**Deciders**: Rafael Escaleira

## Context

`MainState` used to carry four `CashlyRouter<MainRoute>` properties —
one per tab (`intelligenceRouter`, `categoryRouter`, `homeRouter`,
`transactionRouter`). `CashlyRouter` is a reference-type, `@unchecked
Sendable` class (mutable navigationPath, sheet item, etc.). Holding
it inside a value-type State produced three problems:

1. **Sendable lie**: State conforms to `Sendable` via auto-synthesis,
   but the stored router class is `@unchecked Sendable`. Strict
   concurrency would never flag it, yet writes from middleware
   effect closures mutate the shared instance — outside any actor.
2. **Reducer/middleware coupling**: routers are pure SwiftUI
   navigation concerns. Putting them in State pushed
   navigation-shaped concerns into middlewares and reducers that had
   no business touching them.
3. **Replace mechanic broke**: `CashlyReplaceableAction.replace(State)`
   would swap router instances on every replay, losing the live
   navigation stack.

## Decision

Remove all four router properties from `MainState`. Move them to
`MainScreen` as `@State` per tab:

```swift
public struct MainScreen: CashlyView {
    @State var intelligenceRouter = CashlyRouter<MainRoute>()
    @State var categoryRouter = CashlyRouter<MainRoute>()
    @State var homeRouter = CashlyRouter<MainRoute>()
    @State var transactionRouter = CashlyRouter<MainRoute>()
    // ...
}
```

Each `CashlyNavigationView` now binds `$tabRouter` directly instead
of going through `store.cashlyBinding(\.tabRouter)`.

## Consequences

**Good**:
- `MainState` is now pure value semantics. Auto-synthesized
  `Sendable` is honest.
- Routers stay where they belong — in the view layer, alongside
  `NavigationStack`.
- Strict concurrency build clean; zero `@unchecked` in States.
- `replace(State)` semantics correct.

**Trade-offs**:
- Routers no longer survive `MainScreen` re-creation (e.g. parent
  view swap). In practice MainScreen is the app root tab container
  — it doesn't get re-created, so this is fine.
- Tests that asserted `state.intelligenceRouter.navigationPath.isEmpty`
  removed — they were testing SwiftUI state, not Domain state.

## Alternatives considered

1. **Make CashlyRouter a value type.** Rejected: SwiftUI bindings
   need reference semantics for the navigation stack to mutate
   in-place across re-renders.
2. **Keep routers in State, mark MainState `@unchecked Sendable`.**
   Rejected: lies harder, doesn't fix the replay-on-replace issue.
3. **Single shared router in Environment.** Rejected: each tab needs
   its own navigation stack; one router would conflate them.

## Follow-ups

- Verify on a long session that no tab loses its navigation stack
  during a backgrounded → foregrounded cycle. SwiftUI keeps `@State`
  alive while the view is in the hierarchy; the tab's own
  `NavigationStack` is unaffected.
