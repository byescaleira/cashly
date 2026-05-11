# ``CashlyPresentation``

Redux-style state management for Cashly built on Prism. Holds States,
Actions, Reducers, Middlewares, the routing layer, and the
``CashlyStore`` typealias that screens consume via SwiftUI
`@Environment`.

## Overview

Each feature ships its own trio:

- A **State** struct (``MainState``, ``AddCategoryState``,
  ``AddBudgetState``, ``AddTransactionState``, ``AddUserState``,
  ``AddTagState``) — pure data + derived helpers (e.g.
  `canSave`, `yearMonth`, `categories`).
- An **Action** enum (``MainAction`` and the `Add*Action` family),
  every one conforming to ``CashlyReplaceableAction`` so the
  `.replace(State)` case can be dispatched by Store binding helpers.
- A **Reducer** (`@MainActor struct: PrismReducer`) that maps
  `(inout State, Action) -> PrismEffect<Action>`.
- A **Middleware** (`struct: PrismMiddleware`) that interprets the
  action and produces a `PrismEffect.run { send in ... }` against
  domain use cases.

The ``CashlyStore`` typealias targets `PrismStore<State, Action>` —
`@MainActor @Observable`. View writes route through
``CashlyStore/cashlyBinding(_:)``, ``CashlyStore/cashlyMutate(_:_:)``,
and ``CashlyStore/cashlyReplace(_:)``, each of which dispatches
`.replace(newState)` so the reducer remains the single source of
truth even for two-way bindings.

## Topics

### Stores

- ``CashlyStore``
- ``CashlyState``
- ``CashlyAction``
- ``CashlyReducer``
- ``CashlyMiddleware``
- ``CashlyReplaceableAction``

### Store binding helpers

- ``PrismArchitecture/PrismStore/cashlyBinding(_:)``
- ``PrismArchitecture/PrismStore/cashlyMutate(_:_:)``
- ``PrismArchitecture/PrismStore/cashlyReplace(_:)``

### States

- ``MainState``
- ``FilterState``
- ``AddCategoryState``
- ``AddBudgetState``
- ``AddTransactionState``
- ``AddUserState``
- ``AddTagState``

### Actions

- ``ApplicationAction``
- ``MainAction``
- ``AddCategoryAction``
- ``AddBudgetAction``
- ``AddTransactionAction``
- ``AddUserAction``
- ``AddTagAction``

### Reducers

- ``MainReducer``
- ``AddCategoryReducer``
- ``AddBudgetReducer``
- ``AddTransactionReducer``
- ``AddUserReducer``
- ``AddTagReducer``

### Middlewares

- ``MainMiddleware``
- ``AddCategoryMiddleware``
- ``AddBudgetMiddleware``
- ``AddTransactionMiddleware``
- ``AddUserMiddleware``
- ``AddTagMiddleware``

### Routing

- ``MainRoute``

### Composition root helpers

- ``CashlyPresentationFactory``
- ``CashlyPresentationFactoryProtocol``
