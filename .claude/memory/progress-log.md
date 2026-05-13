## 2026-05-13 — Release v0.1.0 (Eixos A+B+C+D fechados)

**Tipo**: release
**Tag**: v0.1.0
**URL**: https://github.com/byescaleira/cashly/releases/tag/v0.1.0
**Resumo**: Primeiro release versionado cobrindo A1-A6 (refactor), B1-B4 (StoreKit 2 subscription), C1-C7 (followups), D1-D9 (UX/affordances/onboarding/deeplinks/CI), E1-E2 (review blockers fechados). 373 tests passing, iOS Production build clean.
**Aprovação**: swift-reviewer 2-pass — 11/11 blockers/majors/minors PASS.

---

## 2026-05-12 — Onda E1+E2 (review blockers + actionable majors)

**Tipo**: fix
**Módulos**: CashlyPresentationFactory + OSLogAnalyticsTracker (analytics wiring), Info.plist (CFBundleURLTypes), OnboardingScreen + CashlyApp (router callback + routeExternal), MainScreen (pendingDeeplink clear), MainState+Computed (freeLimits alias), SettingsScreen (restore quiet + StoreKit comment), PaywallMiddleware (classify failure), Binding+Inverted, snapshots.yml (drop || true)
**Resumo**: Reviewer 1 retroativo sobre D1-D9 flagou 4 blockers + 5 majors + 3 minors. E1 fechou os 4 blockers (D3 analytics dead → OSLogAnalyticsTracker injected; D5 deeplinks dead → URL scheme registered; D4 onboarding upgrade dead → router callback; pendingDeeplink dedupe → clear-on-yield). E2 fechou 5/5 majors + 2/3 minors (#10 deferido).
**Reviewer 2**: APPROVED 11/11.

---

## 2026-05-12 — Release process formalizado

**Tipo**: chore
**Módulos**: scripts/release.sh, .claude/memory/release-process.md
**Resumo**: Per-wave workflow agora codificado: build/test green → swift-reviewer agent (gate) → conventional commit → release.sh (semver bump, changelog auto via git log, gh release create) → progress-log entry. release.sh suporta `major|minor|patch|x.y.z` + `--dry-run`. Pre-1.0 convention: minor=feature, patch=tudo mais.
**Impacto**: Ondas anteriores (A1-A6, B1-B4, C1-C7, D1-D9) ficaram sem review formal; review retroativo rodando para gerar follow-up issues. Daqui em diante, cada onda passa pelo gate.
**Aprendizados**: Process > tooling — checklist explícito > ferramenta sofisticada.

---

## 2026-05-12 — Ondas D6/D7 (deferred — Widget + AppIntents)

**Tipo**: planning
**Resumo**: Widget extension + AppIntents extension exigem novos targets no Cashly.xcodeproj (pbxproj edit + bundle id + entitlements). Risco alto sem ferramenta de edit confiável (xcodeproj manipulation programática). Defer para sessão com Xcode aberto.
**Decisão**: skip.

---

## 2026-05-12 — Onda D9 (CI/CD hooks)

**Tipo**: chore
**Módulos**: .github/workflows (ci.yml + snapshots.yml), .githooks/pre-push, scripts/install-hooks.sh
**Resumo**: Pre-push hook (swift build + swift test --parallel local). install-hooks.sh wires .githooks/ via core.hooksPath. Snapshot regen workflow (workflow_dispatch) flips isRecording, roda suite, flip back, commit baseline PNGs. CI emite TestResults.xcresult + coverage summary + upload artifact 7d.
**Impacto**: Bad pushes pegos antes de bater CI. Snapshot regen sem manual local. Coverage visible no Actions tab.

---

## 2026-05-12 — Onda D5 (deeplinks cashly://)

**Tipo**: feat
**Módulos**: CashlyPresentation/Route/MainDeeplink, CashlyTests/Presentation/MainDeeplinkTests, EnvironmentValues+Extension (pendingDeeplink), Cashly/Cashly/CashlyApp (.onOpenURL), CashlyUI/Screens/MainScreen (.onChange consume)
**Resumo**: MainDeeplink.resolve(URL) → MainRoute? para paywall/settings/home/intelligence/transactions/categories + trigger query param. CashlyApp pega .onOpenURL, MainScreen observa env e dispara homeRouter.route(to:) trocando tab para .home. 9 tests cobrindo scheme rejection, hosts, query params, unknown host.
**Impacto**: URLs externas roteiam para destinos. Foundation para Universal Links + push notifications.

---

## 2026-05-12 — Onda D10 (deferred — AdapterActor N+1)

**Tipo**: planning
**Resumo**: Perf issue 1 (AdapterActor faz N+1 fetches por Transaction resolve) requer Instruments trace + arquitetura nova (bulk fetch + actor-local cache). Custo alto sem repro mensurada. Defer para sessão com Instruments + dataset realista.

---

## 2026-05-12 — Onda D4 (onboarding flow)

**Tipo**: feat
**Módulos**: CashlyUI/Screens/OnboardingScreen, Cashly/Cashly/CashlyApp (fullScreenCover), CashlyResource/Localizable.xcstrings (6 strings)
**Resumo**: 3-step paged TabView (Welcome / Free / Pro). Last page split CTA: Upgrade to Pro routes paywall, Continue with Free dismisses. @AppStorage "cashly.onboarding.completed" persiste. CashlyApp .fullScreenCover bound to !completed.
**Impacto**: First-launch UX cobre proposition Free vs Pro antes user pisar no app.

---

## 2026-05-12 — Onda D3 (analytics events)

**Tipo**: feat
**Módulos**: CashlyPresentation/Middlewares/PaywallMiddleware
**Resumo**: 9 events: paywall_viewed, purchase_started/succeeded/cancelled/pending/failed, restore_started/succeeded/no_entitlement. Properties carry plan_id, trigger, reason. AnalyticsTracker injected via init com NoopAnalyticsTracker default — composition root pluga concreto quando wiring real.
**Impacto**: Funnel measurable para Pro conversion.

---

## 2026-05-12 — Onda D8 (i18n audit)

**Tipo**: i18n
**Módulos**: CashlyResource/Localizable.xcstrings (+24 keys en + pt-BR)
**Resumo**: grep CashlyL10n.string em Sources vs catálogo identificou 24 strings novas das Waves B3/D1/D2 sem entries. Adicionados ambos locales.
**Impacto**: pt-BR completo para superfícies Pro/Paywall/Settings.

---

## 2026-05-12 — Onda D2 (SettingsScreen)

**Tipo**: feat
**Módulos**: CashlyUI/Screens/SettingsScreen, MainRoute.settings, MainScreen destination, HomeScreen toolbar gear
**Resumo**: Settings com sections Subscription (tier badge, plan, renew/expire), Actions (Manage Subscription via manageSubscriptionsSheet iOS/visionOS, Upgrade/Restore), App (version/build).
**Impacto**: Native iOS subscription management via Apple. Ponto de entrada Free → Pro.

---

## 2026-05-12 — Onda D1 (locked UI affordances)

**Tipo**: feat
**Módulos**: MainState+Computed (isPro/canAdd/usageLabel), CashlyUI/Views/ProBadgeView, HomeScreen/IntelligenceScreen toolbar, AddCategory/AddBudget/AddUser usageItem chips
**Resumo**: Pro badge (crown gold) ou Upgrade (lock accent) toolbar item. IntelligenceScreen lock CTA Free. Save buttons lock icon + usage chip "1/3" quando Free no limite. 4 tests cobrindo isPro/canAdd/usageLabel/intelligence gate.
**Impacto**: User vê estado da limitação antes de tentar saving.

---

## 2026-05-12 — Onda C7 (DocC + README)

**Tipo**: docs
**Módulos**: CashlyDomain.docc, README.md
**Resumo**: DocC mention UserPreferences/Subscription/FeatureGate use cases + Subscription section com value types. Drop nota stale sobre legacy CashlyError. README headline mention Pro tier, 7 stores, StoreKit listener task. Test count 336→360.
**Impacto**: Onboarding e contributor docs sync com B1-B4 + C1-C5.
**ADR**: nenhum

---

## 2026-05-12 — Onda C6 (strict concurrency check)

**Tipo**: chore
**Módulos**: nenhum
**Resumo**: Verificação `swift build -Xswiftc -strict-concurrency=complete` clean. Package.swift swift-tools 6.2 já implica strict-by-default. Nada para corrigir. Skip wave (no-op).
**Aprendizados**: Swift 6.2 tooling padrão já strict — não precisa flag explícita.

---

## 2026-05-12 — Onda C5 (snapshot regression — PaywallScreen)

**Tipo**: test
**Módulos**: CashlyTests/Snapshots/ScreenSnapshotTests (PaywallScreen case)
**Resumo**: Adicionado PaywallScreen snapshot. Suite `#if canImport(UIKit)` — pula macOS, grava na primeira execução iOS sim. HomeScreen Free vs Pro variants deferred (precisa helper seeded MainState).
**ADR**: nenhum

---

## 2026-05-12 — Onda C4 (subscription status observer → MainState)

**Tipo**: feat
**Módulos**: CashlyPresentation/States/MainState (subscriptionStatus), Actions/MainAction (.subscriptionUpdated), Reducers/MainReducer, Cashly/Cashly/CashlyApp (statusUpdates .task forward), CashlyMock/Views/MockModifier
**Resumo**: SubscriptionStatus stream → MainState. New MainAction.subscriptionUpdated(_:), reducer writer, middleware no-op. CashlyApp adds 2º `.task` consuming statusUpdates() para app lifetime, redispatch como action. MockModifier mirror para previews.
**Impacto**: UI reage a tier sem queries diretas. Foundation para Pro badges, locked-feature affordances.
**ADR**: nenhum
**Aprendizados**: Stream observer no app delegate é padrão limpo — single source para state mutation via reducer.

---

## 2026-05-12 — Onda C3 (medium bugs — isSaved/legacy cleanup/cashlyMutate batch/sleep hacks)

**Tipo**: fix
**Módulos**: 5 Add*Reducer (reset isSaved+error on .fetch), UserDefaultsUserPreferences (drop legacy blob after migration), Store+Binding (closure-form cashlyMutate), 5 Add*Screen+Handlers (Task.yield em vez de sleep)
**Resumo**: BUG-009 isSaved reset on fetch + error reset. BUG-012 migration one-shot (drop legacy `cashly.user` blob após copiar id). BUG-013 cashlyMutate closure form para batching atomic — AddTransaction.onChangeSelectedUsers refactored. BUG-015 substituir Task.sleep(0.5s) por Task.yield() em handlerInitialState (5 screens).
**Impacto**: UX mais previsível em re-uso de store. Migration leve em re-installs. Lost-update race fechada. Nav rápida não corre Task cancellation.
**ADR**: nenhum
**Aprendizados**: Reducer deve normalizar campos de UX (isSaved, error) on entry-point actions (.fetch), não só na resposta (.saved/.error). Task.yield ≠ Task.sleep — yield só cede 1 ciclo, ideal para "wait next runloop".

---

## 2026-05-12 — Onda C2 (multi-context — deferred)

**Tipo**: planning
**Resumo**: BUG-004 (cada *Actor cria seu próprio ModelContext + AdapterActor adicional) recomendaria centralizar em CashlyDataActor ou compartilhar ModelContext. Trade-off muito alto sem repro real do bug. Save() já é explicit em todos os mutadores; SwiftData SQLite + CloudKit já propagam. Sem repro confirmada, defer C2. Documentar e watch.
**Decisão**: skip wave.
**Aprendizados**: Bug-hunter levantou suspeita arquitetural; sem repro real custo de refactor 6 actors > ROI. Watch flag para Wave futura caso aparecer flaky test/issue real.

---

## 2026-05-12 — Onda C1 (UX errors visíveis + paywall auto-trigger)

**Tipo**: feat
**Módulos**: CashlyUI/Modifier/CashlyErrorAlertModifier, 6 screens (HomeScreen + 5 Add*)
**Resumo**: BUG-007 surface state.error. Modifier `.cashlyErrorAlert(error:reset:)` exibe SwiftUI alert com errorDescription/failureReason/recoverySuggestion. `.featureGated` curto-circuita: router.route(to: .paywall(trigger: .limitReached)) — paywall replaces alert para monetisation gates. OK button → reset closure clears state.error via cashlyMutate(\.error, nil).
**Impacto**: Falhas de save não silenciosas mais. Hit Free-tier ceiling abre paywall automático. Loop feedback completo Domain → UI.
**ADR**: nenhum

---

## 2026-05-12 — Wave B4 (receipt verification + refund/revocation)

**Tipo**: feat
**Módulos**: CashlyData/Services/StoreKitSubscriptionService, CashlyMock/Services/InMemorySubscriptionService, CashlyTests/Data/InMemorySubscriptionServiceTests
**Resumo**: Hardening do listener StoreKit. handleVerification agora distingue .verified vs .unverified (unverified dropped, log em DEBUG); apply(verified:) ordena revocationDate → expirationDate → productID membership antes de promover tier. Unknown product IDs em transações verified são ignorados (não derrubam Pro de sibling app). Mock service ganhou simulateRevocation() + simulateExpiry() para testar Pro → Free transitions sem StoreKit. 3 testes novos: revocation drop, expiry drop, statusUpdates AsyncStream emite initial + changes.
**Impacto**: Refund/chargeback automaticamente re-locka Pro features. Status stream pronto para observer no app delegate (Wave futura) propagar tier para state.
**ADR**: nenhum (segue B1)
**PRs**: pending commit
**Aprendizados**: StoreKit 2 `.unverified` deve nunca grantear acesso; sibling app product IDs colidem no Apple ID compartilhado (ignorar é correto).

---

## 2026-05-12 — Wave B3 (paywall sheet + 3 trigger contexts)

**Tipo**: feat
**Módulos**: CashlyPresentation (PaywallState/Action/Reducer/Middleware), CashlyUI/Screens/PaywallScreen, CashlyPresentation/Route/MainRoute (.paywall case), Cashly/Cashly/CashlyApp (paywallStore), CashlyMock/Views/MockModifier, CashlyPresentation/Actions/ApplicationAction (.paywall case), Factories
**Resumo**: Sheet de upgrade. PaywallTrigger (.limitReached / .intelligenceTab / .upgradeButton) muda headline + analytics, plans defaultam para yearly. Reducer trata estados (fetch/update/select/purchase/purchaseSucceeded/cancelled/restore/error/replace). Middleware bridge para SubscriptionUseCase mapeia outcomes (.success/.userCancelled/.pending/.failed). PaywallScreen com Form (header + plans + continue + restore), auto-dismiss em didPurchase. MainRoute.paywall com .present navigation style. CashlyApp + MockModifier ganharam paywallStore. 10 PaywallReducer tests + ApplicationActionTests extended.
**Impacto**: UI completa pronta. Qualquer screen pode `router.push(.paywall(trigger: ...))` ou trigger via dispatch. Falta: hook em screens Add* para auto-trigger ao receber state.error.featureGated (próxima wave/melhoria).
**ADR**: nenhum (segue B1/B2)
**PRs**: pending commit
**Aprendizados**: Single paywall store em app-wide level + state replace per trigger é mais simples que store per push.

---

## 2026-05-12 — Wave B2 (feature gating matrix)

**Tipo**: feat
**Módulos**: CashlyDomain (FeatureGateUseCase + DomainError.featureGated), CashlyData/Services/DefaultFeatureGate, CashlyMock/Services/AlwaysAllowedFeatureGate + StubFeatureGate, AddUser/AddCategory/AddBudget middlewares, factories
**Resumo**: Free vs Pro matrix. FeatureGate enum (.addUser/.addCategory/.addBudget/.intelligence/.multiUser) + Decision (.allowed/.blocked(feature, requiredTier)). Limits struct (1 user / 3 categories / 5 budgets free default). DefaultFeatureGate combina SubscriptionUseCase.tier + counts from User/Category/Budget cases — Pro short-circuit. Middlewares chamam decide() no path de create (não em edit) e emitem `.error(.domain(.featureGated))` no block. 6 tests DefaultFeatureGate + middleware tests atualizados com AlwaysAllowedFeatureGate.
**Impacto**: Gating ativo. UI ainda não cataloga `.featureGated` em alert (depende Wave B3+gancho). Foundation pronta para paywall trigger.
**ADR**: nenhum
**PRs**: pending commit
**Aprendizados**: `state.isNew` distingue create vs edit — gate apenas no create. Pattern actor para count snapshot é OK porque gate é consulta one-shot.

---

## 2026-05-12 — Wave B1 (StoreKit 2 infrastructure)

**Tipo**: feat
**Módulos**: CashlyDomain/Use Cases/SubscriptionUseCase, CashlyData/Services/StoreKitSubscriptionService, CashlyMock/Services/InMemorySubscriptionService, Factories, Cashly/Cashly/CashlyApp (subscriptionService.start() at launch)
**Resumo**: Foundation Pro tier. SubscriptionUseCase protocol Domain-side (Tier free/pro, SubscriptionPlan, SubscriptionStatus, PurchaseOutcome, statusUpdates AsyncStream). StoreKitSubscriptionService actor StoreKit 2 (Product.products(for:), Transaction.updates listener, currentEntitlements, purchase com VerificationResult). Product IDs centralizados: com.cashly.pro.{monthly,yearly}. InMemorySubscriptionService mirror para tests/previews com nextPurchaseOutcome override + setTier seam. Factories wire makeSubscriptionUseCase. CashlyApp segura subscriptionService + .task { .start() } no launch.
**Impacto**: Pronto para B2-B4. StoreKit nunca leak para Presentation/UI — protocolo é a única superfície.
**ADR**: nenhum (segue padrão Prism)
**PRs**: pending commit
**Aprendizados**: StoreKit.Transaction colide com CashlyDomain.Transaction; qualificar com namespace evita ambiguity. Listener Task.detached precisa ser retido pelo app delegate (instância no App struct).

---

## 2026-05-12 — Bug-hunt critical pass (7 fixes)

**Tipo**: fix
**Módulos**: TransactionActor (filter participants), TransactionEntity (endDate rollover >1yr), CashlyIntelligence (model nil returns), MainMiddleware (PredictionCache user invalidation), MainReducer (removeTag filter), MainRoute (Hashable com payload id), HomeScreen/IntelligenceScreen (rollback cancelEffects regressão A2)
**Resumo**: Triagem de 4 critical + 3 high do bug-hunt agent. Highlights: PredictionCache não invalidava em troca de user (modelos de A em data de B); CashlyIntelligence.model(for:) sempre retornava placeholder não-nil (guards inúteis); MainRoute hash ignorava payload (NavigationStack quebrava com dois pushes); MainReducer.removeTag sobrescrevia filter.tags com tudo (ativava filter unwanted); TransactionEntity.endDate quebrava em parcelamentos >24m (overflow de month); TransactionActor filter participants usava Array.contains em vez de .contains(where:). A2 regressão: HomeScreen/IntelligenceScreen compartilham mainStore — cancelEffects on disappear derrubava fetch da tab adjacente; removido apenas dessas duas screens, Add* mantidas.
**Impacto**: 345 tests passing pós-fix. Test MainRouteTests atualizado para asserir contract correto.
**ADR**: nenhum
**PRs**: pending commit
**Aprendizados**: cancelEffects() em onDisappear só faz sentido para screens com store próprio, não para tabs compartilhando store global. PredictionCache deve guardar identity do owner do cache.

---

## 2026-05-12 — Performance pass (top hot paths)

**Tipo**: perf
**Módulos**: MainState (caches stored), MainState+Derived (recomputeDerived), MainState+Computed (delegates to cache), MainReducer (recompute on update/remove), MainMiddleware (dedup tags fetch + withTaskGroup predictions), CashlyIntelligenceModifier (offload inference from MainActor), IntelligenceScreen (serialized training)
**Resumo**: Top 7 issues do swift-performance-analyst. (1-4) Per-id totals e sections agora stored caches no MainState, populados pelo recomputeDerived() no Reducer — view bodies O(1) em vez de O(N×M) per render. (5) Tag fetch duplicado em MainMiddleware.fetch eliminado. (6) Per-budget predictions paralelizados via withTaskGroup. (7) CashlyIntelligenceModifier.predict não pin mais MainActor — inferência off main, only assignment on main. (8) IntelligenceScreen.train sequencial (single Task) em vez de 3 paralelos saturando pool.
**Impacto**: HomeScreen/TransactionScreen body O(1) em transactionsAmount/sections. ML training não satura cooperative pool. 331 tests still pass.
**ADR**: nenhum
**PRs**: pending commit
**Aprendizados**: SwiftUI body re-eval frequente — qualquer cálculo O(N) em body acumula em scroll. Stored caches no state com invalidação explícita pelo reducer é o pattern correto.

---

## 2026-05-12 — Fix tests macOS (CashlyEditMode + Sendable)

**Tipo**: fix
**Módulos**: CashlyDesignSystem/CashlyEditMode (cross-platform), CashlyUI/Screens/TransactionScreen + MainScreen (#if os(iOS)), CashlyTests/Data/UserDefaultsUserPreferencesTests (Sendable race)
**Resumo**: `swift test` macOS bloqueado por EditMode + tabBarMinimizeBehavior(.onScrollDown) (ambos iOS-only). Solução: CashlyEditMode enum + .cashlyEditMode(_:) modifier (no-op em macOS); .tabBarMinimizeBehavior wrap em #if os(iOS). UserDefaultsUserPreferencesTests fix Swift 6 `sending` race scopeando UserDefaults dentro de makePreferences(seed:). 331 tests passam macOS pela primeira vez.
**Impacto**: CI macOS funcional. swift test end-to-end clean.
**ADR**: nenhum
**PRs**: pending commit
**Aprendizados**: Cross-platform UI types precisam abstração própria — EditMode SwiftUI não cobre macOS, precisa wrapper.

---

## 2026-05-11 — Wave A6 (strict-Sendable State: extract routers from MainState)

**Tipo**: refactor
**Módulos**: CashlyPresentation/States/MainState (4 router properties removidos), CashlyUI/Screens/MainScreen (@State routers added), CashlyTests/States/StateFactoryTests (router asserts removidos)
**Resumo**: `MainState` carregava 4 `CashlyRouter<MainRoute>` (intelligenceRouter, categoryRouter, homeRouter, transactionRouter). CashlyRouter é `@unchecked Sendable` class (final, reference type, mutable nav stack). Estado value-type segurando reference-type que é `@unchecked Sendable` = mentira que nunca seria flagada por strict concurrency mas quebrava semântica de `replace(State)`. A6 move routers para `MainScreen.@State`, binding direto via `$intelligenceRouter` em vez de `store.cashlyBinding(\.intelligenceRouter)`. MainState agora 100% value type, Sendable honesto.
**Impacto**: Zero `@unchecked Sendable` em States. `replace(state:)` preserva nav stack (não overwrite mais). iOS build-for-testing ✅. Restam apenas 2 `@unchecked Sendable` no codebase: CashlyRouter (justificado, MainActor-bound) e Prism `PrismIntelligencePredictionInput` extension (external).
**ADR**: 0006-mainstate-router-extraction
**PRs**: pending commit
**Aprendizados**: Reducer-shaped state (value type) e SwiftUI navigation state (reference type) precisam ficar separados. Quando se mistura, perdem-se invariantes de ambos. Routers em @State per tab é a posição canônica — sobrevivem re-renders, morrem com a view.

---

## 2026-05-11 — Wave A2 (cancellable middleware effects)

**Tipo**: refactor
**Módulos**: CashlyUI/Screens (HomeScreen, IntelligenceScreen, AddBudgetScreen, AddCategoryScreen, AddTagScreen, AddUserScreen, AddTransactionScreen)
**Resumo**: `PrismStore.cancelEffects()` existia mas nenhuma screen Cashly chamava. Background fetches continuavam após dismiss — possíveis state mutations stale + memory pressure em rapid navigation. A2 adicionou `.onDisappear { store.cancelEffects() }` em 7 screens com fetch background. IntelligenceScreen ganhou `@Environment(CashlyStore<MainState, MainAction>.self) var store` + `import CashlyPresentation` (faltava). AddTransactionScreen agregou cancelEffects ao onDisappear existente (que já zerava selectedUsers).
**Impacto**: Effects in-flight cancelam quando view desaparece. SwiftUI `.task` auto-cancela o closure mas não o Task interno do PrismStore (criado em `.run` via `Task { ... }`) — agora ambos. iOS build ✅.
**ADR**: nenhum (segue padrão Prism existente — apenas usa API pública)
**PRs**: pending commit
**Aprendizados**: `.task` SwiftUI != cancelamento de effects do store. O closure do `.task` é cancelado mas o `action(...)` dispara um effect que vive no store, separado da view lifecycle. Sem `cancelEffects()` explícito, fetch background pode mutar state após dismiss e disparar UI updates em hierarchy desmontada.

---

## 2026-05-11 — Wave A5 (god-file splits: AddBudget/AddCategory/AddTag/FilterItemView)

**Tipo**: refactor
**Módulos**: CashlyUI/Screens (AddBudgetScreen, AddCategoryScreen, AddTagScreen — cada um split em +Sections/+Subviews/+Toolbar), CashlyUI/Items (FilterItemView split em +DateMenu/+SelectionMenus)
**Resumo**: 4 god-files (242/236/225/259 LOC) excediam convention <= 200. Aplicada estratégia HomeScreen+/AddTransaction+ existente: extension per concern. AddBudgetScreen: shell+state+handlers (93) / +Sections (78) / +Subviews (53) / +Toolbar (57). AddCategoryScreen: shell (86) / +Sections (84) / +Subviews (67) / +Toolbar (37). AddTagScreen: shell (78) / +Sections (84) / +Subviews (65) / +Toolbar (37). FilterItemView: shell (103) / +DateMenu (79) / +SelectionMenus (101). Todos abaixo de 200 LOC.
**Impacto**: Convention compliance. Cada arquivo tem foco singular (sections vs subviews vs toolbar vs date filtering vs multi-select filtering). iOS build ✅. Sem mudança comportamental.
**ADR**: nenhum (refactor estrutural seguindo padrão existente)
**PRs**: pending commit
**Aprendizados**: Pattern HomeScreen+/AddTransaction+ é genérico: extension por concern (Sections para form layout, Subviews para reusable building blocks, Toolbar para toolbar items, Handlers para action dispatchers). Custo de split é ~zero (extension preserva access a propriedades stored), benefício é navegação imediata.

---

## 2026-05-11 — Wave A4 (deferred — Intelligence typealias migration)

**Tipo**: planning
**Módulos**: nenhum
**Resumo**: Reavaliação durante ultrathink: o ganho proposto (remover `import PrismIntelligence` de `CashlyDomain`) custaria adicionar `import CashlyData` em ~10 arquivos de UI/Presentation, sem ganho semântico real. PrismIntelligence é um peer module estável (parte da família Prism, similar a PrismFoundation que já vem `@_exported` por Domain). Acoplamento é ambient, não infra. Decisão: A4 fica **deferida sem ADR**. Typealiases permanecem em Domain. Roadmap atualizado para refletir.
**Impacto**: nenhum — pula direto para A5.
**ADR**: nenhum (rejection de A4)
**PRs**: pending commit
**Aprendizados**: Roadmap waves precisam ser revalidadas no momento da execução. Custo vs benefício pode mudar quando se vê os real callsites. Skip é resultado válido — não força execução de wave por completude.

---

## 2026-05-11 — Wave A3 (typed CashlyError — kill legacy onFetch/onSave/onRemove)

**Tipo**: refactor
**Módulos**: CashlyDomain (CashlyError enum), CashlyPresentation (6 middlewares: AddBudget/AddCategory/AddTag/AddTransaction/AddUser/Main), CashlyTests (6 middleware test suites, 5 reducer test suites, CashlyErrorTests, ReducerCompositionTests, UseCaseDoubles)
**Resumo**: Segunda onda do Eixo A. `CashlyError` ganhou `.persistence`/`.domain` typed wrappers há tempos mas todos middlewares continuavam emitindo `.onFetch/.onSave/.onRemove` opaco. A3 mapeou cada emissão por intenção: catch de use-case throw → `.persistence(.fetchFailed/saveFailed/removeFailed)` com entity + underlying.localizedDescription; guard fail por input ruim → `.domain(.invalidInput(field:reason:))`; guard fail por dep existente (remoção bloqueada) → `.domain(.businessRuleViolated(rule:))`; guard fail por target ausente → `.persistence(.notFound(entity:id:))`. Legacy cases deletados do enum. Testes migraram para pattern match em nível de categoria (`.persistence(.saveFailed)` vs `.domain(.invalidInput)`), não em entity string.
**Impacto**: state.error agora carrega entity + underlying + categoria — analytics conseguem split por tipo. Foundation para Wave B2 (paywall errors via `.domain(.featureGated)`). iOS build-for-testing ✅. Reducer composition + middleware tests passam compilação.
**ADR**: 0005-typed-cashly-error
**PRs**: pending commit
**Aprendizados**: Quando typed e legacy convivem por muito tempo, callsites estagnam no fácil. Solução: deletar legacy em uma onda só (não deprecation ramp) quando o codebase ainda é pequeno. Pattern match no nível de categoria (`.error(.persistence)`) preserva intenção do teste sem acoplar a entity strings.

---

## 2026-05-11 — Wave A1 (UserPreferences abstraction — decouple UserActor from UserDefaults)

**Tipo**: refactor
**Módulos**: CashlyDomain (UserPreferencesUseCase + factory protocol), CashlyData (UserDefaultsUserPreferences, UserActor manual ModelActor), CashlyMock (InMemoryUserPreferences, factory wire)
**Resumo**: Primeira onda do roadmap-2026 Eixo A. UserActor não fala mais UserDefaults direto — recebe `UserPreferencesUseCase` no init. Production impl é actor `UserDefaultsUserPreferences` em Data: armazena `cashly.user.id` (string), migra one-shot do legacy `cashly.user` (full User blob) na primeira leitura. UserActor dropou `@ModelActor` macro (init signature fixa bloqueava injeção) — conforma `ModelActor` manualmente com `modelContainer` + `preferences`. Demais actors (Budget/Category/Tag/Transaction/Participant) mantêm macro. MockCashlyFactory + CashlyDataFactoryProtocol ganharam `makeUserPreferences()`.
**Impacto**: Seam de teste limpo (InMemoryUserPreferences). Storage format passa de blob codificado para id plano (sem name/photo stale). UserUseCase API inalterada — 5 middleware callsites zero-touch. iOS build ✅ via xcodebuild -sdk iphonesimulator. swift test bloqueado por bug pré-existente em CashlyUI (EditMode/onScrollDown unavail em macOS) — não é regressão A1.
**ADR**: 0004-user-preferences-abstraction
**PRs**: pending commit
**Aprendizados**: `@ModelActor` macro é açúcar, não lei — quando precisa de DI extra, dropar macro e implementar `ModelActor` à mão custa ~6 linhas. UserDefaults migration shim deve preservar key legacy até clear explícito (idempotência em re-installs). swift test no monorepo Cashly compila CashlyUI mesmo com --filter; xcodebuild iOS é a única forma de validar A1 enquanto UI macOS-broken existir.

---

## 2026-05-11 — Wave 6g (.gitignore + stale schemes cleanup)

**Tipo**: chore
**Módulos**: .gitignore, .DS_Store untracking, CashlyKit/.swiftpm/xcode/xcshareddata/xcschemes/ (4 stale schemes)
**Resumo**: Repo hygiene. .gitignore ganhou .DS_Store, .claude/projects/, .codex/, DerivedData/ entries. 2 .DS_Store files untracked + 5 .DS_Store removed do source tree. 4 stale CashlyKit schemes (Core/Data/Interface/Presentation — Ryze-era target names que não existem mais) deletados. Workspace `xcodebuild -list` agora matches active target list. SwiftPM auto-gera CashlyKit-Package + per-library schemes — aliases legacy não eram necessários.
**Impacto**: Repo limpo. Sem stale references. Cashly.xcworkspace funcional sem schemes broken.
**ADR**: nenhum
**PRs**: 2 commits em main
**Aprendizados**: SwiftPM Xcode schemes em .swiftpm/xcode/xcshareddata/xcschemes/ ficam stale após module renames. Limpar periodicamente para evitar broken xcodebuild scheme lookups. Default scheme generation (CashlyKit-Package) é suficiente — não precisa custom aliases.

---

## 2026-05-11 — Wave 6f (README rewrite — accurate post-migration state)

**Tipo**: docs
**Módulos**: README.md
**Resumo**: README stale. Reescrito: sibling-checkout pattern (cashly + prism peers), test command corrigido (CashlyKit-Package + 336/54), migration Status section dropada (gap IDs não existem em source), DocC section nova (per-target catalogs + preview command). Zero `Wave`/`G0XX`/`Ryze`/INSTALL refs.
**Impacto**: README primeiro-contact-friendly. Reflete estado real do projeto.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: README é onboarding canvas — não pode listar gaps in-flight quando migration está completa. History → memory log only.

---

## 2026-05-11 — Wave 6e (strip Wave/Gap from tests + DocC)

**Tipo**: chore
**Módulos**: CashlyTests/Snapshots/ScreenSnapshotTests, CashlyTests/Actors/SmokeTests, CashlyData.docc/CashlyData.md, CashlyUI.docc/CashlyUI.md
**Resumo**: Cleanup pass remanescente. Wave/Gap tags removidos de:
- ScreenSnapshotTests + SmokeTests headers (Wave 0 deferred → plain description).
- CashlyData DocC ("Lifted out of Domain in Wave 5c" → drop).
- CashlyUI DocC ("see G007 in gap-analysis" → inline explanation da SwiftPM condition limitation).
Final audit: zero matches `Wave [0-9]`/`G0[0-9][0-9]`/`Ryze` em Sources, Tests, Cashly app, e DocC `.md`. Migration history vive APENAS em `.claude/memory/`.
**Impacto**: Source + docs limpos. Onboard docs falam sobre comportamento atual, não trajetória.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: DocC markdown também conta como source documentation — Wave/Gap tags lá têm a mesma rot-rate que em headers swift. Audit deve incluir `.md` files.

---

## 2026-05-11 — Wave 6d (strip Wave/Gap migration tags from source)

**Tipo**: chore
**Módulos**: 37 swift files across CashlyUI, CashlyResource, CashlyData, CashlyPresentation/States
**Resumo**: Strip migration metadata (`Wave 5b`, `Wave 7 G019`, `G004/G001`, `Wave 5 G034`, `Wave 8 G024`) de file headers + inline comments. Substituídos por descrições do que o código faz hoje. Zero matches `Wave [0-9]` / `G0[0-9][0-9]` em Sources agora. Migration history continua em `.claude/memory/progress-log.md` — source comments descrevem código, não archaeology.
**Impacto**: Source mais clean para onboarding. Comments don't rot — futurama developer não precisa saber Wave numbering ou gap IDs.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Comments com migration metadata têm validade curta. Útil durante wave para tracking, deve ser strippado quando wave fecha. Memory log + ADRs são home apropriado para project archaeology.

---

## 2026-05-11 — Wave 6c (Ryze residuals removed)

**Tipo**: chore
**Módulos**: 9 swift headers em CashlyDesignSystem + CashlyDomain, Cashly.xcodeproj Package.resolved, CashlyKit/Package.resolved
**Resumo**: Pós Wave 5a real merge, restavam apenas comentários "Wave 5b: replaces RyzeX" + stale Ryze pin no Cashly app Package.resolved (não SPM-fresh desde Wave 5a). Reescritos 9 file headers para descrever comportamento atual em vez de migration history. Cashly.xcodeproj/Package.resolved removido (Prism agora local path → SPM não mantém resolved file). CashlyKit/Package.resolved regenerado sem Ryze pin. CashlyDesignSystem.swift entry file virou navigation index puro (sem metadata Wave 5b). 336 tests passing. Zero matches `Ryze`/`ryze` em Sources/Xcodeproj/Package files.
**Impacto**: Codebase agora Prism-only. Sem traces de Ryze. Fácil onboarding para novos devs — não há "qual é Ryze?" question.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: SwiftPM gera Package.resolved só para remote-source deps. Local-path deps (Prism = ../../prism) não criam pin entries. `xcodebuild -resolvePackageDependencies` força re-resolve sem alterar source files.

---

## 2026-05-11 — Wave 6b (lint pass: trailing whitespace + double blanks)

**Tipo**: chore
**Módulos**: 73 swift files (Sources + Tests)
**Resumo**: Lint pass. sed -i '' 's/[[:space:]]*$//' removeu 508 lines de trailing whitespace. awk-pass squashed 6 double-blank line occurrences (IntelligenceScreen, CashlyChart, CashlyCompareChart, CashlySymbolCategory(+Symbols), Participant). Verified: zero tabs, todos files com final newline. Alinhado com Apple Swift style.
**Impacto**: Source tree limpo. swift-format friendly. 336 tests still passing.
**ADR**: nenhum
**PRs**: 2 commits em main
**Aprendizados**: Bulk sed strip + awk dedup é cheap-effective para lint pass sem instalar swift-format ou SwiftLint. Future enforce via CI step `swift-format lint --recursive Sources Tests`.

---

## 2026-05-11 — Wave 6a (Package.swift Apple-standard rewrite)

**Tipo**: chore
**Módulos**: CashlyKit/Package.swift
**Resumo**: Removida toda metaprogramming do Package.swift. Antes: enum CashlyTarget gerando targets/products/deps via switches; CashlyDependency enum para package URLs; extensions em Product/Target/Target.Dependency/Package.Dependency/Array. Agora: declarativo plain — `dependencies:`, `products:`, `targets:` blocks com `.target(name:dependencies:)` literais. Match style Apple usa em SDK packages. 200 → 145 linhas. "What does target X depend on" agora lê em 5 linhas em vez de chase via 4 computed properties. 336 tests ainda passing.
**Impacto**: Manutenibilidade Package.swift drasticamente melhor. Lint-friendly. Add/remove target é um delta inline, não 5 sites diferentes.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Bespoke enum-driven Package.swift patterns são DRY-attractive mas anti-readability. Apple convention é deliberadamente verbose para que cada target self-document deps. Ferramentas (swift-format, IDE refactoring) handle padrão estandard, não o custom.

---

## 2026-05-11 — Wave 5z (Package.swift dep graph trim)

**Tipo**: chore
**Módulos**: Package.swift, MainState, EnvironmentValues+Extension
**Resumo**: Trimm dep graph SPM. EnvironmentValues+Extension dropou `import CashlyData` (unused). MainState dropou `import PrismIntelligence` (leftover Wave 5c). Package.swift edges:
- `.presentation` deps: removido `.prismIntelligence`. Presentation só importa PrismArchitecture (state/store/effect) + PrismFoundation (PrismDateFormatter). Intelligence types chegam transitivamente via Domain.
- `.ui` deps: removido `.prismUI` e `.prismArchitecture`. CashlyUI tem zero `import Prism*` — todo Prism wrapped por CashlyDesignSystem ou CashlyPresentation typealiases.
336 tests / 54 suites passing.
**Impacto**: Build graph mais explícito. UI target zero-Prism-dep — confirma Wave 5b vocabulary boundary. Faster builds.
**ADR**: nenhum
**PRs**: 2 commits em main
**Aprendizados**: Auditoria de Package.swift deps deve cross-verify com `grep "^import Prism*"` por target. Edges declarados mas não usados causam transitive bloat + unnecessary recompilation cascade.

---

## 2026-05-11 — Wave 5y (final imports audit: Foundation/Domain/Resource/PrismArchitecture)

**Tipo**: chore
**Módulos**: 17 arquivos trimmed across Domain/Data/Presentation/UI/Mock
**Resumo**: Wave 5x continuação. Audit + drops:
- 7 unused `import Foundation` (Score, Participant, CashlyError, MainState, CashlySymbolCategory(+Symbols), AddTransactionMiddleware); 3 SwiftData actors explicit-kept (CategoryActor/TagActor/ParticipantActor — need Foundation para Predicate macro).
- 1 unused `import CashlyDomain` (CashlyMenuSelectionView).
- 3 unused `import CashlyResource` (AddTransactionScreen, TransactionBalanceView, MainState).
- 8 unused `import PrismArchitecture` (CashlyStore typealias resolve via CashlyPresentation re-export); 2 explicit-kept para factory files que retornam CashlyStore<...> em public API (CashlyPresentationFactory + MockCashlyFactory).
Total: 19 import lines removidas em 3 commits. 336 tests ainda passing.
**Impacto**: Build mais limpo. Cada arquivo importa só o que usa. Acoplamento real entre modules reflete graph dependencies.
**ADR**: nenhum
**PRs**: 3 commits em main
**Aprendizados**: Public API com generic type retornado (e.g., `func make() -> CashlyStore<S, A>`) requer import do módulo definidor mesmo quando há typealias — Swift type resolution não chase aliases through module boundaries para public surfaces.

---

## 2026-05-11 — Wave 5x (hygiene: drop unused imports + DesignSystem dep prune)

**Tipo**: chore
**Módulos**: CashlyDesignSystem (3 files), CashlyMock (MockModifier + 6 actors), CashlyData (5 actors + TransactionEntity), CashlyPresentation (CashlyDateFormatter), CashlyDomain (CashlyKey), Package.swift (designSystem deps)
**Resumo**: Imports auditados pós Wave 5a/5b. CashlyDesignSystem agora é pure SwiftUI module: `import PrismUI/PrismArchitecture/CashlyResource` dropados (zero usage) + Package.swift deps de `[.resource, .prismUI, .prismArchitecture]` para `[]`. Outros 11 arquivos com `import PrismFoundation` leftover dropados (zero usage); 2 explicit-kept (TransactionEntity + CashlyDateFormatter precisam PrismDateFormatter). 336 tests passing pós cleanup.
**Impacto**: Build mais rápido (DesignSystem não compila contra Prism graph). Imports limpos refletem real graph dependencies. Cashly hygiene.
**ADR**: nenhum
**PRs**: 2 commits em main
**Aprendizados**: Após bulk rename Ryze→Prism, imports ficaram leftover em arquivos que não usavam tipos do módulo. SourceKit não flagga unused imports — só ferramentas externas (e.g. periphery). Manual audit via `grep -L "PrismX|PrismY" ...` é cheap-effective.

---

## 2026-05-11 — Wave 5w (entity .mock/.mocks + cashlyPreview helpers)

**Tipo**: test
**Módulos**: CashlyTests/Mocks/{EntityMocks, CashlyPreview}Tests
**Resumo**: 10 testes novos. EntityMocksTests (8): User/Budget/Category/Tag/Participant/Transaction PrismMock conformances — .mocks JSON resolves, sort orders correct (User asc by name, Budget desc by date), e .mock always resolves. CashlyPreviewTests (2): both instance and static cashlyPreview() build sem crash. 336 tests / 54 suites passing.
**Impacto**: Mock fixture surface coberto. Tests garantem JSON parsing está funcional + ordenação esperada.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Static cashlyPreview() é constrained `where Self: CashlyView` e usa `mocked()` default (EmptyView) — preview-only TestView fixture funciona como conformer mínimo.

---

## 2026-05-11 — Wave 5v (MockCashlyFactory dual-conformance tests)

**Tipo**: test
**Módulos**: CashlyTests/Mocks/MockCashlyFactoryTests
**Resumo**: 4 testes novos cobrindo MockCashlyFactory que implementa BOTH CashlyDataFactoryProtocol e CashlyPresentationFactoryProtocol. Data use cases (adapter + 6 actors) buildam; presentation stores buildam no baseline correto; makeModelContext OK; instances independentes (sem shared global). 326 tests / 52 suites passing.
**Impacto**: Dual-conformance factory surface coberto. Garante que previews + tests podem rebuildar todo o graph sem SwiftData on-disk init.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: MockCashlyFactory cria new MockUserActor / MockBudgetActor / etc por chamada — cada makeXUseCase() retorna instance fresh. Tests de visibility cross-instance precisam fixar uma única actor instance, não múltiplas via factory calls.

---

## 2026-05-11 — Wave 5u (composition factories + flaky poll fix)

**Tipo**: test + fix
**Módulos**: CashlyTests/Data/CashlyDataFactoryTests, CashlyTests/Presentation/CashlyPresentationFactoryTests, ReducerCompositionTests (flake fix)
**Resumo**: 9 testes novos. CashlyDataFactoryTests (2): in-memory init via init(modelContainer:); cada makeXUseCase build; budget roundtrip end-to-end. CashlyPresentationFactoryTests (7): each makeXStore baseline + independência entre instances. Flake fix em ReducerCompositionTests: trocado fixed 200ms sleep por 10ms-tick poll até 2s — async middleware effect ocasionalmente passava do budget em cold runs. 322 tests / 51 suites passing.
**Impacto**: Composition root coverage end-to-end. Test stability melhor (poll exits early on green, full budget só em failure).
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Async test patterns devem polling em vez de fixed sleep para evitar flakes em runners CI lentos. `for _ in 0 ..< N where condition { sleep(10ms) }` é o pattern canônico para "wait for state change".

---

## 2026-05-11 — Wave 5t (reducer+middleware composition + State factories)

**Tipo**: test
**Módulos**: CashlyTests/Presentation/ReducerCompositionTests, CashlyTests/States/StateFactoryTests
**Resumo**: 17 testes novos. ReducerCompositionTests (5): drive PrismStore.init(reducer:middleware:) end-to-end. .update sync sets fields + async middleware emits .stopLoading; .saved sets flag sem cascade; .replace swap sem cascade; .fetch sync flips loading; .error termina sem follow-up. StateFactoryTests (12): every Add*State.new() / .edit(id:) baseline + parameterized factories (Budget.new(category:date:), Transaction.new(budget:date:)) prefill correctly. MainState default init: routers empty, collections empty, loading=true. 313 tests / 49 suites passing.
**Impacto**: PrismStore composition seam (reducer + middleware merge via `handling(with:)`) testado end-to-end. Confirma reducer arm sync + middleware effect async no mesmo store.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Em PrismStore, reducer arm executa síncrono dentro de send() ANTES da effect AsyncStream começar drain. Pattern útil para tests: assertar reducer-side mutations imediatamente após send, depois Task.sleep para middleware emissions.

---

## 2026-05-11 — Wave 5s (CashlyResource + CashlyLogger tests)

**Tipo**: test
**Módulos**: CashlyTests/Resource/{CashlyResourceTests, CashlyLoggerTests}
**Resumo**: 11 testes novos. CashlyResourceTests (8): CashlyL10n fallback + non-empty known keys; CashlyResourceFile data + decoded<[User]> + decoded<[Category]>; CashlyResourceImage rawValues + avatar fallback paths. CashlyLoggerTests (3): subsystem const + 6 categories reachable + .info logging non-crash. 296 tests / 47 suites passing.
**Impacto**: Resource target leaf agora coberto. Coverage map: Domain (28) + Data (32+9=41) + Presentation (107) + DesignSystem (47) + Resource (25) + UI (11) + Snapshots (7) = 296 tests.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: Bundle.module resolução de localized strings funciona em test runner; non-existent keys retornam a própria chave (Apple fallback behavior). Em testes XCTest, `os.Logger.info(_:)` é safe-to-call sem capture/verification — apenas smoke.

---

## 2026-05-11 — Wave 5r (FilterState + CashlyError tests)

**Tipo**: test
**Módulos**: CashlyTests/States/FilterStateTests, CashlyTests/Domain/CashlyErrorTests
**Resumo**: 16 testes novos. FilterStateTests (5): default init, Equatable/Hashable polish, Set membership. CashlyErrorTests (11): legacy cases + .unknown + PersistenceError + DomainError + umbrella forwarding + description fallback. 285 tests / 45 suites passing.
**Impacto**: Coverage agora cobre estados de filtro (importante para `onChange(of: filter)` em CashlyApp) e error surface completa (legacy + typed variants).
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: CashlyError tem 3 buckets de variants — legacy (onFetch/onSave/onRemove para retrocompat), .unknown(message:) para erros anônimos, e wrappers tipados (.persistence(.fetchFailed(...)) / .domain(.invalidInput(...))). Tests confirmam que cada bucket tem mensagem + recovery + failure reason coerente.

---

## 2026-05-11 — Wave 5q (Double + Transaction extensions + Participant tests)

**Tipo**: test
**Módulos**: CashlyTests/UI/DoubleExtensionTests, CashlyTests/Domain/TransactionExtensionsTests, CashlyTests/Actors/ParticipantActorTests
**Resumo**: 12 testes novos. DoubleExtension (4): currencyColor polarity (zero vs non-zero reference), percentage rounding, variationMessage/Color thresholds. TransactionExtension (6): participantsAmount(filter:) empty/paymentsPlan/participants paths + filter sum/no-match; shareMessage header/count/total structure. ParticipantActor (2): smoke + add/remove roundtrip via MockParticipantActor. 269 tests / 43 suites passing.
**Impacto**: Extension surfaces e Participant actor cobertos. Coverage map agora cobre Domain (entities, enums, score, transaction extensions, Codable), Data (5 actors + IntelligenceService + Adapter FK), Presentation (6 reducers + 6 middlewares + states + bindings + route + ApplicationAction + env), DesignSystem (color/shape/spacing/router/routable/systemMonitor/Color(hex)), Resource (Analytics + Signpost), UI (Double extension + snapshots).
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: `@testable import CashlyUI` permite testar extensions internal (Double.currencyColor não é public — não bate em compile barrier mas precisa @testable).

---

## 2026-05-11 — Wave 5p (cross-cutting glue tests: ApplicationAction + env + analytics + signpost)

**Tipo**: test
**Módulos**: CashlyTests/Presentation/{ApplicationAction, EnvironmentValues}Tests, CashlyTests/Resource/{AnalyticsTracker, CashlySignpost}Tests
**Resumo**: 15 testes novos cobrindo glue layer. ApplicationAction umbrella wrapping (1), EnvironmentValues @Entry defaults (8 — verify state.new() defaults, nil user, no-op action closure), AnalyticsTracker protocol (3 — default track(event:) forwards, NoopAnalyticsTracker, SpyTracker), CashlySignpost.withInterval (3 — sync/async returns body value + rethrows). 255 tests / 44 files / 40 suites passing.
**Impacto**: Cross-cutting layer agora testado — composition root patterns (env defaults, analytics injection) e observability primitives (signpost return-passthrough) cobertos.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: SwiftUI EnvironmentValues() default-init instancia todos os @Entry defaults — tests podem assertar contra eles sem mock view hierarchy.

---

## 2026-05-11 — Wave 5o (G020 a11y tail — icon-only buttons labeled)

**Tipo**: a11y
**Módulos**: 4 Add* screens (AddBudget/AddCategory/AddTag/AddUser)
**Resumo**: VoiceOver tail. Audit identificou 4 screens com saveButton/removeButton icon-only sem accessibilityLabel — só checkmark/trash CashlySymbol. AddTransactionScreen+Toolbar e TransactionScreen+Toolbar já tinham labels. Adicionados `.accessibilityLabel(CashlyL10n.string("Save"))` / `"Delete"` em todos. Snapshots re-gravados (sem mudança visual mas snapshot harness rejeitava attribute change). 240 tests passing. a11y label count: 14 → 22.
**Impacto**: G020 tail efetivamente fechado. Toda toolbar action icon-only agora anuncia ação para VoiceOver.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: snapshot-testing detecta attribute-tree changes mesmo quando visual diff é zero — accessibilityLabel não muda pixels mas muda hierarchy; precisa re-record.

---

## 2026-05-11 — Wave 5n (DocC for Data/UI/Mock/Resource + Domain symbol docs)

**Tipo**: docs
**Módulos**: CashlyData.docc, CashlyUI.docc, CashlyMock.docc, CashlyResource.docc; symbol docs em Budget/Category/TransactionStatus/TransactionSplitMode/CashlyState/Action/Reducer/Middleware/Store
**Resumo**: 4 catalogos DocC adicionais — agora todos os 7 SPM targets têm DocC catalog (CashlyDesignSystem, CashlyDomain, CashlyPresentation já tinham). Per-target topics: Data (factory + actors + adapter + intelligence), UI (screens + view extensions), Mock (factory + mock actors + MockModifier), Resource (L10n + files + Logger/Signpost + AnalyticsTracker). Symbol docs em Domain entities clarificam packed YYYYMM dates, hex color convention, directional vs terminal TransactionStatus, per-case SplitMode arithmetic. Typealiases em CashlyPresentation ganham descrições dos roles + write-seam pattern. 240 tests ainda passando.
**Impacto**: G016 + G024 essencialmente fechados. Documentação navegável por `docc preview` em qualquer target.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: DocC catalog `.docc/` dentro de Sources/{Module} é auto-detectado pelo SwiftPM — nada precisa ser adicionado ao Package.swift. Cross-module symbol refs em topic lists usam `ModuleName/Type/symbol(args:)` pattern.

---

## 2026-05-11 — Wave 5m (Domain+Presentation DocC + hot-path signposts)

**Tipo**: docs + perf
**Módulos**: CashlyDomain.docc, CashlyPresentation.docc, MainState+Computed (signposts)
**Resumo**: DocC catalogs para Domain (entities, transaction enums, scoring, use cases, errors, intelligence types) e Presentation (stores, replace seam, States/Actions/Reducers/Middlewares, MainRoute, factory). Signposts adicionados em `MainState.transactionSections` (Dictionary grouping by date) e `MainState.biggestTags` (nested transactions × tags loop) — junto com o existente `MainState.score`, ficam 3 hot paths agora visíveis no Instruments Signposts track. 240 tests ainda passando.
**Impacto**: G024 ampliado. DocC catalogs prontos para `docc preview` por target. Performance observability cobre os 3 derived properties mais caros do MainState.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: DocC `.docc/` bundle dentro de Sources/{Module} é auto-detectado pelo SwiftPM build sem Package.swift change. Symbol refs em DocC topic lists podem ser cross-target via fully-qualified module name (e.g. `PrismArchitecture/PrismStore/cashlyBinding(_:)`).

---

## 2026-05-11 — Wave 5l (CI rewrite + CashlyDesignSystem DocC)

**Tipo**: ci + docs
**Módulos**: .github/workflows/ci.yml, CashlyDesignSystem.docc/CashlyDesignSystem.md, symbol docs em CashlyText/Color/Spacing/Shape/Routable/Router
**Resumo**: CI workflow stale (referenciava Cashly.xcworkspace inexistente + scheme Core dropado, sem provisão de Prism sibling). Reescrito: checkout cashly + prism sibling, xcodebuild test via CashlyKit-Package scheme (validado localmente — `** TEST SUCCEEDED **` 240 testes). DocC: CashlyDesignSystem.md landing page com topic grouping (Text/Layout/Lists/Controls/Tokens/Navigation/View/Observability/Loading). Symbol-level docs nos types mais tocados — CashlyText loading-state behavior, CashlyColor per-case semantic, CashlySpacing rhythm guidance, CashlyShape mapping, CashlyRoutable Hashable note pós hash-recursion fix, CashlyRouter dismiss priority. Drop stale `import PrismUI` em CashlyText. 240 testes ainda passando.
**Impacto**: G024 (observability/docs) ampliado. CI alinhada com Prism-based build. DocC ready para `docc preview`.
**ADR**: nenhum
**PRs**: 2 commits em main (CI + docs separadamente)
**Aprendizados**: SwiftPM local path deps (`../../prism`) requerem sibling checkout em CI. `set -o pipefail` antes de xcodebuild | xcbeautify é mandatory — `|| exit 1` depois do pipe não captura xcodebuild failures porque xcbeautify exits 0.

---

## 2026-05-11 — Wave 5k (test suite GREEN — 240 testes passing)

**Tipo**: fix + test
**Módulos**: CashlyDesignSystem/CashlyRoutable (hash bug fix), CashlyTests (assertion adjustments), Snapshots (re-recorded)
**Resumo**: Primeira execução real `xcodebuild test` revelou 3 classes de issues:
1. **CashlyRoutable.hash recursion**: default `hash(into:)` combinava `id` que era `Self` → infinite recursion. Crash em todos os 36 test suites. Fix: removido default hash; conformers fornecem próprio. MainRoute já tinha (discriminator-based); RawRepresentable enums (SimpleRoute, TestRoute) ganham Hashable synthesis grátis.
2. **Mock fixture interference**: User.mocks JSON pre-seeds 5 users. Tests assumindo store vazio quebravam. Fix: assert por id presence ao invés de exact ordering / value match. Mock contracts diferem do real actor (MockUserActor appends sem upsert vs UserActor SwiftData upsert real).
3. **TZ-sensitive yearMonth test**: `Date(timeIntervalSince1970: 0)` em BRT → 1969-12-31 → yearMonth 196912 ≠ 197001. Fix: usar DateComponents explícitos.
4. Snapshot baselines regravados post Wave 5a (UI mudou).
**Resultado**: 240 tests passing. `** TEST SUCCEEDED **`.
**Impacto**: Source bug real (CashlyRoutable hash recursion) descoberto por testes — bug latente que nunca crashou em produção porque NavigationStack codifica path em vez de hashear. Vale o investimento em test execution real, não apenas compilation.
**ADR**: nenhum
**PRs**: 1 commit em main
**Aprendizados**: SPM `xcodebuild test` via `CashlyKit-Package` scheme funciona (não o app Production scheme — esse só roda app target). Mock actor semantic é approximation do real SwiftData actor — tests precisam ser robustos ao contract diff.

---

## 2026-05-11 — Wave 5j (G017 MockAdapter FK + entity Codable; G007 SPM note)

**Tipo**: test + chore
**Módulos**: CashlyTests/Mocks/MockAdapterActorTests, CashlyTests/Domain/EntityCodableTests, Package.swift comment
**Resumo**: 15 testes novos cobrindo gaps remanescentes. MockAdapterActor (7): FK miss/hit em categoryAdapted/tagAdapted/transactionAdapted; userAdapted sem FK; invalid status raw. Entity Codable (8): User/Category/Budget/Tag/Participant/Transaction + TransactionStatus/SplitMode roundtrip JSON. G007 SPM: tentou `condition: .when(configuration: .debug)` em target dep — não existe na API SwiftPM (`configuration:` só para `.platforms`). Edge `.ui → .mock` permanece unconditional; symbols `#if DEBUG`-guarded em todos os 21 imports → linker dead-codes em Release. Comment atualizado em Package.swift. Inventory total: 40 files / 241 @Test declarations.
**Impacto**: Coverage chega no surface mais wide possível por static testing — entity persistence, FK resolution, e adapter behavior cobertos. G017 essencialmente fechado.
**ADR**: nenhum
**PRs**: 1 commit
**Aprendizados**: SwiftPM `condition:` API só aceita `.when(platforms:)`. Para debug-only deps usar `#if DEBUG` em imports + confiar em dead-code elimination — não há flag SPM nativa.

---

## 2026-05-11 — Wave 5i (G017 IntelligenceService + Routable + MainRoute + enums)

**Tipo**: test
**Módulos**: CashlyTests/Data/CashlyIntelligenceServiceTests, CashlyTests/DesignSystem/{CashlyRoutable, CashlySystemMonitor}Tests, CashlyTests/Presentation/MainRouteTests, CashlyTests/Domain/TransactionEnumsTests
**Resumo**: G017 cobertura quase saturada. 34 novos testes:
- IntelligenceService (9): tabularData/textData data shaping com participant/paymentsPlan respect; rejects wrong-model.
- CashlyRoutable defaults (4): id == self, hash, NavigationStyle distinct.
- CashlySystemMonitor (3): default/explicit init + Equatable.
- MainRoute (6): discriminator-based equality ignora payload — addUser(state: A) == addUser(state: B). Hash matches case identity.
- TransactionEnums (12): Status.reverse pairs, SplitMode.value para cada modo (equal/fixedAmount/percentage/payerBased), nil-guards.
Inventory total: 38 files / 226 @Test declarations.
**Impacto**: G017 "parcial muito avançado" → "essencialmente fechado". Pure-function Domain + Data shaping + state derivation + design tokens + routing tudo coberto.
**ADR**: nenhum
**PRs**: 2 commits direto em main
**Aprendizados**: MainRoute equality é intencionalmente discriminator-only (case identity), não case+payload — navegação não deve diferir por mudança no State carregado. Padrão útil para Routes que carregam State como navegação argument.

---

## 2026-05-11 — Wave 5h (G017 DesignSystem + state computed + Store binding tests)

**Tipo**: test
**Módulos**: CashlyTests/DesignSystem/{CashlyShape, CashlyColor, CashlyRouter}Tests, CashlyTests/States/AddStateComputedTests, CashlyTests/Presentation/StoreBindingTests
**Resumo**: G017 cobertura ampliada para o seam UI ↔ Presentation. 36 testes novos:
- CashlyShape (4): path geometry matches SwiftUI primitives via boundingRect.
- CashlyColor (9): cada token semântico + .color(nil)/.hex(nil) → .clear + .color(c) passthrough.
- CashlyRouter (8): push/present/full + root()/dismiss() priority (path → present → full → isPresented). TestRoute fixture conforming CashlyRoutable.
- Add*State.canSave (10): regras de cada formulário + AddUserState.photos male/female + AddBudgetState.user derivation + yearMonth packing + AddTransactionState.categories projection + summaryTags substring filter.
- StoreBinding (5): cashlyBinding/Mutate/Replace dispatch via .replace + nested keypath round-trip via SwiftUI.Binding dynamic member lookup.
Inventory total: 33 files / 192 @Test declarations.
**Impacto**: G017 "parcial avançado" → "parcial muito avançado". Cobertura: Domain (Score), Data (5 actors), Presentation (reducers/middlewares/states/bindings), DesignSystem (shape/color/spacing/router/Color(hex)), UI snapshots.
**ADR**: nenhum
**PRs**: 2 commits direto em main
**Aprendizados**: PrismStore.send(_:) síncrono dispara reducer mas reentrant guards/effect handling exigem Task.yield para state observable atualizar em testes. SwiftUI.Binding @dynamicMemberLookup projeta keypaths nested mantendo binding chain — `binding.field.wrappedValue` é syntax válida pós-projection.

---

## 2026-05-11 — Wave 5g (G014: data actors + Domain Score tests)

**Tipo**: test
**Módulos**: CashlyTests/Actors/{Category, User, Tag, Transaction}ActorTests, CashlyTests/Domain/ScoreTests, CashlyTests/Common/CommonTestSuite (expandido)
**Resumo**: G014 fechado em "parcial avançado". Expandido CommonTestSuite para expor todos 6 UseCase handles (era apenas budget+category). 4 atores SwiftData novos cobertos com integration tests pattern BudgetActorTests: roundtrip add+fetch, unknown returns nil, remove drops, upsert on conflicting id. Sort/list paths cobertos onde aplicável. Domain Score ganhou tests puro-função: level cutoffs (200-499, 500-699, 700-894, 895-1000), progress linear, stable id == title. Total: 22 testes novos (15 actors + 7 score).
**Impacto**: G014 status: BudgetActor-only → 5 atores cobertos (Adapter ainda smoke-only). Inventory total: 28 files / 156 @Test declarations.
**ADR**: nenhum
**PRs**: 2 commits direto em main
**Aprendizados**: SwiftData @ModelActor + isStoredInMemoryOnly cria store fresh por suite struct instance. Tests não precisam tearDown — cada CommonTestSuite() bootstrapa novo container. Mock adapter resolve user FK via User.mocks JSON — tests precisam usar `User.mock` para que adapter encontre o user no JSON, OU inserir via UserUseCase antes (TagActor pattern).

---

## 2026-05-11 — Wave 5f (G017 middleware integration tests, all 6 middlewares)

**Tipo**: test
**Módulos**: CashlyTests/Common/{EffectHelpers, UseCaseDoubles}, CashlyTests/Middlewares/{AddUser, AddCategory, AddTag, AddBudget, AddTransaction, Main}MiddlewareTests
**Resumo**: Cobertura completa de middleware integrations. Infraestrutura nova: `collectActions(from:timeout:)` para drenar PrismEffect.actions AsyncStream em [Action] com bounded 5s timeout; UseCaseDoubles para todos os 6 Domain UseCase protocols com programmable returns + throw flags + CallRecorder thread-safe. Tests dirigidos por ações: dispatch action → observe action sequence emitted by effect → assert. Sem SwiftData, sem in-memory store. 6 middlewares cobertos: AddUser (11), AddCategory (8), AddTag (8), AddBudget (7), AddTransaction (6), Main (9) — total 49 testes de middleware. Inventory total: 23 arquivos / 134 @Test declarations.
**Impacto**: G017 fechado em "parcial substancial" → "parcial avançado". Middleware happy paths + error paths + dependency-blocked paths cobertos. Faltam: snapshot tests post-Wave-5a (alguns podem precisar re-record) e UI interaction tests (futuro).
**ADR**: nenhum
**PRs**: 2 commits direto em main
**Aprendizados**: PrismEffect.actions AsyncStream é drainable a partir de qualquer Task — útil para tests. CashlyError não conforma Equatable (PrismError refina apenas Codable/CustomStringConvertible) — usar `if case .X = state.error` em vez de `==`. Test doubles thread-safe via NSLock são cheaper que actor wrappers e suficientes para tests sync.

---

## 2026-05-11 — Wave 5e (G017 test coverage boost)

**Tipo**: test
**Módulos**: CashlyTests/Reducers/*, CashlyTests/States/MainStateComputedTests, CashlyTests/DesignSystem/{ColorHexTests, CashlySpacingTests}
**Resumo**: G017 (parcial test coverage) substancialmente avançado. +9 arquivos de teste (de 6 p/ 15), +70 @Test declarations (de 15 p/ 85). Cobertura:
- 6 reducers x 6-10 cases cada (42 testes): fetch/stopLoading/update/saved/error/replace + ações no-op verificadas.
- MainState computed (8 testes): budgetsAmount/remainingAmount/variation/score/budget(for:)/partition/biggestTransactions.
- Color(hex:) (7 testes): nil/empty/malformed/6digit/8digit/whitespace.
- CashlySpacing (12 testes): todos tokens nominal + negative + custom.
TEST BUILD SUCCEEDED no iPhone 17 simulator. Execução CLI falha por SPM xctest bundle config — Xcode-only runtime.
**Impacto**: G017 de "parcial (smoke + snapshots)" para "parcial substancial". Próximo seria middleware integration tests com mock UseCases — fora de escopo agora.
**ADR**: nenhum
**PRs**: 2 commits direto em main
**Aprendizados**: PrismReducer pure-function shape (`reduce(into:action:) -> PrismEffect`) facilita test — basta criar State, dispatch action, verificar state mutated. Effects descartados nestes tests; mid-test middleware integration é wave futura.

---

## 2026-05-11 — Wave 5d (G016 README + G019 MainState split)

**Tipo**: docs + refactor
**Módulos**: README.md, CashlyPresentation/States/MainState.swift (split), CashlyPresentation/States/MainState+Computed.swift (novo)
**Resumo**: README reescrito pós-Wave 5a (7 SPM targets, Prism state-mgmt, CashlyDesignSystem, composition root, cashlyBinding/Mutate). MainState (268 linhas) cortado em MainState.swift (54 lin — data + init) + MainState+Computed.swift (211 lin — score/variation/sections/biggest*/etc). Ambos confortavelmente abaixo do cap 280. Audit confirmou: zero literal strings hardcoded fora de CashlyL10n.string; Logger + Signpost ativos.
**Impacto**: G016 e G019 (residual god-files) fechados. G020 confirmado fechado em auditoria — sem strings hardcoded em UI. Migration backlog efetivamente vazio.
**ADR**: nenhum
**PRs**: commit direto em main
**Aprendizados**: Computed properties em States podem viver em extension separada quando viram >150 linhas — separação data/derivação melhora navegação sem mudar API.

---

## 2026-05-11 — Wave 5c (G001 Domain Intelligence purification)

**Tipo**: refactor (architecture — Domain hygiene)
**Módulos**: CashlyData/Services/CashlyIntelligenceService (novo), CashlyDomain/Utils/CashlyIntelligence (slim), CashlyUI/Screens/IntelligenceScreen, Package.swift
**Resumo**: G001 fechado. PrismIntelligence training (PrismTabularIntelligence, PrismTextIntelligence) movido de Domain p/ Data via `CashlyIntelligenceService`. Domain mantém apenas o enum `CashlyIntelligence` (cases + display strings + `model(for:)`) e os typealiases (Model/Result/Prediction/PredictionResult/PredictionInput) que State types referenciam — necessários para boundary, não infraestrutura. Auditoria adicional confirmou: G002 (SwiftData @Model em Domain), G004 (SwiftUI.Color em Score), G005 (singletons), G006 (BudgetActor inline factory) já fechados em waves anteriores. Stale `CashlyDomain/Factories/CashlyPresentationFactoryProtocol.swift` placeholder removido. BUILD SUCCEEDED.
**Impacto**: 5 gaps de arquitetura fechados (G001 + auditoria G002/G004/G005/G006). Migration backlog praticamente vazio — restam só docs (G016 README), god-files residuais (G019), e i18n/a11y tail (G020).
**ADR**: nenhum novo
**PRs**: commit direto em main
**Aprendizados**: Domain pode importar PrismIntelligence apenas para typealiases sem trazer infraestrutura — pattern aceitável onde lib provê tipos de dado e algoritmos juntos. Decisão: tipos de dado em Domain, algoritmos em Data via Service struct injetável.

---

## 2026-05-11 — Wave 5a COMPLETO (Prism merged + G003+G022+G033+G036 fechados)

**Tipo**: feat (migration — Architecture cutover, MAIN GREEN)
**Módulos**: Package.swift, todos 6 Reducers, 6 Middlewares, 6 Action enums, Factory protocols, MockModifier, CashlyApp, EnvKeys
**Resumo**: Quinta tentativa Wave 5a em branch `migration/wave-5a-attempt-5` — SUCESSO. Package.swift trocado para local Prism path. Pre-requisites de Wave 5a' (binding seam) + Wave 5a'' (drop `.ryze(...)` modifiers) habilitaram o cutover mecânico. Padrão final: `case replace(State)` em cada Action, conforming a `CashlyReplaceableAction`, dispatched via PrismStore.send a partir dos helpers cashlyBinding/cashlyMutate/cashlyReplace. PredictionCache lift para actor privado interno em MainMiddleware. CashlyEntity refinada com Identifiable (PrismEntity dropou esse refinement). CashlyApp.swift e MockModifier dropam `@Environment(\.theme)`; usam `Color.accentColor`. BUILD SUCCEEDED iPhone 17 simulator. Branch fast-forwarded para main.
**Impacto**: G003 (cross-cutting Ryze), G022 (Ryze→Prism), G033 (Reducer API incompat), G036 (binding pattern) todos fechados. Abertos restantes: G001, G002, G004 (Domain hygiene), G005, G006 (DI). Apenas hygiene/DI gaps continuam abertos — todo o pesado de migração resolvido.
**ADR**: 0002 + 0003 já documentavam estratégia; outcome confirmado.
**PRs**: merge direto main via fast-forward de migration/wave-5a-attempt-5.
**Aprendizados**: PrismStore<State, Action> (não <Reducer, Middleware>) — direct generic params mudam call sites. `state` é `private(set)` — write seam via `.replace(State)` case é mais clean que `replaceState` API exposure. PrismReducer associatedtypes resolvem associada limpa quando Reducer e Middleware compartilham State/Action concretos. PrismMiddleware Sendable struct OK desde que cache mutável vire actor interno. CashlyEntity precisa Identifiable explicit (PrismEntity não tem). `\.isLoading` env é Cashly-owned now. Sem `@retroactive @unchecked Sendable` necessário — PrismStore já é @MainActor.

---

## 2026-05-11 — Wave 5a'' (drop residual .ryze() modifiers)

**Tipo**: refactor (migration prep)
**Módulos**: CashlyUI/Extensions/View+Extension, CashlyDesignSystem/CashlyConfetti, CashlyDesignSystem/CashlyBackgroundRow
**Resumo**: 7 `.ryze(...)` modifiers restantes em CashlyUI eliminados. CashlyConfetti (piece+container+modifier) e CashlyBackgroundRowModifier portados para CashlyDesignSystem. View+Extension reescrito 100% nativo: cashly(font:weight:design:), cashly(loading:), cashlyBackgroundItem, cashly(if:), cashly(item:), cashlyConfetti, cashly(symbol:). Drop `import RyzeUI` da View+Extension. Build verde.
**Impacto**: Última ponte de modifier visual com Ryze removida. Pre-requisite para Wave 5a real merge mecânico.
**Aprendizados**: SwiftUI Binding.@dynamicMemberLookup permite `store.cashlyBinding(\.filter).startDate` nested projection sem keypath chain manual.

---

## 2026-05-11 — Wave 5a' (binding seam — G036 fix)

**Tipo**: refactor (migration prep)
**Módulos**: Store+Binding.swift (novo), 11 view files
**Resumo**: Cashly screens usavam `@Bindable var store; $store.state.field` (23 sites) e `store.state.X = value` (~15 sites) — pattern impossível com PrismStore (state é private(set)). Introduzido `Store+Binding.swift` com `cashlyBinding(_:)`, `cashlyMutate(_:_:)`, `cashlyReplace(_:)`. Hoje (Ryze) escreve direto em state[keyPath:]; depois (Prism) só esse arquivo precisa mudar. 24 `@Bindable var store = store` shadows removidos. Build green ainda em Ryze.
**Impacto**: G036 fix preparado. Wave 5a real merge agora mecânico.
**Aprendizados**: Multi-field mutations refatoradas para copy-mutate-write-back pattern: `var arr = store.state.X; arr[i] = v; store.cashlyMutate(\.X, arr)`. Comportamento idêntico, semântica explícita.

---

## 2026-05-11 — Wave 5a Attempt #4 (deferred again, G036 discovered)

**Tipo**: chore (migration — exploration, branch deleted)
**Módulos**: Package.swift, todos Reducers, Middlewares, Factories, MockModifier (todos no branch deletado)
**Resumo**: Quarta tentativa Wave 5a em branch `migration/wave-5a-prism-attempt-4`. Package.swift trocado para local Prism, 6 Reducers + 6 Middlewares portados para `@MainActor struct: PrismReducer/Middleware` com `inout state` + `PrismEffect.run`. MainMiddleware ganhou `PredictionCache` actor interno para cache mutável. Factory protocols movidos para Presentation, marcados `@MainActor`. View+Extension reverteu `.cashly(...)` para nativo (color/tint/clip/alignment). Bulk sed Ryze→Prism limpo. Bloqueio: `$store.state.x` two-way bindings em ~25 sites — PrismStore.state é `private(set)`, mutação só via `send(action:)`. Branch deletado, main intacto.
**Impacto**: ADR-0002 atualizado com findings attempt #4. G036 novo gap criado (bloqueia Wave 5a real merge). Próxima tentativa precisa de Wave 5a' (refactor bindings → actions ou PrismStore.scope) antes do Package swap.
**ADR**: 0002 atualizado, 0003 não tocado
**PRs**: nenhum
**Aprendizados**: PrismStore.state é read-only por design — Cashly's `@Bindable var store = store; $store.state.filter.X` pattern não compila. Opção mais limpa: `PrismStore.scope(state: keyPath, action: action)` cria child stores binable. `\.theme` env não migrou para PrismUI; usar `Color.accentColor` nativo. PrismFileManager/PrismTabularIntelligence/PrismTextIntelligence existem 1:1. `\.isLoading` env é Cashly-side now — adicionar EnvironmentKey próprio em CashlyDesignSystem. CashlyDataFactoryProtocol precisa `@MainActor` (PrismStore é @MainActor). MockCashlyFactory tinha que ser @MainActor inteiro.

---

## 2026-05-11 — Wave 5b Completo + ADR-0003 (CashlyDesignSystem Cashly-owned)

**Tipo**: feat (migration — design system layer)
**Módulos**: CashlyDesignSystem (novo target), CashlyUI, CashlyMock, CashlyPresentation, Package.swift
**Resumo**: Wave 5b inteiro entregue. CashlyDesignSystem agora possui tipos próprios: CashlyText/Spacer/Symbol/Spacing/HStack/VStack/ZStack/Button/Label/Color/Shape/View/CurrencyTextField/List/HorizontalList/SystemMonitor/Routable/Router/NavigationView. Surface Cashly* não depende mais de RyzeUI/RyzeArchitecture para vocabulário (apenas State/Action/Reducer/Middleware/Store remanescentes). Modifiers `.cashly(color:tint:background:clip:alignment:systemMonitor:)` reescritos para SwiftUI nativo. CashlyDesignSystem virou dep de CashlyPresentation (router types). G023 e G035 fechados.
**Impacto**: 9 commits this session. Wave 5a real merge (Ryze→Prism Package swap) permanece deferred per ADR-0002 (escopo 6 Reducers + 6 Middlewares com mudança de API actor→@MainActor inout state). Wave 5b unblocked desse trabalho — Prism cutover futuro só toca Architecture layer + 2 aliases (State/Action/Reducer/Middleware/Store).
**ADR**: 0003-cashly-design-system (vocabulário Cashly-owned, layering, ownership table)
**PRs**: pushes diretos em main
**Aprendizados**: `@_exported import SwiftUI` em DS root vaza ObjC `Category` (UIKit typedef) via UIKit transitivo — quebra CashlyDomain.Category lookup em CashlyPresentation. Usar `import SwiftUI` plain. CashlyColor enum precisa de cases ópticos (Color?, String?) para casar com call sites que passam Color opcional. CashlyShape como enum Sendable é mais clean que struct com closure não-Sendable.

---

## 2026-05-11 — Wave 5a Real Attempt (Architecture layer green, UI gap → G035)

**Tipo**: chore (migration — exploration, branch deleted)
**Módulos**: Reducers, Middlewares, Factories, Protocols, EnvironmentValues, MockModifier
**Resumo**: Terceira tentativa Wave 5a em branch `migration/wave-5a-prism`. Architecture layer (Reducer/Middleware/Factory/Store) portado completo e compilando. UI layer (CashlyUI typealiases) bloqueia com 57 errors em tipos PrismUI inexistentes (PrismView/Text/Label/Symbol/HStack/...). Branch deletado, main intacto. Lições consolidadas em G035.
**Impacto**: Padrão de migração Reducer/Middleware validado end-to-end. Wave 5b = CashlyDesignSystem target ou per-call-site SwiftUI replacement. Pre-requisitos resolvidos (G034 State Sendable, ADR-0002 mapping).
**ADR**: 0002 ainda válido + futuro 0003 quando Wave 5b decidir CashlyDesignSystem strategy
**PRs**: nenhum
**Aprendizados**: PrismStore<State, Action> não PrismStore<Reducer, Middleware> — typealiases CashlyStore generic params mudam. CashlyPresentationFactoryProtocol não pode estar em Domain (referencia States/Actions de Presentation). Protocol associatedtypes não funcionam com Prism — usar concreto PrismStore<S,A>. EnvironmentValues @Entry de tipos MainActor requer EnvironmentKey explícito com @preconcurrency. theme env renomeado para prismTheme em Prism. PrismMock substitui PrismUIMock (sem View constraint). PrismTheme usa color(.brand) não color.primary. PrismUI carece de 14+ tipos visuais que Cashly usa pesadamente → G035 dedicado.

---

## 2026-05-10 — Wave 5a Second Spike (ADR-0002 + G034)

**Tipo**: chore (migration — exploration, branch deleted)
**Módulos**: ADR-0002, gap-analysis G034, progress-log
**Resumo**: Segunda tentativa Wave 5a em branch `migration/wave-5a-prism`. Package.swift trocado para submódulos Prism (`../../prism`). Bulk rename Ryze→Prism completo. 6 Reducers portados para `@MainActor struct: PrismReducer` com `reduce(into:action:) -> PrismEffect<Action>`. 2 Middlewares portados (AddUser, AddCategory). Bloqueio: State Sendability — 5 dos 6 States carregam `SwiftUI.Color` (MainActor-bound) que viola `@Sendable` capture em `PrismEffect.run`. Branch deletado, main intacto.
**Impacto**: Main em `f3349dd`. ADR-0002 escrito com mapping table validada. G034 novo gap. Wave 5 segue bloqueado mas com plano claro.
**ADR**: 0002-wave-5-prism-migration-spike
**PRs**: nenhum
**Aprendizados**: PrismStore `init(initialState:reducer:middleware:)` matches Cashly call sites — não há ajuste de dispatch sites. State refactor é blocker real, não API redesign. Recomendado: opção (a) drop SwiftUI.Color de State, usar String hex + Color(hex:) na UI. PrismMiddleware.run retorna PrismEffect; `.run { send in ... }` substitui AsyncStream + continuation.yield. Prerequisite para Wave 5a real: 1) decisão State Sendability, 2) port AddUser trio end-to-end como validation, 3) ripple para 5 outras trios.

---

## 2026-05-10 — Wave 5a Aborted (G033 — Reducer API incompatible)

**Tipo**: chore (migration — exploration)
**Módulos**: CashlyKit/Package.swift, all CashlyKit sources (sed-renamed, then reverted via stash drop)
**Resumo**: Tentativa Wave 5a. Strategy aprovada: gradual via typealiases, Prism local path, fix PrismUI missing components via CashlyDesignSystem interno. Package.swift atualizado para usar submódulos Prism diretos (evita PrismSecurity broken upstream UIKit import). Bulk sed renomeou `import Ryze*` → `import Prism*` (44 files) e `Ryze*` symbols → `Prism*` (todos os refs). Build falhou: 6 Reducers + 6 Middlewares incompatíveis com nova API PrismReducer/Middleware (assinaturas + isolation diferentes). Stash dropado.
**Impacto**: Main intacto em `ccd419a`. Aprendizado consolidado em G033. Wave 5 real requer sessão dedicada com spike.
**ADR**: nenhum (não houve mudança de policy, só exploração)
**PRs**: nenhum
**Aprendizados**: PrismReducer = `func reduce(into state: inout State, action: Action) -> PrismEffect<Action>` (sync, MainActor, mutating). Cashly = `func reduce(state:action:) async -> State` (async, actor, value return). Não é rename: é redesign. Mesma situação para Middleware/Store/dispatch. Usar Prism submódulos diretos (PrismFoundation, PrismArchitecture, PrismIntelligence, PrismUI) em vez do umbrella `Prism` evita PrismSecurity broken upstream (`import UIKit` faltando em PrismIntegrityChecker.swift). Color.init(hex:) também mudou signature em PrismUI.

---

## 2026-05-10 — Wave 6 Complete + BUILD GREEN

**Tipo**: chore (migration)
**Módulos**: CashlyUI, CashlyDomain
**Resumo**: Build CLI verde pela primeira vez. G032 fechado: 8 views com `@Bindable var store = store` em computeds que usam `$store.x`. Bonus fixes: `cashlyConfetti` ganha param `isActive`, `CashlyIntelligence` declara `Sendable`, `RyzeIntelligencePredictionInput` retroactive `@unchecked Sendable`.
**Impacto**: `xcodebuild build` retorna `BUILD SUCCEEDED` em iOS Simulator destination. CI agora viável. Tests/snapshots deferidos de Wave 0 podem ser escritos.
**ADR**: nenhum
**PRs**: commit 5bdbd6f
**Aprendizados**: Pattern `@Bindable var store = store` dentro de computed property é o equivalente moderno de `@EnvironmentObject` + `$store.x` projection. Funciona porque `@Bindable` shadowing em scope local sintetiza `$` para acesso a propriedades de `@Observable` types. Retroactive Sendable usado pragmaticamente para types upstream sem conformance (`RyzeStore`, `RyzeIntelligencePredictionInput`) — não ideal mas desbloqueia até Wave 5 (Prism migration).

---

## 2026-05-10 — Wave 6 Partial (G018 + G031 + Sendable)

**Tipo**: chore (migration)
**Módulos**: CashlyApp, CashlyMock, CashlyUI, CashlyPresentation
**Resumo**: Wave 6 parcial (commits `08e17b0`, `697dd16`, `fd7f73e`). 13 views + CashlyApp + MockModifier migrados de `@StateObject`/`@EnvironmentObject` para `@State`/`@Environment(T.self)`. RyzeView default `mocked()` extension fecha G031. RyzeStore retroactive Sendable resolve race em MockModifier.
**Impacto**: Build CLI ~95% verde. Bloqueio remanescente: G032 (25 call sites usam `$store` projection que não existe em `@Environment(T.self)`).
**ADR**: nenhum
**PRs**: commits 08e17b0, 697dd16, fd7f73e
**Aprendizados**: `@Environment(T.self)` não tem `$projection`. Use `@Bindable var store = store` no body para reativar `$store.x` bindings com `@Observable` types. Migração StateObject→State é mecânica para storage e ambient supply, mas bindings exigem @Bindable. `@retroactive @unchecked Sendable` mitiga ausência de Sendable em RyzeStore pinned ver.

---

## 2026-05-10 — Wave 2 Partial (G030 + Ryze re-pin + keypath refactor)

**Tipo**: chore (migration)
**Módulos**: CashlyKit/Package.swift, Domain, Presentation, Mock, UI
**Resumo**: Wave 2 parcial (commit `0b203eb`). Ryze re-pinado para `2b619d8` (último commit antes do refactor da58a6f que mudou RyzeReducer API). G030 fix: MainRoute `hash(into:)` adicionado. 8 call sites `sorted(by: \.KeyPath, using:)` substituídos por closure form. Transaction.shareMessage nested ternary refatorado em helper `participantsAmount(filter:)`.
**Impacto**: Build CLI progrediu de Reducers (G029) para MockModifier (G018 territory). ~80% da dep graph compila. RyzeStore @Observable agora válido (re-pin); MockModifier `@StateObject` legado bloqueia próximo passo.
**ADR**: nenhum (re-pin é tactical, não policy)
**PRs**: commit 0b203eb
**Aprendizados**: Re-pin de Ryze pra `2b619d8` resolveu G029 (signature match) automaticamente. Cashly code é stale vs current Ryze API. Pinning é mitigação até Wave 5 (Ryze→Prism). `sorted(by: \KeyPath)` extension em Ryze mudou para esperar optional keypaths — call sites de Cashly precisaram closures. Nested ternaries em Transaction.shareMessage não type-checkable em compiler atual — extração de helper resolve.

---

## 2026-05-10 — Wave 0.5 Partial (Explicit Imports)

**Tipo**: chore (migration)
**Módulos**: CashlyDomain, CashlyData, CashlyResource, CashlyPresentation
**Resumo**: Wave 0.5 executada (commit `3047f6f`). 23 files patched com explicit `import Foundation`/`import SwiftUI`. CashlyResourceImage refatorado para remover dependência de ImageResource (asset não bundled em SPM). `CashlyDomain.Category` qualificado em States/AdapterActor para resolver ambiguidade. Build progrediu até Reducers — bloqueia em G029 (actor vs global-isolated RyzeReducer) e G030 (MainRoute Hashable).
**Impacto**: Imports explícitos em todo Domain/Data/Resource/Presentation. xcodebuild build ainda falha, mas root cause agora é structural (Wave 2/5), não import. Build chega ~75% do path antes de cair.
**ADR**: nenhum
**PRs**: commit 3047f6f
**Aprendizados**: Reducers conformam protocolos Ryze isolados (`@MainActor` ou similar) mas declaram `actor`. Pre-existing bug invisível em Xcode IDE (compila por timing diferente de isolation check) mas explode em xcodebuild CLI. Fix exige redesign — Wave 5 (Ryze→Prism) ou Wave 2 isolada. `MainRoute` declara `==` mas falta `hash(into:)` — fix simples Wave 2. Foundation/SwiftUI implicit imports via Xcode são fonte enorme de fragilidade — Wave 0.5 endereçou parcial; resto vem via lint rule futura.

---

## 2026-05-10 — Wave 1 Partial (G012 + G013) + Wave 0.5 Inserted

**Tipo**: chore (migration)
**Módulos**: Info.plist, entitlements, migration-plan
**Resumo**: Wave 1 parcial — G012 (Info.plist NSUbiquitousContainerName → "iCloud.cashly") e G013 (split entitlements Debug=development / Release=production) commitados (`6db8b65`, `7bab811`). G008 (fatalError) e G007 (CashlyMock dep) deferidos para após Wave 0.5. G027 tentado mas revertido — cascade de imports faltantes em CashlyDomain expôs problema maior.
**Impacto**: Config corrigida para iCloud + push notifications. Build CLI ainda falha (pré-existente, agora documentado). Nova Wave 0.5 inserida no plano para auditoria de imports explícitos em CashlyDomain/Resource antes de prosseguir.
**ADR**: nenhum novo
**PRs**: commits 6db8b65, 7bab811
**Aprendizados**: Cashly nunca compilou via xcodebuild CLI — Xcode IDE faz implicit imports que CLI não replica. Bloqueia CI real e qualquer refactor downstream. Wave 0.5 nova: audit explícito de imports antes de G008. Tentativa de G008 + G027 simultânea cascateou para 60+ files; resetado para clean state (`7bab811`).

---

## 2026-05-08 — Wave 0 Partial (Rede de Segurança)

**Tipo**: chore (migration)
**Módulos**: CI, infra, CashlyKit
**Resumo**: Wave 0 entregue parcialmente (commit 22f6034). CI configurada com xcodebuild, SwiftLint/swift-format/editorconfig adicionados, pre-commit hook instalado, Ryze pinado em commit 15b047569b, SWIFT_VERSION bumped de 5 para 6 no app target. Smoke tests e snapshot tests deferidos para Wave 1.
**Impacto**: Build estável em máquina limpa (Ryze pin resolve divergência upstream), CI operacional, lint baseline estabelecido. Cobertura ainda baixa — G027 bloqueia testes automatizados via SPM CLI.
**ADR**: `.claude/memory/adr/0001-adopt-apple-dev-setup.md`
**PRs**: commit 22f6034
**Aprendizados**: Upstream Ryze foi renomeado para Prism em commit c0981be — `swift test` CLI quebra em CashlyResource por falta de explicit imports de Foundation/SwiftUI e por asset catalog não-bundled em pacote SPM. Xcode mascara o problema via implicit imports. Decisão: CI usa xcodebuild; migração Ryze→Prism mantida em Wave 5. Novos gaps descobertos: G026 (Ryze upstream rename), G027 (SPM CLI broken), G028 (xcbeautify install).

## 2026-05-08 — Onboarding + Migration Plan

**Tipo**: chore
**Módulos**: configuração / memória / migration plan
**Resumo**: `project-onboarder` rodou discovery completo (122 arquivos Swift, 11.201 linhas, 6 targets SPM) e populou `.claude/memory/`. `migration-planner` produziu gap-analysis (24 gaps: 7 críticos, 11 importantes, 6 nice-to-have) e migration-plan (9 ondas, Wave 5 fatiada em 5a/5b/5c/5d).
**Impacto**: Time tem agora um baseline imutável (`migration/baseline.md`), gap analysis priorizado (`migration/gap-analysis.md`) e plano de ondas executável (`migration/migration-plan.md`). Migração Ryze→Prism está mapeada com 8 decisões humanas pendentes que bloqueiam Wave 5.
**ADR**: `.claude/memory/adr/0001-adopt-apple-dev-setup.md`
**PRs**: —
**Aprendizados**: Arquitetura real é Redux/TCA via Ryze (não MV-@Observable como diretriz-alvo). Prism local existe com mapeamento parcial — UI exigirá reescrita por call site. Domain viola Dependency Rule (importa SwiftData/SwiftUI diretamente). Cobertura de testes ~0% fora de BudgetActorTests. Zero infra de qualidade presente (sem SwiftLint, sem CI).
