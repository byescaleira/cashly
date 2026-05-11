# ADR-0005: Typed CashlyError — Kill Legacy onFetch/onSave/onRemove

**Status**: Accepted
**Date**: 2026-05-11
**Deciders**: Rafael Escaleira

## Context

`CashlyError` historically carried three opaque cases —
`.onFetch`, `.onSave`, `.onRemove` — alongside the structured wrappers
`.persistence(PersistenceError)` and `.domain(DomainError)`. The
typed variants existed but every middleware still emitted the legacy
cases, so the state never carried entity, id, underlying reason, or
the difference between a validation failure and a disk error. UI and
analytics had no way to branch by category.

Pre-A3 callsites:

```swift
send(.error(.onSave))  // is this validation? disk? not found?
```

## Decision

1. Delete the three legacy cases from `CashlyError`. No deprecation
   ramp — the codebase is small enough to migrate in one pass.
2. Map every middleware emission to the right typed variant by
   intent:
   - **Catch from a use-case throw** → `.persistence(.fetchFailed |
     .saveFailed | .removeFailed)` with `entity` + `underlying:
     error.localizedDescription`.
   - **Guard fail because input is bad** (`name.count < 3`, invalid
     URL, missing required field, amount ≤ 0) →
     `.domain(.invalidInput(field:reason:))`.
   - **Guard fail because dependent rows exist** (deleting a budget
     with transactions, a user with categories) →
     `.domain(.businessRuleViolated(rule:))`.
   - **Guard fail because the target doesn't exist** →
     `.persistence(.notFound(entity:id:))`.
3. Update all tests to pattern-match at the **category** level
   (`.persistence(.saveFailed)` / `.domain(.invalidInput)`) — keeps
   intent visible without coupling tests to the entity string.

## Examples (post-migration)

```swift
// AddUserMiddleware.save
guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
    send(.error(.domain(.invalidInput(field: "name", reason: "Name must be at least 3 characters."))))
    return
}
// ...
} catch {
    send(.error(.persistence(.saveFailed(entity: "User", underlying: error.localizedDescription))))
}
```

```swift
// AddBudgetMiddleware.remove
guard let budget = try await budgetUseCase.getBudget(id: state.id) else {
    send(.error(.persistence(.notFound(entity: "Budget", id: state.id))))
    return
}
guard transaction.isEmpty else {
    send(.error(.domain(.businessRuleViolated(rule: "Budget has related transactions."))))
    return
}
```

## Consequences

**Good**:
- Errors are now actionable. Analytics can split by category. Future
  paywall/quota errors (Wave B2) plug into `.domain` without
  inventing yet another umbrella case.
- `failureReason` carries the underlying message, so production logs
  can correlate with SwiftData errors.
- Tests assert the right *kind* of failure, not just "something failed."

**Trade-offs**:
- All ~40 callsites changed in one commit — large diff. Acceptable
  here because the legacy cases were never user-facing strings (no
  localization keys to migrate).
- Pattern matching at the category level is slightly verbose
  (`.error(.persistence(.saveFailed))` vs `.error(.onSave)`). Worth
  it for the type-safety.

## Alternatives considered

1. **Deprecate-then-delete in two waves.** Rejected: the legacy cases
   already had typed siblings, deprecation would just add a third
   parallel path during transition.
2. **Collapse to a single `case error(category: ErrorCategory, ...)`
   with associated values for everything.** Rejected: two-level enum
   is clearer at switch sites and Swift's exhaustiveness check works
   nicely with `.persistence(.fetchFailed)`.

## Follow-ups

- Wave A4 may add `.intelligence(IntelligenceError)` when
  CashlyIntelligence gets typed failures (model load, prediction
  empty).
- Wave B2 (feature gating) will likely add
  `.domain(.featureGated(feature:))` or a sibling category for
  paywall triggers.
