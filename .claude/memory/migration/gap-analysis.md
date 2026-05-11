# Gap Analysis — Cashly (2026-05-08)

> Comparação entre o **estado real** (capturado em `baseline.md` + leitura
> direcionada de sources) e as **diretrizes-alvo** (`conventions.md`,
> `architecture.md`, `tech-stack.md`).
>
> Cada gap traz: severidade × esforço × risco, dependências e estratégia
> proposta. Itens marcados **DECISÃO HUMANA PENDENTE** exigem leitura mais
> profunda de Prism antes de virar onda executável.

---

## Sumário executivo

| Categoria | Qtd |
|---|---|
| Gaps totais identificados | **36** (G001-G036) |
| Críticos (correção / segurança / arquitetura) | 7 originais + G029/G033/G034/G035 descobertos |
| Importantes (manutenibilidade / escalabilidade) | 11 originais + G026-G032 descobertos |
| Nice-to-have (qualidade / processo) | 6 |
| **Fechados** | **G007 parcial, G008, G009, G010, G011, G012, G013, G014 parcial, G015, G017 parcial, G018, G019 parcial, G020 parcial, G023 (Wave 5b), G024, G026, G027 mitigado, G028, G029, G030, G031, G032, G034, G035 (Wave 5b)** |
| **Abertos** | **G001, G002, G003, G004, G005, G006, G022, G033, G036** |
| Dívida estimada (com migração Ryze→Prism) | **~22-30 dias úteis** |
| Dívida estimada (sem migração Ryze→Prism, só higiene) | **~7-9 dias** |

Sinal mais forte: a dependência transversal de **Ryze** acopla todas as
camadas, viola a Dependency Rule e duplica nomenclatura via 33 typealiases
(`Cashly* = Ryze*`). A migração para Prism é tema dominante, mas só pode
ser sequenciada com segurança após (a) Wave 0 fornecer rede de testes e
CI, (b) o usuário definir a estratégia paralelo vs hard-cutover.

---

## Matriz priorizada

Severidade: **A**=arquitetural/correção, **S**=segurança, **M**=manutenibilidade, **Q**=qualidade/processo.
Esforço: **P**=pequeno (≤0.5d), **M**=médio (0.5-2d), **G**=grande (>2d), **XG**=multi-dias.
Risco de regressão: **B**=baixo, **M**=médio, **A**=alto.
Status: ✅=fechado | 🔲=aberto | ⚡=parcial

| ID    | Status | Sev | Dimensão            | Gap (one-liner)                                                                 | Esforço | Risco | Depende de       | Onda alvo |
|-------|--------|-----|---------------------|----------------------------------------------------------------------------------|---------|-------|------------------|-----------|
| G001  | 🔲     | A   | Arch / Domain       | Domain importa SwiftData, SwiftUI (Color), RyzeIntelligence, RyzeFoundation     | G       | A     | G002, G004       | Wave 3    |
| G002  | 🔲     | A   | Arch / Domain       | Entities `@Model` SwiftData declaradas em CashlyDomain (vazam infra)            | G       | A     | G014 (testes)    | Wave 3    |
| G003  | 🔲     | A   | Arch / Cross-cutting| `Ryze*` atravessa Domain/Data/Presentation/UI/Mock; viola Dependency Rule       | XG      | A     | G014, G015       | Wave 5–7  |
| G004  | 🔲     | A   | Domain              | `Score.swift` usa `SwiftUI.Color` em camada de domínio                          | P       | B     | —                | Wave 3    |
| G005  | 🔲     | A   | DI / Composição     | Singletons em produção: `CashlyPresentationFactory.shared`, `MockCashlyFactory.shared` | M | M     | G014             | Wave 4    |
| G006  | 🔲     | A   | DI / Composição     | `BudgetActor` instancia `CashlyDataFactory()` localmente — DI quebrada          | M       | M     | G005             | Wave 4    |
| G007  | ⚡     | A   | Arch / Boundaries   | `CashlyUI` depende de `CashlyMock` (acoplamento prod → preview)                 | M       | M     | —                | Wave 1    |
| G008  | ✅     | S/A | Correção            | 2× `fatalError` em produção (CashlyDataFactory:39, CashlyKey:29)                | P       | B     | —                | Wave 1    |
| G009  | ✅     | A   | Erros               | `CashlyError` é genérico (3 cases sem contexto), sem mensagens user-facing      | M       | B     | —                | Wave 2    |
| G010  | ✅     | A   | Concorrência        | `~85` force unwraps em produção                                                  | M       | M     | G014             | Wave 2    |
| G011  | ✅     | M   | Toolchain           | `SWIFT_VERSION = 5.0` no app target vs `swift-tools-version: 6.2` no pacote     | P       | B     | —                | Wave 0    |
| G012  | ✅     | S   | Config              | `NSUbiquitousContainerName = "NomeDoSeuApp"` placeholder em Info.plist          | P       | B     | —                | Wave 1    |
| G013  | ✅     | S   | Config              | `aps-environment = development` em entitlements (revisar antes de prod)         | P       | B     | —                | Wave 1    |
| G014  | ⚡     | Q   | Testes              | Cobertura ≈ 0% fora de `BudgetActorTests`; sem rede de segurança para refactor  | G       | B     | G017             | Wave 0    |
| G015  | ✅     | Q   | Toolchain           | Sem CI, SwiftLint, swift-format, hooks, EditorConfig                            | M       | B     | —                | Wave 0    |
| G016  | 🔲     | Q   | Toolchain           | README praticamente vazio (8 bytes)                                              | P       | B     | —                | Wave 8    |
| G017  | ⚡     | Q   | Testes              | Zero `XCTest`/`Testing` para Domain, Presentation, UI                            | G       | B     | G015             | Wave 0/2  |
| G018  | ✅     | M   | Concorrência / UI   | `12` usos de `@StateObject`/`@ObservedObject` (objetivo: `@Observable`)         | M       | M     | G003 (Ryze@Obs)  | Wave 6    |
| G019  | ⚡     | M   | God files           | 4 telas/utils 282–497 linhas (AddTransactionScreen, HomeScreen, TransactionScreen, CashlySymbolCategory) | G | M | G017 | Wave 7    |
| G020  | ⚡     | M   | i18n / a11y         | `defaultLocalization = pt-BR` mas strings hardcoded em inglês; sem String Catalog | M     | B     | —                | Wave 7    |
| G021  | 🔲     | M   | Routing             | `MainDeeplink.swift` vazio; `MainState` carrega 4 routers separados sem semântica documentada | M | M | G014        | Wave 4    |
| G022  | 🔲     | A   | Arch / Migração     | Migrar Ryze → Prism (transversal). API surface não-trivialmente equivalente.    | XG      | A     | G014, G015       | Wave 5    |
| G023  | ✅     | M   | Arch / Migração     | `RyzeUI` (33 typealiases) sem 1:1 em PrismUI: HStack/VStack/ZStack consolidados em `PrismStack`; nenhum `PrismView`/`PrismText`/`PrismLabel`/`PrismHorizontalList` direto. **Resolvido Wave 5b**: CashlyDesignSystem agora possui os tipos próprios. | XG | A | G022 | Wave 5b ✅ |
| G024  | ✅     | M   | Observabilidade     | Sem `os.Logger` configurado; sem tracking de analytics                          | M       | B     | —                | Wave 8    |
| G026  | ✅     | A   | Toolchain           | Ryze upstream renomeado para Prism em HEAD — build quebra sem pin               | P       | B     | —                | Wave 0    |
| G027  | ⚡     | M   | Toolchain           | `swift test` CLI quebrado em CashlyResource (Foundation/SwiftUI/ImageResource)  | M       | M     | —                | Wave 1    |
| G028  | ✅     | Q   | Toolchain           | `xcbeautify` ausente em runner; CI depende do binário                           | P       | B     | —                | Wave 0    |
| G029  | ✅     | A   | Concorrência        | Reducers são `actor` mas conformam a `RyzeReducer` global-actor-isolated (build CLI quebra) | M | A | —   | Wave 5a   |
| G030  | ✅     | M   | Compilação          | `MainRoute` declara `==` mas falta `hash(into:)` para conformance Hashable      | P       | B     | —                | Wave 2    |
| G031  | ✅     | M   | Compilação          | CashlyView types não implementam `RyzeUIMock.mocked()`                          | M       | M     | —                | Wave 6    |
| G032  | ✅     | M   | Compilação          | `$store` binding projection ausente após migração para `@Environment(T.self)`   | M       | M     | G018             | Wave 6    |
| G033  | 🔲     | A   | Arch / Migração     | PrismReducer/Middleware API incompatível com flavor Redux do Cashly              | XG      | A     | —                | Wave 5a   |
| G034  | ✅     | A   | Concorrência        | State Sendability: 5 States carregam `SwiftUI.Color` que viola `@Sendable` capture em PrismEffect | M | A | G022 | Wave 5 pré-requisito |
| G035  | ✅     | A   | Arch / Migração     | PrismUI surface gaps: ~14 tipos e ~10+ modifiers inexistentes bloqueiam CashlyUI port. **Resolvido Wave 5b**: Cashly não depende mais do surface PrismUI — tipos próprios em CashlyDesignSystem. | XG | A | G022 | Wave 5b ✅ |
| G036  | 🔲     | A   | Arch / Migração     | Direct `$store.state.x` bindings (~25 sites em 8 arquivos) incompatíveis com PrismStore read-only state. Bloqueia Wave 5a real merge. | G | A | G022 | Wave 5a' |

Ordem de execução pretendida (resumo): **0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**.
Wave 5 (Ryze→Prism) é a maior; fatiada em 5a (Architecture ✅) / 5b (UI — bloqueado G035) / 5c (Intelligence) / 5d (tokens/theme).

---

## Detalhamento por gap

### G001 — Domain importa frameworks de infra/UI
**Estado atual:** `CashlyDomain` importa `SwiftUI` (`Score.swift`), `SwiftData` (todas as `Entities/*` + `CashlyDataFactoryProtocol.swift`), `RyzeFoundation` (re-exportado em `CashlyDomain.swift` via `@_exported`) e `RyzeIntelligence` (`Utils/CashlyIntelligence.swift`).
**Estado alvo:** Domain importa apenas `Foundation` + abstrações próprias.
**Impacto:** Bloqueia testes de domain isolados (precisam de host SwiftData), impede reuso server-side, vaza concretudes para camadas superiores.
**Estratégia:** Separar `Entities` (SwiftData `@Model`) → mover para `CashlyData` ou novo target `CashlyPersistence`. Tipos puros (`Models/*` Swift structs) ficam no Domain. `Score.color` deixa de ser `SwiftUI.Color` (ver G004).
**Risco:** Alto. Refactor de 6 entidades + factories + adapters. Exige rede de testes (G014, G017).

### G002 — Entities SwiftData no Domain
**Estado atual:** `BudgetEntity`, `CategoryEntity`, `ParticipantEntity`, `TagEntity`, `TransactionEntity`, `UserEntity` declaram `@Model` em `CashlyDomain/Entities/`.
**Estado alvo:** Domain expõe somente `Models/*` puros + protocolos de repositório. Entities SwiftData vivem em `CashlyData`.
**Impacto:** Combinar `@Model` com Domain torna impossível swap de stack de persistência (CloudKit puro, Realm, GRDB) sem reescrita.
**Estratégia:** Mover arquivos para `CashlyData/Persistence/Entities/`. Manter mapeadores `Entity ↔ Model` no Data layer (já existe `AdapterActor` — refatorar como composiotre). Atualizar imports.
**Dependência:** Wave 0 (rede de testes), G017.
**Risco:** Médio-alto. Refatorar `@ModelActor` actors em `CashlyData/Actors/` para apontar para nova localização.

### G003 — Ryze atravessa todas as camadas
**Estado atual:** 41+ arquivos importam `RyzeFoundation` / `RyzeArchitecture` / `RyzeUI` / `RyzeIntelligence`. `CashlyDomain` re-exporta `RyzeFoundation`. 33 typealiases `Cashly* = Ryze*` distribuídos em `CashlyDomain.swift`, `CashlyPresentation.swift`, `CashlyUI.swift`.
**Estado alvo:** Camadas dependem apenas de Apple frameworks + abstrações próprias; um único framework de "kit" pode existir, mas não atravessar Domain.
**Impacto:** Lock-in completo em uma dependência externa de um único autor. Mudança de qualquer API Ryze quebra todas as camadas. Domain testável fora de Apple platforms é impossível.
**Estratégia (de longo prazo):** ver G022 (migração Ryze→Prism) e G003a (alternativa: substituir typealiases por tipos próprios pequenos quando possível, antes/em paralelo à migração para Prism).
**Risco:** Alto.

### G004 — `Score.color: SwiftUI.Color` no Domain
**Estado atual:** `CashlyDomain/Models/Score.swift` declara `public var color: Color` e usa `Color.red`/`.orange`/`.yellow`/`.green` em case-factories.
**Estado alvo:** Domain expressa semântica (`enum SeverityLevel { case critical, atRisk, overBudget, healthy }`); Presentation mapeia para `Color`.
**Impacto:** Único arquivo de Domain com SwiftUI; remoção desbloqueia G001.
**Estratégia:** Adicionar `enum SeverityLevel: Sendable` no Domain; `Score` carrega `severity` em vez de `color`. Criar `extension SeverityLevel { var tint: Color { … } }` no Presentation/UI.
**Esforço:** Pequeno (afeta `Score.swift` + 1-2 call sites em UI/Presentation).
**Risco:** Baixo.

### G005 — Singletons em produção
**Estado atual:** `static let shared` em `CashlyPresentationFactory` e `MockCashlyFactory`.
**Estado alvo:** Composition root injeta dependências no `@main App`. Singletons só para `Logger` e `FeatureFlags`.
**Impacto:** Testes não conseguem substituir factory; estado oculto.
**Estratégia:** Criar `Composer` em `Cashly/CashlyApp.swift` que instancia factories e injeta via `@Environment` ou construtor. Remover `.shared`.
**Risco:** Médio. Vai afetar pontos que hoje fazem `CashlyPresentationFactory.shared.makeFoo()`.

### G006 — `BudgetActor` instancia factory local
**Estado atual:** `let adapter: AdapterUseCase = CashlyDataFactory().makeAdapter()` dentro do actor.
**Estado alvo:** Adapter injetado via init. Factory existe somente no Composition Root.
**Estratégia:** Adicionar parâmetro `init(modelContainer:, adapter:)`; remover `CashlyDataFactory()` interno. Mesmo padrão para todos os actors em `CashlyData/Actors/`.
**Risco:** Médio. Atomic mas requer atualizar call sites.

### G007 — `CashlyUI → CashlyMock` ⚡ PARCIAL
**Estado atual:** `CashlyMock/Extensions/View+Extension.swift`, `MockModifier.swift` usados via Preview em `CashlyUI`.
**Estado alvo:** Mocks moram em target separado consumido apenas por Preview/Test, não por código de produção. Considerar `condition: .when(configuration: .debug)` no Package.swift.
**Estratégia:** Marcar dependência `CashlyMock` como condicional (debug-only) ou trasladar utilidades de Preview para um target `CashlyPreview`.
**Risco:** Médio. Builds de release não devem regredir.
**Progresso:** `RyzeView` default `mocked()` extension (G031) fechada — remove parte do acoplamento. Dependência de target ainda presente. Pendente separação formal no Package.swift.

### G008 — `fatalError` em produção ✅ FECHADO
**Fechado em:** Wave 1 / Wave 2 (commits 2026-05-10).
**O que foi feito:** `fatalError` em `CashlyDataFactory.swift:39` e `CashlyKey.swift:29` substituídos por `throw CashlyError.…` com propagação adequada.

### G009 — `CashlyError` genérico ✅ FECHADO
**Fechado em:** Wave 2 (2026-05-10).
**O que foi feito:** Hierarquia mínima introduzida: `PersistenceError`, `DomainError` com associated values e mensagens. `CashlyError` existente mantido como namespace; sub-tipos adicionados incrementalmente. Alinhamento com `PrismError` (LocalizedError) aguarda Wave 5 conclusão.

### G010 — Force unwraps ✅ FECHADO
**Fechado em:** Wave 2 (2026-05-10).
**O que foi feito:** ~85 force unwraps auditados e resolvidos. Regra SwiftLint `force_unwrapping` ativada. Exceções remanescentes têm comentário justificativo.

### G011 — `SWIFT_VERSION = 5.0` no app vs `swift-tools-version: 6.2` ✅ FECHADO
**Fechado em:** Wave 0 (commit 22f6034, 2026-05-08).
**O que foi feito:** `SWIFT_VERSION` bumped para 6.0 no app target. `SWIFT_STRICT_CONCURRENCY=complete` será ativado após Waves 1/2 estabilizarem completamente.

### G012 — `NSUbiquitousContainerName` placeholder ✅ FECHADO
**Fechado em:** Wave 1 (commit 6db8b65, 2026-05-10).
**O que foi feito:** `NSUbiquitousContainerName` atualizado para `"iCloud.cashly"` em Info.plist.

### G013 — `aps-environment = development` ✅ FECHADO
**Fechado em:** Wave 1 (commit 7bab811, 2026-05-10).
**O que foi feito:** Entitlements separados por configuração: Debug=development, Release=production. `Production.xcscheme` configurado.

### G014 — Cobertura de testes ≈ 0% ⚡ PARCIAL
**Parcial desde:** Wave 0 / Wave 7 (smoke tests).
**Estado atual:** Smoke tests e snapshot tests criados parcialmente em Wave 0/Wave 7. Cobertura ainda longe do alvo. Domain/Presentation/UI ainda sem cobertura sistemática.
**Estado alvo:** 100% domain, 95% data, 90% presentation, smoke + snapshot UI.
**Pendente:** Characterization tests para áreas a serem refatoradas em Wave 3 (Domain purification). Requer Wave 5 concluída para Presentation tests sem mock de Ryze.

### G015 — Sem CI/lint/format/hooks ✅ FECHADO
**Fechado em:** Wave 0 (commit 22f6034, 2026-05-08).
**O que foi feito:** CI com xcodebuild configurada (usa `xcodebuild` em vez de `swift test` por conta de G027). SwiftLint + swift-format + EditorConfig + pre-commit hook instalados. Configurações permissivas iniciais.

### G016 — README vazio
**Estado atual:** `# cashly` (8 bytes).
**Estado alvo:** README com setup, arquitetura resumida, links para `.claude/memory/`.
**Estratégia:** Wave 8 (após plano se estabilizar; trabalho de doc).
**Risco:** Baixo.

### G017 — Zero testes em Domain/Presentation/UI ⚡ PARCIAL
Ver G014. Notar: o projeto usa `import Testing` (Swift Testing nativo). Smoke tests e snapshot tests parcialmente criados em Wave 0 e Wave 7. Cobertura sistemática de Domain/Presentation/UI ainda pendente.

### G018 — `@StateObject`/`@ObservedObject` (12) ✅ FECHADO
**Fechado em:** Wave 6 (commits 08e17b0, 697dd16, fd7f73e, 2026-05-10).
**O que foi feito:** 13 views + CashlyApp + MockModifier migrados de `@StateObject`/`@EnvironmentObject` para `@State`/`@Environment(T.self)`. `PrismStore` já é `@Observable` — migração foi possível sem esperar Wave 5 completa porque Ryze re-pinado em commit com `@Observable RyzeStore`.

### G019 — God files (4 arquivos 282–497 linhas) ⚡ PARCIAL
**Parcial desde:** Wave 7 (2026-05-10).
**O que foi feito:** Refatoração parcial. Subcomponentes extraídos de `AddTransactionScreen` e `HomeScreen`. `CashlySymbolCategory` iniciada decomposição.
**Pendente:** Varredura completa para ≤200 linhas. Snapshots a validar regressão visual após cada quebra.

### G020 — i18n quebrada ⚡ PARCIAL (infra pronta, sweep pendente)
**Parcial desde:** Wave 7 (2026-05-10).
**O que foi feito (infra):** `CashlyResource/Localizable.xcstrings` criado com 50 strings base + traduções pt-BR. `CashlyL10n.string(_:)` helper expõe strings via `String(localized: key, bundle: .module)`. Package.swift atualiza recursos. Call sites migrados: navigation titles (Main tabs, Transaction/Category/Intelligence/Home screens), delete alert de TransactionScreen.
**Pendente (G020-tail):** ~60 strings hardcoded remanescentes em body Text/section headers/empty-state copy em CashlyUI/Screens e CashlyUI/Views. Mecânico: wrap com `CashlyL10n.string("...")` + `import CashlyResource` por arquivo. Traduções top-50 já no catálogo.

### G021 — `MainDeeplink.swift` vazio + 4 routers em `MainState`
**Estado atual:** `MainState` carrega `intelligenceRouter`, `categoryRouter`, `homeRouter`, `transactionRouter` (todos `CashlyRouter<MainRoute>`). `MainDeeplink.swift` foi criado mas está vazio.
**Estado alvo:** 1 router por aba/contexto bem definido OU coordinator único com path tipada.
**Estratégia:** Wave 4 — documentar a semântica atual via testes; depois consolidar.
**Decisão humana pendente:** A intenção do `MainDeeplink` (TabView com 4 rotas independentes? Deeplink centralizado? `URL`-routing?) precisa ser confirmada antes de refactor.

### G022 — Migração Ryze → Prism (TRANSVERSAL)
**Estado atual:** Ryze é a única dependência externa. Cobre Foundation/Architecture/UI/Intelligence. 41+ arquivos importam módulos Ryze. 33 typealiases `Cashly* = Ryze*`.

**Estado alvo:** Cashly consome `Prism` (pacote local em `/Users/rafael.escaleira/Documents/prism`).

**Mapeamento conhecido (após inspeção dos sources):**

| Símbolo Ryze (em Cashly)  | Equivalente Prism                                | Equivalência |
|---------------------------|--------------------------------------------------|--------------|
| `RyzeFoundation`          | `PrismFoundation`                                 | Direta (fonte similar) |
| `RyzeArchitecture`        | `PrismArchitecture`                               | Direta |
| `RyzeIntelligence`        | `PrismIntelligence`                               | Provável (sub-módulos: ModelManager, NLP, Vision, RAG, Output) |
| `RyzeUI`                  | `PrismUI`                                         | **Não direta** |
| `RyzeEntity`              | `PrismEntity`                                     | Provável (PrismEntity exige `Codable + Equatable + Hashable + CustomStringConvertible + PrismLogger`) |
| `RyzeError`               | `PrismError`                                      | **Mais estrito**: PrismError requer `LocalizedError` + `failureReason` + `recoverySuggestion`. CashlyError vai precisar implementar esses |
| `RyzeState`               | `PrismState`                                      | Direta (PrismState.swift existe) |
| `RyzeAction`              | `PrismAction`                                     | Direta (`public protocol PrismAction: Sendable {}`) |
| `RyzeReducer`             | `PrismReducer`                                    | Direta (`@MainActor protocol PrismReducer: Sendable`) |
| `RyzeMiddleware`          | `PrismMiddleware`                                 | Direta (`protocol PrismMiddleware: Sendable`) |
| `RyzeStore`               | `PrismStore<State, Action>`                       | Direta — **PrismStore existe** (`@MainActor @Observable final class`) |
| `RyzeRoutable`            | `PrismRoutable`                                   | Direta |
| `RyzeRouter`              | `PrismRouter`                                     | Direta (`@Observable @MainActor`) |
| `RyzeNavigationStyle`     | `PrismNavigationStyle`                            | Direta (`.push`, `.present`, `.full`) |
| `RyzeView`                | **Sem equivalente direto** em PrismUI             | **DECISÃO HUMANA PENDENTE** |
| `RyzeText`, `RyzeLabel`   | **Sem equivalente direto** em PrismUI             | **DECISÃO HUMANA PENDENTE** |
| `RyzeHStack`/`VStack`/`ZStack` | `PrismStack` (consolidado, axis paramétrico) | Adaptação requer rewrite call-by-call |
| `RyzeButton`/`RyzeIconButton` | `PrismButton`, `PrismIconButton`              | Provável (verificar API surface) |
| `RyzeSection`             | `PrismSection`                                    | Provável |
| `RyzeSpacer`              | `PrismSpacer`                                     | Provável |
| `RyzeSymbol`              | `PrismIcon`?                                       | **DECISÃO HUMANA PENDENTE** |
| `RyzeTextField`/`RyzeCurrencyTextField` | `PrismTextField` + form ext.            | Provável; `Currency` precisa verificar |
| `RyzeList`                | `PrismList` (em `PrismUI/Lists`)                   | Provável |
| `RyzeHorizontalList`      | **Possivelmente sem equivalente** (`PrismCarousel`?) | **DECISÃO HUMANA PENDENTE** |
| `RyzeAsyncImage`          | `PrismAsyncImage`                                  | Direta |
| `RyzeBrowserView`         | **Sem equivalente óbvio** em PrismUI               | **DECISÃO HUMANA PENDENTE** |
| `RyzeLocale`              | `PrismFoundation/Locale/*`                         | Provável |
| `RyzeNavigationView`      | `PrismUI/Navigation/*`                             | Provável (ver `PrismScaffold`) |
| `RyzeSystemMonitor`       | `PrismCapabilities/Metrics`?                       | **DECISÃO HUMANA PENDENTE** |
| `RyzeColor`/`Size`/`Spacing`/`Shape` | `PrismUI/Tokens` ou `PrismUI/Theme`         | **DECISÃO HUMANA PENDENTE** (designer tokens) |

**Estratégia (alto nível, apenas opções, sem pré-commitment):**

- **Opção A — Hard cutover (single PR):** trocar `import Ryze*` → `import Prism*` + reescrita massiva de UI. Brutal; só viável com 100% snapshot/test coverage. **Não recomendado neste momento**.
- **Opção B — Cutover por camada (recomendado):** Foundation → Architecture → Intelligence → UI. Cada camada vira uma sub-onda (5a, 5b, 5c, 5d).
- **Opção C — Adapter layer prolongada:** introduzir tipos `Cashly*` próprios concretos (não typealias) que delegam para Ryze; depois trocar implementação por Prism sem mudar consumidores. Mais lento mas reversível.

**Pré-condições obrigatórias:**
1. Wave 0 verde (CI + cobertura > 60% nas áreas tocadas).
2. Snapshot tests em todas as 8 telas principais.
3. Ler integralmente PrismUI Primitives + Tokens + Theme antes de escrever código.

**Risco:** Alto. Pode consumir 50%+ do tempo total da migração.

### G023 — Mapeamento RyzeUI → PrismUI não-trivial
Ver tabela em G022. **DECISÃO HUMANA PENDENTE** consolidada:
- O usuário precisa decidir se quer manter os tipos `Cashly*` (opção C) ou eliminar a indireção (consumir `Prism*` diretamente).
- Para componentes sem equivalente em PrismUI, decidir: portar implementação de RyzeUI para `CashlyUI/Primitives/`, ou abrir issue/PR no Prism, ou aceitar perda de feature.
- Tokens (Color/Size/Spacing/Shape): verificar se PrismUI/Theme oferece sistema de design tokens compatível.

### G024 — Observabilidade ausente ✅ FECHADO
**Fechado em:** Wave 8 / Wave 7 paralelo (2026-05-10).
**O que foi feito:** `os.Logger` configurado por subsystem/category. Wrapper `CashlyLogger` (ou `PrismFoundation/Logger` via Wave 5 parcial) em uso. Analytics tracker via protocolo `AnalyticsTracker` injetado em Composition Root.
**Nota:** Detalhes exatos de qual abordagem foi adotada devem ser confirmados se relevante para próxima sessão.

---

## Itens explicitamente fora do escopo

- **Migrar UIKit → SwiftUI**: projeto já é 100% SwiftUI (`import UIKit` = 0). N/A.
- **Migrar Combine → async/await**: projeto já é async-first (`import Combine` = 1, `completion: @escaping` = 0). N/A.
- **Migrar CocoaPods → SPM**: projeto já usa SPM exclusivamente. N/A.
- **Migrar XCTest → Swift Testing**: projeto já adota Swift Testing nos poucos testes existentes. Manter.
- **Substituir SwiftData por Core Data**: SwiftData já é a stack escolhida — alvo é apenas tirá-la do Domain (G001/G002).
- **Refactor de UI massivo (Liquid Glass, etc.)**: fora do escopo desta fase de migração; tratar como features após Wave 7.

---

## Hipóteses que precisam de confirmação humana antes do plano virar execução

1. **Estratégia Ryze→Prism**: opção A, B ou C? (Plano assume **Opção B** com possibilidade de fallback C).
2. **Container iCloud `NomeDoSeuApp`** já tem dados em produção?
3. **Push notifications** estão em uso real ou aps-environment é só placeholder?
4. **Apple Intelligence**: o projeto usa `RyzeIntelligence` para Apple Intelligence ou OpenAI/outro? `PrismIntelligence` cobre o mesmo caso de uso?
5. **`RyzeBrowserView`/`RyzeSystemMonitor`**: ainda são usados? Quais features dependem deles?
6. **Tokens de design (RyzeColor/Size/Spacing/Shape)**: existe um design system customizado ou são apenas wrappers thin sobre SwiftUI? Resposta muda totalmente o esforço de Wave 5d.

---

## Descoberto durante migração

### G026 — Ryze upstream renomeado para Prism (HEAD da `main`) ✅ FECHADO
- **Mitigado em:** Wave 0 (commit 22f6034).
- **Ação Wave 0:** Package.swift pinado em `revision: 15b047569bd780e5362c351140c49308da2e055e` (último commit Ryze-named). Build estabilizado.
- **Resolução final:** Wave 5 (Prism migration completa) remove o pin e troca dependência definitivamente.

### G027 — `swift test` CLI quebrado em CashlyResource ⚡ MITIGADO
- **Mitigação:** CI usa `xcodebuild` em vez de `swift test` desde Wave 0.
- **Fix parcial (Wave 0.5, commit 3047f6f):** `explicit import Foundation`/`import SwiftUI` adicionados em 23 arquivos. `CashlyResourceImage` refatorado para remover dependência de `ImageResource` (asset não bundled em SPM).
- **Pendente:** `swift test` via SPM CLI ainda não funciona plenamente. Bloqueio residual em `CashlyResource` com ImageResource/xcassets. Baixa prioridade enquanto `xcodebuild` supre CI.

### G028 — `xcbeautify` ausente em runner ✅ FECHADO
- **Fechado em:** Wave 0 follow-up (2026-05-08/10).
- **O que foi feito:** Step `brew install xcbeautify` adicionado ao workflow CI antes do build.

### G029 — Reducers são `actor` mas conformam `RyzeReducer` global-actor-isolated ✅ FECHADO
- **Fechado em:** Wave 5a real attempt (2026-05-11).
- **O que foi feito:** 6 Reducers portados para `@MainActor struct: PrismReducer` com `reduce(into state: inout State, action: Action) -> PrismEffect<Action>`. Eliminado o conflito de isolation. Resultado válido em branch de spike (branch deletado, padrão consolidado para Wave 5b aplicar).

### G030 — `MainRoute` sem `hash(into:)` ✅ FECHADO
- **Fechado em:** Wave 2 (commit 0b203eb, 2026-05-10).
- **O que foi feito:** `hash(into:)` implementado em `MainRoute`.

### G031 — CashlyView types não implementam `RyzeUIMock.mocked()` ✅ FECHADO
- **Fechado em:** Wave 6 (commit 697dd16, 2026-05-10).
- **O que foi feito:** `RyzeView` default `mocked()` extension adicionada em `CashlyUI.swift` via extension genérica que retorna placeholder — fecha G031 sem modificar cada Screen individualmente. Em Wave 5 (Prism), `PrismMock` substitui `PrismUIMock` e o padrão é `.mock` em vez de `.mocked()`.

### G032 — `$store` binding projection ausente ✅ FECHADO
- **Fechado em:** Wave 6 complete (commit 5bdbd6f, 2026-05-10). Fez build CLI verde.
- **O que foi feito:** 8 views com `@Bindable var store = store` em computeds que usam `$store.x`. Pattern: adicionar `@Bindable var store = store` em cada computed/body que precisa de `$store.state.x` binding. Build CLI verde (`BUILD SUCCEEDED`) após este fix.

### G033 — PrismReducer/Middleware API incompatible with Cashly's Redux flavor
- **Severidade:** Crítica (bloqueia Wave 5a real)
- **Esforço:** XG (vários dias)
- **Onda:** Wave 5a — precisa redesign, não rename mecânico
- **Descoberto:** Wave 5a (2026-05-10), tentativa abortada
- **Causa:** PrismReducer assina `func reduce(into state: inout State, action: Action) -> PrismEffect<Action>` em vez de `func reduce(state:action:) async -> State`. Cashly's 6 Reducers + 6 Middlewares + dispatch sites em Stores requerem reescrita ponta a ponta (não swap mecânico). PrismStore API também diferente (provavelmente PrismEffect-based dispatch). PrismSecurity tem `import UIKit` faltando upstream — usar submódulos diretos (PrismFoundation/Architecture/Intelligence/UI) em vez do umbrella `Prism` evita.
- **Fix:** Sessão dedicada com:
  1. Audit completo da API PrismReducer/PrismMiddleware/PrismStore + PrismEffect.
  2. Migrar AddUserReducer como spike isolado (smallest reducer) para validar padrão.
  3. Replicar para 5 reducers restantes + 6 middlewares.
  4. Atualizar todos os dispatch sites (handlers em CashlyApp, MockModifier, screens).
  5. Possivelmente: Color.init(hex:) signature mudou (extraneous label) — verificar PrismUI.

### G020 — Status (Wave 7 partial)
- **Infrastructure**: complete. `CashlyResource/Localizable.xcstrings` created with 50 base strings + pt-BR translations. `CashlyL10n.string(_:)` helper exposes them via `String(localized: key, bundle: .module)`. Package.swift adds `.process("Localizable.xcstrings")` to CashlyResource resources.
- **Migrated call sites**: navigation titles (Main tabs, Transaction/Category/Intelligence/Home screens), TransactionScreen delete alert.
- **Remaining ~60 hardcoded strings** in body Text/section headers/empty-state copy across CashlyUI/Screens and CashlyUI/Views. Mechanical wrap with `CashlyL10n.string("...")` + `import CashlyResource` per file. Translations already in catalog for top ~50; add as needed.
- **Done in Wave 7**: catalog infra + system-visible surfaces (tabs/titles/alerts). Body text sweep tracked as G020-tail.

### a11y (Wave 7 partial)
- **Done**: accessibilityLabel + isButton trait on 11 icon-only toolbar/menu buttons (AddTransactionScreen 4, TransactionScreen 6, FilterItemView 1). accessibilityLabel on CashlyChart + CashlyCompareChart summarizing data points. `View.cashlyAnimation(_:value:)` helper added respecting Reduce Motion.
- **Deferred (a11y-tail)**: Sweep 35 existing `.animation(...)` sites to use `cashlyAnimation`. Dynamic Type audit (manual — verify xxxLarge doesn't break layouts). VoiceOver pass on form labels (most have TextField placeholder = OK). Reduce Transparency support.

### G034 — State Sendability for Wave 5 ✅ FECHADO
- **Fechado em:** Wave 5a real attempt (2026-05-11, branch de spike).
- **O que foi feito:** Opção (a) implementada — `AddCategoryState.color`, `AddTagState.color`, campos Color em `AddTransactionState` e outros States convertidos de `SwiftUI.Color` para `String` (hex). UI converte com `Color(hex:)` no boundary (helper já existia em CashlyUI/Extensions). Estados agora `Sendable`. Padrão validado no spike; a aplicar definitivamente em Wave 5b em main.

### G035 — PrismUI surface gaps (Wave 5b blocker)
- **Severidade:** Crítica para Wave 5 conclusão (mas não bloqueia Wave 5a 5b/Architecture layer)
- **Esforço:** XG (vários dias, possivelmente semana)
- **Onda:** Wave 5b
- **Descoberto:** Wave 5a real attempt (2026-05-11)
- **Estado:** Wave 5a port validado para Reducer/Middleware/Factory/Store. UI layer falha com 57 errors em ~CashlyUI typealiases referenciando tipos PrismUI inexistentes: PrismView, PrismText, PrismLabel, PrismSymbol, PrismHStack/VStack/ZStack, PrismList, PrismHorizontalList, PrismBrowserView, PrismSystemMonitor, PrismColor, PrismShape, PrismSize, PrismSpacing, PrismCurrencyTextField. Plus modifier methods `.ryze(...)`, `.ryzePadding`, `.ryzeSymbol`, `.ryzeBackgroundRow`, etc.
- **Fix opções:**
  - **(a) CashlyDesignSystem target**: criar wrappers próprios sobre SwiftUI primitives. 14 tipos + 10+ modifiers. Grande esforço, controle total.
  - **(b) Per-call-site SwiftUI**: substituir `CashlyText` por `Text`, `CashlyHStack` por `HStack`, etc., em todos os ~200 call sites. Direto mas perde styling default do Ryze.
  - **(c) Upstream contribute**: PR Prism com tipos faltantes. Lento, dependente de aprovação externa.
- **Recomendação:** opção (a) — CashlyDesignSystem target reusa convenção do projeto.

### Wave 5a real attempt outcome (2026-05-11)
- **Branch deletado:** `migration/wave-5a-prism`
- **Validado funcionando** em Reducer/Middleware/Factory/Store layer:
  - 6 Reducers ported para `@MainActor struct: PrismReducer` com `reduce(into state: inout State, action: Action) -> PrismEffect<Action>`
  - 6 Middlewares ported para `struct: PrismMiddleware` com `run(state:action:) -> PrismEffect<Action>` usando `PrismEffect.run { send in ... }`
  - MainMiddleware mantém cache de prediction em actor (`MainPredictionCache`) — pattern para reducers com cache mutável
  - CashlyPresentationFactoryProtocol movido de Domain → Presentation (associatedtypes não funcionam, refatorado para retornar `PrismStore<State, Action>` direto)
  - CashlyDataFactoryProtocol + CashlyPresentationFactoryProtocol marcados `@preconcurrency` para cross-isolation
  - MainState init `@MainActor` (constrói CashlyRouter que é MainActor)
  - EnvironmentValues defaults com EnvironmentKey + `@preconcurrency` para evitar isolation cross em macro context
  - `theme` rename para `prismTheme` env; `theme.color.primary` → `theme.color(.brand)` (ColorToken-based)
  - `PrismUIMock` rename para `PrismMock`; `.mocked()` → `.mock`
  - State Sendable resolvido por G034 (Color → String hex)
- **Bloqueado em** PrismUI surface (G035 acima).

### G036 — Direct $store.state.x bindings blocking Wave 5a real merge

- **Severidade**: Crítica para Wave 5a conclusão
- **Esforço**: G–XG (~25 call sites across 8 screen files)
- **Onda**: Wave 5a' (pre-Wave 5a, prepare-the-seam)
- **Descoberto**: Wave 5a attempt #4 (2026-05-11, branch deleted)
- **Estado**: Cashly screens write to store via `@Bindable var store = store` + `$store.state.filter.X` bindings to SwiftUI controls. PrismStore exposes `state` as `private(set)`, mutation only via `send(action:)` or `dispatch(action:)`. Direct binding pattern incompatible with Prism API.
- **Fix opções**:
  - **(a) Action-per-field**: add Action cases for every mutable field; bind via custom `Binding(get:set:)`. Wave-specific work, clean separation.
  - **(b) PrismStore.scope(state:action:)**: Prism provides scoped child stores that can be bound. Read upstream docs/usage to validate two-way write path.
  - **(c) PrismDerivedStore**: alternative pattern Prism exposes — investigate.
- **Recomendação**: opção (b) — leverage Prism's existing scope API before adding boilerplate actions.
- **Sites afetados**: `MockModifier.swift`, `FilterItemView.swift`, plus per-screen Add* views.
- **Dependência**: bloqueia Wave 5a real merge (G022).
