# ``CashlyDomain``

Pure Swift domain layer: entities, use case protocols, and finance
business rules. No SwiftUI, no SwiftData, no UI concerns.

## Overview

`CashlyDomain` defines what Cashly is *about*:

- **Entities** describe persisted nouns — Budget, Category,
  Transaction, Tag, User, Participant.
- **Use Case** protocols describe what each persistence-bound surface
  can do; concrete implementations (SwiftData @ModelActor) live in
  CashlyData.
- **Domain types** like ``Score``, ``BalanceScore``,
  ``TransactionStatus``, ``TransactionSplitMode`` encode rules
  (cutoffs, reversals, split math) without depending on any
  framework.
- **Errors**: ``CashlyError`` is the umbrella type returned by domain
  APIs; it wraps ``PersistenceError`` and ``DomainError`` for typed
  recovery + leaves the legacy `.onFetch / .onSave / .onRemove` cases
  in place for compatibility.

Every entity refines ``CashlyEntity`` — a `PrismEntity & Identifiable
& Sendable` protocol — so models can flow through SwiftConcurrency
boundaries (Prism middleware effects, MainActor stores) without
isolation crosses.

## Topics

### Entities

- ``Budget``
- ``Category``
- ``Transaction``
- ``Tag``
- ``User``
- ``Participant``

### Transaction enums

- ``TransactionStatus``
- ``TransactionSplitMode``

### Scoring

- ``Score``
- ``ScoreLevel``
- ``BalanceScore``

### Use Cases

- ``BudgetUseCase``
- ``CategoryUseCase``
- ``UserUseCase``
- ``TransactionUseCase``
- ``TagUseCase``
- ``ParticipantUseCase``
- ``AdapterUseCase``

### Errors

- ``CashlyError``
- ``PersistenceError``
- ``DomainError``

### Intelligence

- ``CashlyIntelligence``
- ``CashlyIntelligenceModel``
- ``CashlyPrediction``
- ``CashlyPredictionResult``
- ``CashlyPredictionInput``
- ``CashlyTabularData``

### Factories

- ``CashlyDataFactoryProtocol``

### Protocol shorthand

- ``CashlyEntity``
