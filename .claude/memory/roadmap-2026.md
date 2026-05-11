# Cashly Roadmap 2026

Post-migration roadmap. Migration completa em Wave 5/6. Próxima fase
foca em **refactor arquitetural** (primário) + **freemium + Pro
subscription** (secundário). Gamificação está fora-de-escopo nesta
fase.

Cada wave abaixo segue o padrão Wave 5/6:
- **Goal**: o que muda
- **Why**: motivação
- **Scope in / out**: limites
- **Definition of Done**: gates de pronto
- **Deps**: dependências
- **ADR**: documenta decisão se não-trivial

---

## Eixo A — Refactor Arquitetural

### Wave A1 — UserDefaults → Domain UserPreferences

**Goal**: Eliminar `UserDefaults.standard` direto em `UserActor`.
Adapter para preferências persistentes.

**Why**: `UserActor.getCurrentUser()` faz I/O direto em
`UserDefaults.standard.data(forKey: "cashly.user")`. Acopla camada
Data ao mecanismo de preferences, dificulta testes, viola
Single-Responsibility.

**Scope in**:
- New `UserPreferencesUseCase` protocol em Domain (get/set
  current user id).
- Concrete `UserDefaultsUserPreferences` em Data (UserDefaults-
  backed, conforming to protocol).
- `UserActor.getCurrentUser` recebe preferences via init, delega.
- Mock no `CashlyMock` (in-memory dictionary).
- Tests: roundtrip get/set, default value, conflict resolution.

**Scope out**: Migração para Keychain (futuro), iCloud KVStore sync.

**Definition of Done**:
- Zero `UserDefaults` em Data layer (só em concrete impl).
- UserActor.getCurrentUser não toca UserDefaults direto.
- Tests verde + 3-5 novos cases para Preferences.

**Deps**: nenhuma.

**ADR**: 0004 — UserPreferences abstraction.

---

### Wave A2 — Effects layer (cancellable middleware tasks)

**Goal**: Adicionar cancelamento explícito de effects in-flight.
Hoje, mudança rápida de tela enquanto middleware ainda roda pode
emitir actions stale após o usuário sair.

**Why**: `PrismStore.cancelEffects()` existe mas Cashly nunca chama.
Background fetches continuam mesmo após dismiss. Memory leak
potencial em sequências rápidas.

**Scope in**:
- View `.onDisappear { store.cancelEffects() }` em screens com
  middleware-heavy paths (HomeScreen, IntelligenceScreen).
- Middleware tasks usando `Task.checkCancellation()` em loops.
- AddTransactionMiddleware.save: cancel se user navigates away
  durante save.

**Scope out**: Cancellation tokens custom (PrismEffect já oferece).

**Definition of Done**:
- Cancel hooks em todas screens com fetch background.
- Stress test: rapid navigation não gera state mutations post-
  dismiss.

**Deps**: nenhuma.

**ADR**: nenhum (segue padrão Prism existente).

---

### Wave A3 — Domain error refactor: kill legacy cases

**Goal**: Remover legacy cases `.onFetch / .onSave / .onRemove` de
`CashlyError`. Tudo passa por `.persistence(_:)` / `.domain(_:)` /
`.unknown(_:)`.

**Why**: Legacy cases viraram catch-all sem contexto. Bug reports
não diferenciam "save failed because validation" vs "save failed
because disk full". 3 cases vs 11+ typed variants.

**Scope in**:
- Migrar middleware emissions de `.error(.onSave)` para
  `.error(.persistence(.saveFailed(entity:underlying:)))` ou
  `.error(.domain(.invalidInput(field:reason:)))`.
- Atualizar `CashlyError.description` fallback.
- Remover cases legacy + 3 tests legacy em CashlyErrorTests.
- Adicionar tests novos para every typed variant em context.

**Scope out**: Localized error messages (já delega para
errorDescription).

**Definition of Done**:
- Zero refs a `.onFetch / .onSave / .onRemove` em middlewares.
- CashlyError enum tem apenas 3 cases (persistence/domain/unknown).
- Snapshot baselines não mudam (UI usa errorDescription).

**Deps**: nenhuma.

**ADR**: nenhum.

---

### Wave A4 — Split CashlyIntelligence enum from typealiases

**Goal**: Domain `CashlyIntelligence` enum vive em
`CashlyDomain/Models/`. Typealiases (`CashlyIntelligenceModel`,
`CashlyPrediction`, etc.) migram para `CashlyData` onde concrete
training implementations consumem.

**Why**: Domain hoje declara typealiases que apontam para
PrismIntelligence types. Acoplamento Domain→PrismIntelligence
(infra). Mover typealiases mantém Domain puro.

**Scope in**:
- Domain: keep enum `CashlyIntelligence` (cases + display).
- Data: move typealiases + `extension
  PrismIntelligencePredictionInput: @retroactive @unchecked
  Sendable`.
- Update Presentation imports.

**Scope out**: PrismIntelligence rewrite (não é nosso).

**Definition of Done**:
- Domain importa apenas Foundation + (talvez) PrismFoundation.
- PrismIntelligence import desaparece de Domain.
- Tests passing.

**Deps**: nenhuma.

**ADR**: 0005 — Intelligence typealiases migrate to Data.

---

### Wave A5 — God-files final: AddBudgetScreen split

**Goal**: 4 screens ainda > 220 lines (AddBudget 242, AddCategory
236, AddTag 225, FilterItemView 259). Split into per-section
files seguindo pattern de HomeScreen+*.swift / AddTransaction+*.

**Why**: Convention diz <= 200 lines (per `.claude/memory/
conventions.md`). 4 telas violam. Split melhora navegação e
isolamento.

**Scope in**:
- AddBudgetScreen → +Sections / +ItemViews / +Toolbar.
- AddCategoryScreen → +Sections / +ItemViews / +Toolbar.
- AddTagScreen → +Sections / +ItemViews / +Toolbar.
- FilterItemView → +Date / +Categories / +Tags / +Statuses.

**Scope out**: Combine into shared "Add*Screen base" (premature).

**Definition of Done**:
- Zero files > 200 lines em CashlyUI.
- Snapshots green (não muda renderização).

**Deps**: nenhuma.

**ADR**: nenhum.

---

### Wave A6 — `CashlyReplaceableAction` strict-Sendable State

**Goal**: Garantir todo State `Sendable` strict, não `@unchecked`.
Audit + fix remaining cross-isolation issues.

**Why**: PrismMiddleware effects capturam State em closures
`@Sendable`. Se State contém non-Sendable type (ex.
CashlyRouter), warning silencia hoje. Strict mode quebra.

**Scope in**:
- Audit cada State struct para Sendable conformance strict.
- MainState carrega `CashlyRouter<MainRoute>` — verificar
  isolation. Provavelmente extrair routers para um Env separado.
- Build com `swift -strict-concurrency=complete` para flagar.

**Scope out**: Migration para Strict Concurrency total (já tá).

**Definition of Done**:
- Zero `@unchecked Sendable` em States.
- Build com strict concurrency clean.

**Deps**: nenhuma.

**ADR**: 0006 — MainState router extraction.

---

## Eixo B — Monetização (Freemium + Pro Subscription)

### Wave B1 — Subscription infrastructure (StoreKit 2)

**Goal**: Foundation para Pro subscription. Sem features-pagas
ainda — só infra.

**Why**: Toda monetização depende de transaction observation
robusto. StoreKit 2 + Transaction listener.

**Scope in**:
- New module `CashlySubscription` ou submodule em CashlyData.
- `SubscriptionUseCase` protocol em Domain:
  - `var isPro: AsyncStream<Bool> { get }`
  - `func purchase(_ product: Product) async throws`
  - `func restore() async throws`
- Concrete `StoreKitSubscription` em Data:
  - Transaction.updates listener.
  - Product.products(for:) fetch.
  - Verification.verified check.
- App Store Connect: configure 2 products (com.cashly.pro.monthly,
  com.cashly.pro.yearly). Local testing via .storekit file.
- Mock `MockSubscription` (in-memory toggle).
- Tests: purchase happy path, restore, verification failure,
  transaction listener.

**Scope out**: UI paywall (Wave B3). Feature gating (Wave B2).

**Definition of Done**:
- `isPro` AsyncStream funcional em sandbox.
- Restore funcional.
- StoreKit configuration file commitado para testing.
- Tests verde.

**Deps**: nenhuma.

**ADR**: 0007 — Subscription architecture (StoreKit 2 + AsyncStream).

---

### Wave B2 — Feature gating

**Goal**: Identificar quais features ficam atrás do paywall, gate
em código.

**Why**: Antes de UI, precisa decidir o que é free vs Pro. Gating
em código garante uniformidade.

**Free tier (proposta inicial)**:
- 1 user
- Até 3 categories
- Até 5 budgets
- Transações ilimitadas
- Filtros básicos (date, category)
- L10n + a11y

**Pro tier**:
- Multi-user splits
- Unlimited categories + budgets
- AI predictions (BudgetValue, CategoryName, TagValue)
- Advanced filters (tags, statuses, participants)
- Charts + analytics avançados
- CloudKit sync (já existe, mas gate)
- Export CSV/PDF (futuro)

**Scope in**:
- `FeatureFlag` enum em Domain.
- `FeatureGate` policy struct: maps flag → requires-pro.
- Middleware emissions check `isPro` via injected service.
- UI: disabled-with-lock-icon affordance para Pro features.
- Tests: free user hits paywall trigger; Pro bypasses.

**Scope out**: Paywall UI (B3). Server-side enforcement (none —
on-device only).

**Definition of Done**:
- Toda feature Pro tem gate em código.
- Free user vê lock + CTA para Pro.
- Tests cover both tiers.

**Deps**: Wave B1.

**ADR**: 0008 — Feature flag matrix.

---

### Wave B3 — Paywall UI + onboarding flow

**Goal**: Tela paywall reusável + integrate em onboarding +
upgrade prompts.

**Why**: Conversion depende de UX. Single paywall view, multiple
trigger contexts (onboarding, gated feature, settings).

**Scope in**:
- `PaywallScreen` em CashlyUI:
  - Product list (monthly/yearly + savings %).
  - Feature comparison table (free vs Pro).
  - Subscribe button → calls SubscriptionUseCase.purchase.
  - Restore link.
  - Privacy + Terms links.
- Trigger contexts: onboarding final step, Pro-feature tap,
  Settings → Upgrade.
- L10n para en + pt-BR.
- Snapshot tests do paywall.

**Scope out**: A/B testing (futuro).

**Definition of Done**:
- Paywall renders + purchase fluxo funcional sandbox.
- 3+ trigger contexts working.
- Snapshot baseline.

**Deps**: Wave B1, Wave B2.

**ADR**: nenhum.

---

### Wave B4 — Receipt validation + entitlements

**Goal**: Hardening. Defesa contra refund/expiração tardia. Use
StoreKit 2 `Transaction.currentEntitlements` como source-of-truth.

**Why**: Sandbox testing OK mas produção precisa de robustez.
Refunds via Apple não vêm via push automaticamente.

**Scope in**:
- App launch: refresh entitlements.
- Background task to refresh (BGAppRefreshTask).
- Transaction.updates listener active during app lifetime.
- Handle revocation (refund) → revoga isPro.

**Scope out**: Server-side receipt validation (overkill para apps
sem backend).

**Definition of Done**:
- Refund test (sandbox) revoga isPro dentro de 5min.
- App launch reflete current entitlements.

**Deps**: Wave B1.

**ADR**: nenhum.

---

## Eixo C — Performance + Memória (deferred)

Fora-de-escopo da fase priorizada. Mantida em backlog para futura
priorização:

- C1: Instruments profile de scroll em listas grandes (>500 tx).
- C2: LazyVStack vs List benchmark.
- C3: Image cache audit (CashlyResourceImage).
- C4: SwiftData query optimization (predicates → @FetchRequest).
- C5: Memory leak hunt (CashlyRouter retain cycles).

---

## Ordering & dependencies

Sugestão de execução:

```
A1 → A3 → A4 → A5 → A6
(B1 + A2 podem rodar em paralelo)
B1 → B2 → B3 → B4
```

Refactor (A) primeiro porque limpa o ground antes de adicionar
subscription. Paywall integration fica mais fácil em código
arrumado.

## Out of scope (esta fase)

- Gamification (achievements, streaks, levels)
- Performance optimization (eixo C)
- New entities (recurring transactions, savings goals,
  investment tracking)
- watchOS / tvOS / visionOS-specific UX
- Backend API (Cashly continua on-device + CloudKit only)
