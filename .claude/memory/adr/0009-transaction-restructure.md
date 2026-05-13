# ADR-0009: Transaction restructure — break Budget FK, add kind + needsReview

**Status**: Accepted
**Date**: 2026-05-13
**Deciders**: Rafael Escaleira

## Context

The current SwiftData graph is:

```
Category  ◄── Budget  ◄── Transaction  ◄── Participant
                                ▲
                                └── Tag (M:N)
```

Three problems surface as we add features:

1. **Transaction ↔ Budget hard FK** forces every transaction to live
   inside a budget. A transaction without a matching budget can't be
   persisted, which blocks income / standalone spending and any
   spending in a month that has no budget configured yet.
2. **No income or loan tracking.** Cashly today is expense-only.
   Users need to register income, and also "I lent X to Y" entries
   that count as expense until repaid, then stop counting.
3. **No "needs review" signal** for transactions captured from a
   future Apple-Intelligence dictation flow that may leave some
   fields missing.

## Decision

### 1. Break the Transaction → Budget FK

- Transaction stores `category: Category` directly.
- Budget ↔ Transaction correlation is derived: a budget for
  `(category, yearMonth)` aggregates every transaction whose
  `category.id == budget.category.id` AND
  `yearMonth(transaction.date) == budget.date`.
- A Domain helper does the predicate:
  `Budget.transactions(in:) -> [Transaction]` and
  `Budget.spent(in:) -> Double`.
- Existing fetch APIs that accept `budgets: [String]` switch to
  accepting `categories: [String]` + `date: Date` (which they
  already accept in some cases).

### 2. Add `TransactionKind`

```swift
public enum TransactionKind: Int, CaseIterable, Sendable, Codable {
    case expense = 0   // default — matches current behavior
    case income = 1
    case loan = 2      // counts as expense until status == .settled
}
```

- `Transaction.kind: TransactionKind` (default `.expense` on migrate).
- Aggregation rules:
  - `.expense` → sums into `Budget.spent` and Insights spending charts.
  - `.income` → never sums into spending; surfaces in its own
    "Income" report / chart series.
  - `.loan` → sums into `Budget.spent` while
    `status ∈ {.pendingToPay, .pendingToReceive}`; stops summing once
    `status == .settled`. `.canceled` also stops summing.
- UI filter chips gain a kind selector.

### 3. Add `needsReview`

- `Transaction.needsReview: Bool` (default `false`).
- Set to `true` by the dictation flow when one or more required
  fields (amount, category, summary, date) couldn't be inferred from
  the spoken utterance.
- Render with a badge in lists; tapping opens edit screen so the
  user fills the gaps and toggles the flag off.

### 4. Installments stay derived

- Keep `paymentsPlan: Int?` as today.
- One Transaction row represents N installments; UI + score
  computation expand virtually via
  `Transaction.installments() -> [Date]`.
- Edits stay centralized — change once, applies to every derived
  month. Matches user preference recorded 2026-05-13.

### 5. Apple Intelligence dictation (separate ondas)

- J8 lands the `TransactionDictationUseCase` protocol + an in-memory
  keyword stub for tests. No UI, no on-device LLM.
- J9 (later) adds the Foundation Models impl behind iOS 18.1
  availability. J10 wires Speech.framework + mic button.

## Migration strategy

**Path chosen**: SwiftData VersionedSchema + MigrationPlan in one
release wave (J1 boilerplate, J2 schema change + backfill). Reasons:

- CloudKit users may already have data; a wipe loses it.
- VersionedSchema is the documented Apple path, even if more code.
- Backfill is mechanical:
  `transaction.category = transaction.budget?.category ?? nil` and
  `transaction.kind = .expense` and
  `transaction.needsReview = false`.

After backfill the Budget FK column on TransactionEntity can be
dropped. Domain-side `Transaction.budget` goes away in J3.

## Wave plan

| Onda | Scope |
|---|---|
| J1 | VersionedSchema + MigrationPlan scaffolding, both versions empty diff |
| J2 | TransactionEntity v2: add category/kind/needsReview, backfill, drop budget |
| J3 | Domain: TransactionKind enum, Transaction shape change, installment helper |
| J4 | MainState computeds: Budget.spent via date+category predicate |
| J5 | AddTransactionScreen rework (kind picker, category direct, needsReview) |
| J6 | Filter chip for kind |
| J7 | Installment rendering helper + UI usage |
| J8 | TransactionDictationUseCase protocol + InMemory stub + factory wires |

J9 / J10 (Apple Intelligence dictation + mic) live in a follow-up ADR.

## Consequences

**Positive**

- Transactions can exist without a budget for that month.
- Income + loan tracking unlock a real "monthly summary" view.
- Budget aggregation becomes a pure function of (category, month) —
  easier to reason about, easier to memoize.
- needsReview gives the dictation flow a graceful degradation path.

**Negative**

- Schema migration is the highest-risk change in the project so far.
  Mitigation: V1 + V2 unit tests with a hand-rolled fixture
  ModelContainer before touching production data.
- Budget.spent becomes O(N) over transactions per render. Mitigation:
  same MainState pre-aggregation that already caches
  `transactionsAmountByCategory` (just keyed differently).
- Removes a property AdapterActor / TransactionActor depend on
  (`transaction.budget`). Every callsite needs an update — touches
  AddTransactionMiddleware, MainState, Insights.

**Neutral**

- Loan terminal semantics piggyback on existing `.settled` —
  no new TransactionStatus case.

## References

- User decisions captured 2026-05-13:
  - Installments: 1 row + derived aggregate
  - Loan: counts as expense until settled, then stops
  - Dictation: protocol + stub only in this batch
  - Strategy: ADR-first, then implement
