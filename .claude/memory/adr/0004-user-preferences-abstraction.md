# ADR-0004: UserPreferences Abstraction — Decouple UserActor from UserDefaults

**Status**: Accepted
**Date**: 2026-05-11
**Deciders**: Rafael Escaleira

## Context

Pre-Wave A1, `UserActor` (SwiftData-backed `UserUseCase`) reached
directly into `UserDefaults.standard` to remember the *currently
selected* user. Two coupled concerns lived in one actor:

1. CRUD over `UserEntity` rows (real SwiftData persistence).
2. A single "current user id" pointer (UserDefaults string).

Three problems followed:

- **Testability**: tests could not exercise current-user logic without
  polluting `.standard` UserDefaults. No seam to inject a fake store.
- **Concurrency**: the `@ModelActor` macro fixes the init signature to
  `init(modelContainer:)`. There was no place to thread in an
  alternative preferences source.
- **Storage format**: the legacy implementation persisted the *full
  encoded `User` blob* under `cashly.user`. Reading current user
  required decoding a `User` just to grab the id, which kept stale
  copies of name/photo around forever (no refresh after edit).

## Decision

Split the two concerns. Introduce a new domain protocol
`UserPreferencesUseCase` for the pointer concern only, and inject it
into `UserActor`.

```swift
public protocol UserPreferencesUseCase: Sendable {
    func currentUserId() async -> String?
    func setCurrentUserId(_ id: String) async
    func clearCurrentUserId() async
}
```

- Domain owns the protocol (`CashlyDomain/Use Cases/`).
- Data owns the production impl `UserDefaultsUserPreferences` (actor),
  which stores a plain string under `cashly.user.id` and migrates the
  legacy `cashly.user` blob on first read.
- Mock owns `InMemoryUserPreferences` for tests/previews.
- `UserActor` drops the `@ModelActor` macro and conforms to
  `ModelActor` manually, so the init can accept both
  `modelContainer` and `preferences`. Other actors keep the macro.
- `UserUseCase` keeps its surface (`getCurrentUser`, `selectUser`)
  unchanged — callers in middlewares are untouched.

## Migration path

`UserDefaultsUserPreferences.currentUserId()` checks the new key
first; if absent, it decodes the legacy `cashly.user` blob, extracts
the id, writes it under `cashly.user.id`, and returns it. The legacy
blob is left in place until `clearCurrentUserId()` runs (which wipes
both keys). After one read on a previously-installed app, the new key
takes over and the legacy decode path is never re-entered.

## Consequences

**Good**:
- Tests can inject `InMemoryUserPreferences` and assert without
  touching `.standard`.
- UserActor no longer carries UserDefaults knowledge — Data → Foundation
  coupling shrank to one actor.
- Future preference storage swaps (Keychain for sensitive ids, iCloud
  KVS for cross-device sync) only touch the new actor, not UserActor.
- Stored format is now a tiny string, not an encoded entity.

**Trade-offs**:
- `UserActor` no longer uses `@ModelActor` macro; it implements the
  protocol manually (~6 lines of init boilerplate). Worth it for the
  injection seam.
- One extra protocol in Domain and one extra factory method on
  `CashlyDataFactoryProtocol`.

## Alternatives considered

1. **Keep UserDefaults inside UserActor, add a test seam via init
   parameter.** Rejected: still couples Data → UserDefaults, and the
   macro blocks new init params anyway.
2. **Move current-user id into SwiftData as a singleton row.**
   Rejected: SwiftData CloudKit sync would replicate a per-device UX
   selection across devices, which is wrong.
3. **Drop the abstraction; just inline `UserDefaults.standard` access
   into a private struct.** Rejected: same test pollution problem.

## Follow-ups

- B-axis Wave B1 will reuse this pattern for `FeatureFlagPreferences`
  / `SubscriptionPreferences` (StoreKit 2 entitlement caching).
- If we adopt iCloud KVS or App Group sharing, swap the impl behind
  the same protocol — no callsite changes.
