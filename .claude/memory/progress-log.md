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
