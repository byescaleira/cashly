# ADR-0008: Performance signposts placement

**Status**: Accepted
**Date**: 2026-05-13
**Deciders**: Rafael Escaleira

## Context

H10 called for an Instruments-driven performance audit. Without a
device trace, we instead defined which hot paths must be wrapped in
`OSSignposter` intervals so any future Instruments run produces
useful labelled traces out of the box.

## Decision

Wrap the following hot paths in `CashlySignpost.withInterval(name:)`:

| Path | Signpost name | Why |
|---|---|---|
| `MainState.score` getter | `MainState.score` | computed on every state replay; touches every transaction |
| `MainMiddleware.fetch` | `MainMiddleware.fetch` | composite fetch — users, categories, budgets, transactions, tags, predictions, all in one effect |

Future signposts (TBD when Instruments trace available):

- `TransactionActor.getTransactions` — single biggest query.
- `CashlyIntelligenceService.train` — model training cold path.
- `CoreSpotlightIndexer.index(transactions:)` — runs on every state
  diff.
- `InsightsScreen.chartAggregation` — Swift Charts data prep.

## Naming convention

`<Layer>.<entryPoint>` — colons reserved for ad-hoc child intervals.
Names must be stable string literals so signpost regex filters in
Instruments stay valid across releases.

## Consequences

- Instruments traces ship labelled without needing per-PR manual
  signpost work.
- Zero release-build cost: `OSSignposter` collapses to a no-op when
  no profiler is attached.
- Adds a thin `CashlyResource` dependency to `CashlyPresentation` —
  already present transitively, formalised by this ADR.
