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
