# ``CashlyData``

SwiftData persistence + on-device intelligence training. Concrete
implementations of every Domain Use Case protocol.

## Overview

Every Use Case declared in CashlyDomain has a `@ModelActor`
implementation here:

- ``BudgetActor`` / ``CategoryActor`` / ``TransactionActor`` /
  ``UserActor`` / ``TagActor`` / ``ParticipantActor`` — each is
  isolated to a SwiftData `ModelContext` and routes domain reads
  through ``AdapterActor`` to materialize Domain models from
  `@Model` entities.
- ``CashlyDataFactory`` — composition root for the actors. Builds
  the `ModelContainer` once and hands each actor its own
  `ModelContext`. Marked `@MainActor` because PrismStore (which
  consumes the factory output) is MainActor-bound.
- ``CashlyIntelligenceService`` — wraps PrismTabularIntelligence /
  PrismTextIntelligence training so CashlyDomain stays
  infrastructure-free.

The SwiftData entities (`BudgetEntity`, `CategoryEntity`, etc.) are
private to this target; consumers only see the Domain values returned
by the adapter.

## Topics

### Composition root

- ``CashlyDataFactory``

### Persistence actors

- ``BudgetActor``
- ``CategoryActor``
- ``TransactionActor``
- ``UserActor``
- ``TagActor``
- ``ParticipantActor``

### Adapter

- ``AdapterActor``

### Intelligence

- ``CashlyIntelligenceService``

### Subscription

- ``StoreKitSubscriptionService``
- ``DefaultFeatureGate``

### Preferences

- ``UserDefaultsUserPreferences``
- ``UserDefaultsFeatureFlags``
- ``InMemoryFeatureFlags``

### Platform services (Eixo H)

- ``CoreSpotlightIndexer``
- ``InMemorySpotlightIndexer``
- ``NWPathReachabilityService``
- ``InMemoryReachabilityService``
- ``UserDefaultsSyncStatus``
- ``UserNotificationsBudgetAlerts``
- ``InMemoryBudgetAlerts``
- ``UIKitAppIconService``
- ``InMemoryAppIconService``
- ``BGTaskBackgroundRefresh``
- ``InMemoryBackgroundRefresh``
