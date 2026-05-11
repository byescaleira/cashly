# ``CashlyUI``

SwiftUI screens, items, components, and views. Top layer of the
package graph — depends on every layer below.

## Overview

`CashlyUI` is the surface a user actually sees. It composes
``CashlyDesignSystem`` primitives against `CashlyStore`s injected via
SwiftUI `@Environment`, and dispatches `ApplicationAction`s back into
the reducer pipeline.

Screens follow a standard shape:

1. `@Environment(CashlyStore<X, Y>.self) var store` for state access.
2. `@Environment(\.actionState)` (per-feature env values) for typed
   read of the current `State`.
3. `@Environment(\.action)` to dispatch `ApplicationAction`.
4. `body` composes `CashlyVStack` / `CashlyList` / `Form` of
   ``CashlyDesignSystem`` primitives.
5. Writes go through `store.cashlyBinding(\.field)` /
   `cashlyMutate(\.field, value)`.

`#if DEBUG` `import CashlyMock` brings preview fixtures; the
SPM-target edge stays unconditional but symbols dead-code-eliminate
out of Release thanks to the import guard. SwiftPM lacks a
debug-only target dep condition, so the linker pass is the only
gate.

## Topics

### Screens

- ``MainScreen``
- ``HomeScreen``
- ``IntelligenceScreen``
- ``CategoryScreen``
- ``DetailCategoryScreen``
- ``TransactionScreen``
- ``AddBudgetScreen``
- ``AddCategoryScreen``
- ``AddTagScreen``
- ``AddTransactionScreen``
- ``AddUserScreen``

### View extensions

- ``SwiftUICore/View/cashly(font:weight:design:)``
- ``SwiftUICore/View/cashly(color:)``
- ``SwiftUICore/View/cashly(tint:)``
- ``SwiftUICore/View/cashly(background:)``
- ``SwiftUICore/View/cashly(clip:)``
- ``SwiftUICore/View/cashlyPadding(_:_:)``
- ``SwiftUICore/View/cashlyRounded()``
- ``SwiftUICore/View/cashly(loading:)``
- ``SwiftUICore/View/cashlyDelete(action:)``
- ``SwiftUICore/View/cashlyEdit(action:)``
- ``SwiftUICore/View/cashlyDismiss(isSaved:)``
- ``SwiftUICore/View/cashlyIntelligence(model:isActive:input:publishEvery:result:)``
