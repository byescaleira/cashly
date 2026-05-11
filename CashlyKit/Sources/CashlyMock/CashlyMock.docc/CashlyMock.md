# ``CashlyMock``

DEBUG-only test + preview fixtures. Mock implementations of every
Domain Use Case + SwiftUI preview helpers.

## Overview

`CashlyMock` is meant to be `#if DEBUG`-imported. It ships:

- ``MockCashlyFactory`` — in-memory `ModelContainer` + mock actor
  implementations (``MockBudgetActor``, ``MockCategoryActor``,
  ``MockUserActor``, ``MockTransactionActor``, ``MockTagActor``,
  ``MockParticipantActor``, ``MockAdapterActor``). Used by tests and
  SwiftUI previews to bootstrap a working store graph.
- Per-entity `PrismMock` extensions seeded from `CashlyResource`
  JSON: `User.mocks`, `Budget.mocks`, `Tag.mocks`, etc.
- ``MockModifier`` — a SwiftUI view modifier that wires every store
  into the environment so previews can render screens identically to
  production composition.
- The static ``SwiftUICore/View/cashlyPreview()`` (`Self: CashlyView`)
  helper that wraps a view in the modifier.

## Topics

### Factory

- ``MockCashlyFactory``

### Mock actors

- ``MockAdapterActor``
- ``MockBudgetActor``
- ``MockCategoryActor``
- ``MockUserActor``
- ``MockTransactionActor``
- ``MockTagActor``
- ``MockParticipantActor``

### Preview modifier

- ``MockModifier``
