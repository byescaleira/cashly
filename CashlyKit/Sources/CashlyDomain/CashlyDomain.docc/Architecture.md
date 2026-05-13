# Cashly Architecture

A bird's-eye view of how the 7 SPM targets interact and where each
responsibility lives.

## Targets

- **CashlyDomain** — pure Swift entities, use case protocols, finance
  rules. No frameworks.
- **CashlyData** — SwiftData `@ModelActor` + StoreKit 2 + platform
  services. Implements every Domain protocol.
- **CashlyPresentation** — Prism stores, reducers, middlewares,
  state types, deeplink routes.
- **CashlyUI** — SwiftUI screens. Reads stores, dispatches actions.
- **CashlyDesignSystem** — typography, colors, iconography primitives.
- **CashlyResource** — strings, fixtures, logging, analytics,
  crash reporting.
- **CashlyMock** — in-memory factory + fixtures for previews & tests.

## Data flow

```
SwiftUI View  →  PrismStore.handle(action)
              ↓
          Reducer       (pure, synchronous)
              ↓
        Middleware      (async effects, factory-injected)
              ↓
       Use Case (Data)  (SwiftData / StoreKit / Network)
              ↓
        Domain model    ← AdapterActor
              ↓
       store.state      (Observable, drives the View)
```

## Composition root

``CashlyDataFactory`` builds every concrete use case once at app boot
and passes them into the Presentation factory, which assembles the
PrismStore. Tests use ``MockCashlyFactory`` to swap in-memory
implementations without touching SwiftData / StoreKit.

## Platform services (Eixo H)

Each platform integration follows the same shape: Domain protocol →
production impl in CashlyData → in-memory fallback for tests/macOS →
factory wires.

| Concern | Protocol | Production | Fallback |
|---|---|---|---|
| Spotlight | ``SpotlightIndexerUseCase`` | ``CoreSpotlightIndexer`` | ``InMemorySpotlightIndexer`` |
| Reachability | ``ReachabilityUseCase`` | ``NWPathReachabilityService`` | ``InMemoryReachabilityService`` |
| Sync status | ``SyncStatusUseCase`` | ``UserDefaultsSyncStatus`` | (same) |
| Budget alerts | ``BudgetAlertsUseCase`` | ``UserNotificationsBudgetAlerts`` | ``InMemoryBudgetAlerts`` |
| App icon | ``AppIconUseCase`` | ``UIKitAppIconService`` | ``InMemoryAppIconService`` |
| Feature flags | ``FeatureFlagsUseCase`` | ``UserDefaultsFeatureFlags`` | ``InMemoryFeatureFlags`` |
| Background refresh | ``BackgroundRefreshUseCase`` | ``BGTaskBackgroundRefresh`` | ``InMemoryBackgroundRefresh`` |

## Deeplinks & Quick Actions

``MainDeeplink`` resolves three external entry points to a
``MainRoute``:

- `cashly://` URLs
- `NSUserActivity` from Spotlight (`CSSearchableItemActionType`)
- `UIApplicationShortcutItem` identifiers from Home-screen quick
  actions

`AppDelegate` and `PendingShortcutAction` bridge UIKit launch
callbacks back into SwiftUI's `scenePhase` cycle.
