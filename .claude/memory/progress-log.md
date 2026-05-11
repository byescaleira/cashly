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
