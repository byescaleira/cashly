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
  recovery. The legacy `.onFetch / .onSave / .onRemove` cases were
  retired in Wave A3 — every callsite now emits the typed variants.
- **Preferences & Subscription**:
  ``UserPreferencesUseCase`` abstracts the "current user" pointer
  away from `UserDefaults`. ``SubscriptionUseCase`` and
  ``FeatureGateUseCase`` model the StoreKit 2-backed Pro tier and
  the Free/Pro decision matrix that drives both the paywall and
  middleware gating.

Every entity refines ``CashlyEntity`` — a `PrismEntity & Identifiable
& Sendable` protocol — so models can flow through SwiftConcurrency
boundaries (Prism middleware effects, MainActor stores) without
isolation crosses.

## Topics

### Articles

- <doc:Architecture>

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
- ``UserPreferencesUseCase``
- ``TransactionUseCase``
- ``TagUseCase``
- ``ParticipantUseCase``
- ``AdapterUseCase``
- ``SubscriptionUseCase``
- ``FeatureGateUseCase``

### Platform Use Cases (Eixo H)

- ``SpotlightIndexerUseCase``
- ``ReachabilityUseCase``
- ``SyncStatusUseCase``
- ``BudgetAlertsUseCase``
- ``AppIconUseCase``
- ``FeatureFlagsUseCase``
- ``BackgroundRefreshUseCase``
- ``FeatureFlag``

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

### Subscription

- ``SubscriptionTier``
- ``SubscriptionPlan``
- ``SubscriptionStatus``
- ``PurchaseOutcome``
- ``FeatureGate``
- ``FeatureGateDecision``
- ``FeatureGateLimits``

### Factories

- ``CashlyDataFactoryProtocol``

### Protocol shorthand

- ``CashlyEntity``
