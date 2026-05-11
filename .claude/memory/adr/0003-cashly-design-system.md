# ADR-0003: CashlyDesignSystem — Cashly-owned Vocabulary Layer

**Status**: Accepted
**Date**: 2026-05-11
**Deciders**: Rafael Escaleira

## Context

Wave 5b carved a new SPM target `CashlyDesignSystem` between
`CashlyResource` and `CashlyUI`. Pre-Wave 5b, every `Cashly*` UI symbol
(`CashlyText`, `CashlyButton`, `CashlyColor`, `CashlySpacing`, etc.) was
a thin `public typealias` to a `Ryze*` counterpart living in
`RyzeUI`/`RyzeArchitecture`. Wave 5a froze Ryze at commit `2b619d8` and
ADR-0002 deferred the full Prism migration. Cashly call sites already
spoke `Cashly*` vocabulary, but the symbols still resolved into Ryze —
so a future Prism cutover would break every screen unless we owned the
vocabulary first.

## Decision

CashlyDesignSystem is the **vocabulary boundary**. Every `Cashly*`
symbol consumed by `CashlyUI` is owned by `CashlyDesignSystem`, backed
by native SwiftUI primitives (and a small set of Cashly-owned tokens),
not Ryze re-exports. Ryze remains a transitive dependency only for
two named escape hatches: `CashlyNavigationView` (couples to
`RyzeRouter`/`RyzeRoutable`) and `CashlySystemMonitor` (Mach
CPU/memory probes). Both are tracked for follow-up ports.

## Layering

```
CashlyResource ──┐
                 ├──► CashlyDesignSystem ──► CashlyUI ──► Cashly (app)
Ryze ────────────┘                          CashlyMock
```

- CashlyDesignSystem depends on: SwiftUI, CashlyResource, Ryze (transient).
- CashlyUI imports CashlyDesignSystem via `@_exported import` so screen
  files keep working without source-level changes.
- CashlyMock depends on CashlyDesignSystem (was Ryze) for the
  `Self: CashlyView` constraint on `cashlyPreview()`.

## Cashly-owned symbols

| Symbol | File | Shape |
|---|---|---|
| `CashlyText` | `CashlyText.swift` | View; honors `\.isLoading` env. |
| `CashlySpacer` | `CashlySpacer.swift` | View wrapping `Spacer(minLength:)`. |
| `CashlySymbol` | `CashlySymbol.swift` | View wrapping `Image(systemName:)` + symbol effects. |
| `CashlySpacing` | `CashlySpacing.swift` | `indirect enum`: zero, extra/small/medium/large/extra/ultra, section, negative(self), custom(CGFloat). |
| `CashlyHStack`/`VStack`/`ZStack` | `CashlyStacks.swift` | Thin native stack wrappers taking `CashlySpacing`. |
| `CashlyButton` | `CashlyButton.swift` | Async-action Button with iOS haptic. |
| `CashlyLabel` | `CashlyLabel.swift` | SwiftUI Label honoring `\.isLoading`. |
| `CashlyColor` | `CashlyColor.swift` | `enum`: primary/text/textSecondary/disabled/info/success/warning/error/white/clear/gray/secondary/yellow/background + `color(Color?)` + `hex(String?)`. |
| `Color+Hex` | `Color+Hex.swift` | `init(hex:)` for `#RRGGBB`/`#RRGGBBAA`. |
| `CashlyShape` | `CashlyShape.swift` | `enum: Shape, Sendable`: capsule, circle, rounded(radius:). |
| `CashlyView` | `CashlyView.swift` | `@MainActor` protocol: `mocked()`, `canAppear`. |
| `CashlyCurrencyTextField` | `CashlyCurrencyTextField.swift` | Currency-masked TextField via NumberFormatter. |
| `CashlyList` | `CashlyList.swift` | List wrapper with optional Hashable selection set. |
| `CashlyHorizontalList` | `CashlyHorizontalList.swift` | Horizontal ScrollView with ScrollViewReader. |

## Symbols dropped (unused)

`CashlySize`, `CashlySection`, `CashlyTextField`,
`CashlyTextFieldConfiguration`, `CashlyAsyncImage`,
`CashlyBrowserView`, `CashlyLocale`. None had call sites.

## Symbols still aliased

| Alias | Reason |
|---|---|
| `CashlyNavigationView = RyzeNavigationView` | Couples to `RyzeRouter<Route: RyzeRoutable>`. Porting requires owning the routing protocol stack first — scheduled as part of Wave 5a real merge. |
| `CashlySystemMonitor = RyzeSystemMonitor` | Mach CPU/memory probes. Lift planned in Wave 8 (observability). |

## Modifier surface (View+Extension.swift)

The `.cashly(...)` modifier family was rewritten to consume native
SwiftUI primitives instead of forwarding to `.ryze(...)`:

- `cashly(color:)` → `foregroundStyle(CashlyColor.resolved)`
- `cashly(tint:)` → `tint(CashlyColor.resolved)`
- `cashly(background:)` → `background(CashlyColor.resolved)`
- `cashly(clip:)` → `clipShape(CashlyShape)`
- `cashly(alignment:)` → `multilineTextAlignment(_:)`
- `cashlyPadding(_:_:)` → `padding(_:CashlySpacing.rawValue)`

Modifiers still forwarding to Ryze: `cashly(font:weight:design:)`,
`cashly(loading:)`, `cashlyBackgroundItem()`, `cashly(if:)`,
`cashly(item:)`, `cashlyConfetti(...)`, `cashly(symbol:...)`,
`cashly(systemMonitor:)`. These piggyback on Ryze view modifiers that
have non-trivial behavior; planned for incremental port after the
Prism cutover lands.

## Consequences

**Positive**
- Prism cutover (Wave 5a real merge) no longer requires touching any
  `CashlyUI` screen. The Ryze→Prism swap will only affect
  CashlyDesignSystem's two remaining aliases plus the architecture
  modules (`CashlyPresentation`).
- Vocabulary now matches the product name. Snapshots, semantics, and
  defaults are auditable inside Cashly's own repo.
- `CashlyColor` enum surfaces every semantic token used by the app
  (audited via grep across CashlyUI) — drift-resistant.

**Negative**
- One extra SPM target to keep building. Mitigated: target is small,
  source-only, no resources.
- Two named aliases (`CashlyNavigationView`, `CashlySystemMonitor`)
  still tie CashlyUI to Ryze transitively. Tracked in this ADR.
- `CashlyShape` is `Sendable` enum, no longer wraps arbitrary
  `Shape`. Acceptable: every call site uses one of the three named
  factories.

## Follow-ups

- G034 (new): port `CashlyNavigationView` after CashlyRouter port.
- G035 (existing): lift `CashlySystemMonitor` into
  CashlyDesignSystem/Observability during Wave 8.
- Rewrite remaining `.cashly(...)` modifiers (font/loading/if/item/
  confetti/symbol) to native SwiftUI after Prism cutover.

## References

- ADR-0001 — adoption of Apple Dev Setup
- ADR-0002 — Wave 5 Ryze→Prism spike
- `.claude/memory/migration/gap-analysis.md` — G022, G033 still open
