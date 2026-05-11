# ``CashlyResource``

Bundled resources + cross-cutting helpers. String catalog, mock JSON
fixtures, image lookup, logging + signpost infrastructure.

## Overview

`CashlyResource` is the leaf module that every other layer imports for
shared bits that don't fit anywhere else:

- ``CashlyL10n`` — typed access to `Localizable.xcstrings` keys.
- ``CashlyResourceFile`` / ``CashlyResourceImage`` — typed paths to
  bundled JSON fixtures and image assets.
- ``CashlyLogger`` — per-subsystem `os.Logger` instances
  (`.data`, `.domain`, `.presentation`, `.ui`, `.intelligence`,
  `.app`) under the `com.cashly.app` subsystem.
- ``CashlySignpost`` — `OSSignposter` wrapper that hot paths use to
  emit Instruments-visible intervals.
- ``AnalyticsTracker`` — protocol injected at the composition root so
  the bulk of the codebase stays vendor-agnostic;
  ``NoopAnalyticsTracker`` covers tests/previews.

## Topics

### Strings

- ``CashlyL10n``

### Files & images

- ``CashlyResourceFile``
- ``CashlyResourceImage``

### Observability

- ``CashlyLogger``
- ``CashlySignpost``

### Analytics

- ``AnalyticsTracker``
- ``NoopAnalyticsTracker``
