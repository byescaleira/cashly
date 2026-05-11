# ``CashlyDesignSystem``

Vocabulary layer for Cashly UI. Cashly-owned SwiftUI primitives, tokens,
and routing types that screens and items compose against.

## Overview

`CashlyDesignSystem` sits between `CashlyResource` and `CashlyUI` in the
package graph and is the only place Cashly screens import to access
visual primitives. Every public symbol here is owned by Cashly — none
are typealiases to external libraries — so a future swap of the
underlying state-management or theming library only touches this
module.

The module ships:

- **Views**: ``CashlyText``, ``CashlyLabel``, ``CashlySymbol``,
  ``CashlySpacer``, ``CashlyHStack``, ``CashlyVStack``, ``CashlyZStack``,
  ``CashlyList``, ``CashlyHorizontalList``, ``CashlyButton``,
  ``CashlyCurrencyTextField``.
- **Tokens**: ``CashlyColor``, ``CashlyShape``, ``CashlySpacing``.
- **Navigation**: ``CashlyRoutable``, ``CashlyNavigationStyle``,
  ``CashlyRouter``, ``CashlyNavigationView``.
- **Observability**: ``CashlySystemMonitor`` and its modifier.
- **Confetti overlay**: ``cashlyConfetti(amount:seconds:isActive:)``.

## Topics

### Text & symbols

- ``CashlyText``
- ``CashlyLabel``
- ``CashlySymbol``

### Layout

- ``CashlySpacer``
- ``CashlyHStack``
- ``CashlyVStack``
- ``CashlyZStack``
- ``CashlySpacing``

### Lists

- ``CashlyList``
- ``CashlyHorizontalList``

### Controls

- ``CashlyButton``
- ``CashlyCurrencyTextField``

### Color & shape tokens

- ``CashlyColor``
- ``CashlyShape``

### Navigation

- ``CashlyRoutable``
- ``CashlyNavigationStyle``
- ``CashlyRouter``
- ``CashlyNavigationView``

### View

- ``CashlyView``

### Observability

- ``CashlySystemMonitor``

### Loading state

- ``SwiftUICore/EnvironmentValues/isLoading``
