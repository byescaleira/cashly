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
| Gaps totais identificados | **24** |
| Críticos (correção / segurança / arquitetura) | 7 |
| Importantes (manutenibilidade / escalabilidade) | 11 |
| Nice-to-have (qualidade / processo) | 6 |
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

| ID    | Sev | Dimensão            | Gap (one-liner)                                                                 | Esforço | Risco | Depende de       | Onda alvo |
|-------|-----|---------------------|----------------------------------------------------------------------------------|---------|-------|------------------|-----------|
| G001  | A   | Arch / Domain       | Domain importa SwiftData, SwiftUI (Color), RyzeIntelligence, RyzeFoundation     | G       | A     | G002, G004       | Wave 3    |
| G002  | A   | Arch / Domain       | Entities `@Model` SwiftData declaradas em CashlyDomain (vazam infra)            | G       | A     | G014 (testes)    | Wave 3    |
| G003  | A   | Arch / Cross-cutting| `Ryze*` atravessa Domain/Data/Presentation/UI/Mock; viola Dependency Rule       | XG      | A     | G014, G015       | Wave 5–7  |
| G004  | A   | Domain              | `Score.swift` usa `SwiftUI.Color` em camada de domínio                          | P       | B     | —                | Wave 3    |
| G005  | A   | DI / Composição     | Singletons em produção: `CashlyPresentationFactory.shared`, `MockCashlyFactory.shared` | M | M     | G014             | Wave 4    |
| G006  | A   | DI / Composição     | `BudgetActor` instancia `CashlyDataFactory()` localmente — DI quebrada          | M       | M     | G005             | Wave 4    |
| G007  | A   | Arch / Boundaries   | `CashlyUI` depende de `CashlyMock` (acoplamento prod → preview)                 | M       | M     | —                | Wave 1    |
| G008  | S/A | Correção            | 2× `fatalError` em produção (CashlyDataFactory:39, CashlyKey:29)                | P       | B     | —                | Wave 1    |
| G009  | A   | Erros               | `CashlyError` é genérico (3 cases sem contexto), sem mensagens user-facing      | M       | B     | —                | Wave 2    |
| G010  | A   | Concorrência        | `~85` force unwraps em produção                                                  | M       | M     | G014             | Wave 2    |
| G011  | M   | Toolchain           | `SWIFT_VERSION = 5.0` no app target vs `swift-tools-version: 6.2` no pacote     | P       | B     | —                | Wave 0    |
| G012  | S   | Config              | `NSUbiquitousContainerName = "NomeDoSeuApp"` placeholder em Info.plist          | P       | B     | —                | Wave 1    |
| G013  | S   | Config              | `aps-environment = development` em entitlements (revisar antes de prod)         | P       | B     | —                | Wave 1    |
| G014  | Q   | Testes              | Cobertura ≈ 0% fora de `BudgetActorTests`; sem rede de segurança para refactor  | G       | B     | G017             | Wave 0    |
| G015  | Q   | Toolchain           | Sem CI, SwiftLint, swift-format, hooks, EditorConfig                            | M       | B     | —                | Wave 0    |
| G016  | Q   | Toolchain           | README praticamente vazio (8 bytes)                                              | P       | B     | —                | Wave 8    |
| G017  | Q   | Testes              | Zero `XCTest`/`Testing` para Domain, Presentation, UI                            | G       | B     | G015             | Wave 0/2  |
| G018  | M   | Concorrência / UI   | `12` usos de `@StateObject`/`@ObservedObject` (objetivo: `@Observable`)         | M       | M     | G003 (Ryze@Obs)  | Wave 6    |
| G019  | M   | God files           | 4 telas/utils 282–497 linhas (AddTransactionScreen, HomeScreen, TransactionScreen, CashlySymbolCategory) | G | M | G017 | Wave 7    |
| G020  | M   | i18n / a11y         | `defaultLocalization = pt-BR` mas strings hardcoded em inglês; sem String Catalog | M     | B     | —                | Wave 7    |
| G021  | M   | Routing             | `MainDeeplink.swift` vazio; `MainState` carrega 4 routers separados sem semântica documentada | M | M | G014        | Wave 4    |
| G022  | A   | Arch / Migração     | Migrar Ryze → Prism (transversal). API surface não-trivialmente equivalente.    | XG      | A     | G014, G015       | Wave 5    |
| G023  | M   | Arch / Migração     | `RyzeUI` (33 typealiases) sem 1:1 em PrismUI: HStack/VStack/ZStack consolidados em `PrismStack`; nenhum `PrismView`/`PrismText`/`PrismLabel`/`PrismHorizontalList` direto | XG | A | G022 | Wave 5/6 (DECISÃO HUMANA PENDENTE) |
| G024  | M   | Observabilidade     | Sem `os.Logger` configurado; sem tracking de analytics                          | M       | B     | —                | Wave 8    |

Ordem de execução pretendida (resumo): **0 → 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8**.
Wave 5 (Ryze→Prism) é a maior; pode ser fatiada em 5a/5b/5c (ver plano).

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

### G007 — `CashlyUI → CashlyMock`
**Estado atual:** `CashlyMock/Extensions/View+Extension.swift`, `MockModifier.swift` usados via Preview em `CashlyUI`.
**Estado alvo:** Mocks moram em target separado consumido apenas por Preview/Test, não por código de produção. Considerar `condition: .when(configuration: .debug)` no Package.swift.
**Estratégia:** Marcar dependência `CashlyMock` como condicional (debug-only) ou trasladar utilidades de Preview para um target `CashlyPreview`.
**Risco:** Médio. Builds de release não devem regredir.

### G008 — `fatalError` em produção
**Estado atual:**
- `CashlyDataFactory.swift:39` (precisa olhar contexto exato)
- `CashlyKey.swift:29` (`fatalError("🗓️ Failed to extract month from date.")`)
**Estado alvo:** `try throws` ou `Result`; falhas explícitas e logadas.
**Estratégia:** Substituir por `throw CashlyError.…` específico; em call sites, propagar.
**Risco:** Baixo (apenas se existir caso real onde a data falha em extrair mês — improvável com `Calendar.current`).

### G009 — `CashlyError` genérico
**Estado atual:** `enum CashlyError: RyzeError { case onFetch, onSave, onRemove }`. `description` retorna `""`. Sem associated values, sem causa.
**Estado alvo:** Erros granulares por contexto (`PersistenceError`, `IntelligenceError`, `ValidationError`), com associated values e mensagens user-facing separadas.
**Estratégia:** Em Wave 2, introduzir hierarquia mínima (`PersistenceError`, `DomainError`, `PresentationError`). Em Wave 5, alinhar com `PrismError` (LocalizedError).
**Risco:** Baixo se feito incrementalmente.

### G010 — Force unwraps
**Estado atual:** ~85 ocorrências fora de testes (heurística, ainda inclui `!=`, etc — exigirá auditoria precisa).
**Estado alvo:** Apenas IBOutlets ou casos com invariante demonstrável documentado.
**Estratégia:** Wave 2 — auditar com `swiftc -warnings-as-errors` e/ou regra SwiftLint `force_unwrapping`. Lista de exceções permitidas + comentário justificando cada uma.
**Risco:** Médio. Alguns `!` mascaram bugs; vão aparecer no fluxo de execução real.

### G011 — `SWIFT_VERSION = 5.0` no app vs `swift-tools-version: 6.2`
**Estado atual:** Pacote SPM em Swift 6, app target compila como Swift 5.
**Estado alvo:** Coerência. Idealmente Swift 6 + concurrency strict em todos os targets.
**Estratégia:** Wave 0 — bumpar `SWIFT_VERSION = 6.0` no Xcode, ligar `SWIFT_STRICT_CONCURRENCY = complete` apenas após Wave 1/2 estabilizarem. Pode revelar warnings novos.
**Risco:** Baixo (mas pode produzir erros de Sendable que precisam de tratamento individual).

### G012 — `NSUbiquitousContainerName` placeholder
**Estado atual:** Info.plist contém `"NomeDoSeuApp"`.
**Estado alvo:** Nome real (`Cashly`) ou remover se não usado.
**Estratégia:** Wave 1, mudança trivial. Cuidado: alterar isso em produção pode invalidar containers iCloud existentes — confirmar com o usuário se há dados em prod.
**Decisão humana pendente:** Há instalações em prod usando esse container? Se sim, manter o placeholder mas documentar; senão, corrigir.

### G013 — `aps-environment = development`
**Estado atual:** Entitlement em modo development.
**Estado alvo:** `production` em build de Release/App Store.
**Estratégia:** Wave 1 — separar entitlements por configuração (Debug vs Release). Verificar `Production.xcscheme` (já existe).
**Risco:** Baixo (mas se push prod já está em uso, testar antes).

### G014 — Cobertura de testes ≈ 0%
**Estado atual:** Apenas `BudgetActorTests.swift` (1 actor de Data). Sem teste de Domain, Presentation, UI.
**Estado alvo:** 100% domain, 95% data, 90% presentation, smoke + snapshot UI.
**Estratégia:** Wave 0 = characterization tests para tudo que será refatorado a partir de Wave 3. Priorizar: `MainState` (cálculos financeiros), reducers, middlewares, adapters.
**Risco:** Baixo (criar teste é seguro), mas exige investimento de tempo significativo.

### G015 — Sem CI/lint/format/hooks
**Estado atual:** Nenhum `.github/workflows/`, `.swiftlint.yml`, `.swift-format`, `.editorconfig`, `pre-commit`.
**Estado alvo:** CI rodando `swift test` em PR, SwiftLint+swift-format em pre-commit, badges em README.
**Estratégia:** Wave 0. Configurações iniciais permissivas (não falhar build no primeiro dia).
**Risco:** Baixo.

### G016 — README vazio
**Estado atual:** `# cashly` (8 bytes).
**Estado alvo:** README com setup, arquitetura resumida, links para `.claude/memory/`.
**Estratégia:** Wave 8 (após plano se estabilizar; trabalho de doc).
**Risco:** Baixo.

### G017 — Zero testes em Domain/Presentation/UI
Ver G014. Notar: o projeto usa `import Testing` (Swift Testing nativo), 3 ocorrências, todas em `BudgetActorTests`.

### G018 — `@StateObject`/`@ObservedObject` (12)
**Estado atual:** 12 usos de wrappers Combine-era para observação.
**Estado alvo:** `@Observable` (macro Observation) no projeto inteiro.
**Estratégia:** Wave 6 — converter ViewModels para `@Observable`. Mas a maior parte desses 12 vem de Ryze (`RyzeStore` é `ObservableObject`?). Ver dependência G003.
**Decisão humana pendente:** se Wave 5 (Ryze→Prism) acontecer antes de Wave 6, esse gap diminui — `PrismStore` já é `@Observable`. Se cutover de Prism atrasar, fazer adaptador local.

### G019 — God files (4 arquivos 282–497 linhas)
**Estado atual:** `AddTransactionScreen.swift` (497), `CashlySymbolCategory.swift` (486), `HomeScreen.swift` (466), `TransactionScreen.swift` (282).
**Estado alvo:** ≤200 linhas por arquivo View; subcomponentes extraídos.
**Estratégia:** Wave 7 — quebrar em subviews em `Components/`. `CashlySymbolCategory` provavelmente é um catálogo enum gigante — mover para resource ou String Catalog.
**Risco:** Médio (snapshot tests cobrem regressão visual).

### G020 — i18n quebrada
**Estado atual:** `defaultLocalization = pt-BR` mas strings hardcoded em inglês, sem String Catalog (`*.xcstrings`).
**Estado alvo:** String Catalog completo, idiomas suportados explícitos.
**Estratégia:** Wave 7 — gerar Catalog vazio, deixar Xcode extrair strings, traduzir o mínimo viável.
**Risco:** Baixo.

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

### G024 — Observabilidade ausente
**Estado atual:** Sem `os.Logger`, sem `OSSignposter`, sem analytics tracker.
**Estado alvo:** Logger por subsystem/category, hooks de analytics via protocolo injetado.
**Estratégia:** Wave 8 — adotar `PrismFoundation/Logger` (após migração Ryze→Prism) ou wrapper interno mínimo enquanto isso.

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

### G026 — Ryze upstream renomeado para Prism (HEAD da `main`)
- **Severidade:** Crítica (build quebra em máquina limpa sem pin)
- **Esforço:** P (mitigado em Wave 0 via revision pin)
- **Onda:** Wave 0 mitigado; resolução real = Wave 5
- **Ação Wave 0:** Package.swift pinado em `revision: 15b047569bd780e5362c351140c49308da2e055e` (último commit Ryze-named).
- **Resolução final:** Wave 5a substitui dependência por Prism + atualiza imports.

### G027 — `swift test` CLI quebrado em CashlyResource (Foundation/SwiftUI/ImageResource)
- **Severidade:** Importante
- **Esforço:** S (1 dia)
- **Onda:** Wave 1
- **Causa:** `import RyzeFoundation` não re-exporta Foundation/SwiftUI; `ImageResource` requer .xcassets em pacote (não existe). Xcode supre via implicit imports + asset catalog do app target — SPM CLI não.
- **Mitigação Wave 0:** CI usa xcodebuild em vez de `swift test`.
- **Fix:** explicit `import Foundation` + `import SwiftUI` em CashlyResource; mover ImageResource para target com .xcassets ou criar .xcassets em CashlyResource.

### G028 — `xcbeautify` ausente em runner; CI depende do binário
- **Severidade:** Nice-to-have
- **Esforço:** P
- **Onda:** Wave 0 follow-up
- **Ação:** adicionar step `brew install xcbeautify` antes do build, ou substituir por `| cat`.

### G029 — Reducers (`AddUserReducer`, `MainReducer`, etc.) são `actor` mas conformam a `RyzeReducer` (global-actor-isolated)
- **Severidade:** Crítica (build CLI quebra; Xcode IDE compila por timing diferente de isolation check)
- **Esforço:** M (1 dia) ou G se exigir API redesign
- **Onda:** Wave 5 (Ryze→Prism reduce — PrismReducer pode ter isolation diferente) ou Wave 2 isolada
- **Descoberto:** Wave 0.5 (2026-05-10)
- **Mitigação:** Build via xcodebuild CLI ainda falha; Xcode IDE continua compilando. CI segue bloqueado até Wave 2 ou Wave 5.

### G030 — `MainRoute` declara `==` manualmente mas falta `hash(into:)` para conformance Hashable
- **Severidade:** Importante (build CLI quebra)
- **Esforço:** P
- **Onda:** Wave 2
- **Descoberto:** Wave 0.5
- **Fix:** Implementar `hash(into:)` manualmente OU remover `==` custom e deixar enum gerar (mas associated values exigem Hashable em todos).

### G031 — CashlyView types não implementam `RyzeUIMock.mocked()`
- **Severidade:** Importante (bloqueia build CLI)
- **Esforço:** M (1 dia) ou G se exigir mock data robusto
- **Onda:** Wave 6 ou Wave 5 (parte da migração Ryze→Prism)
- **Descoberto:** Wave 6 (2026-05-10)
- **Causa:** `RyzeView` protocol em Ryze 2b619d8 herda `RyzeUIMock` que requer `static func mocked() -> MockView`. 14 tipos Cashly (todos Screens + alguns Views/Components) declaram `: CashlyView` mas não implementam `mocked()`. Xcode IDE talvez tolere via default; CLI não.
- **Fix:** Adicionar `static func mocked() -> some View { ... }` em cada tipo, ou criar conformance default em CashlyUI.swift via extension genérica que retorna placeholder.

### G032 — `$store` binding projection ausente após migração para `@Environment(T.self)`
- **Severidade:** Importante (bloqueia build CLI — 25 call sites)
- **Esforço:** M-G (audit + reescrita Bindings)
- **Onda:** Wave 6 (G018 completo)
- **Descoberto:** Wave 6 (2026-05-10)
- **Causa:** `@EnvironmentObject` sintetiza `$store.x` para bindings. `@Environment(T.self)` não. Substituir por `@Bindable var store = store` em body ou `Binding(get:set:)` explícito.
- **Fix:** Em cada call site `$store.state.x` → `@Bindable var store = store` + `$store.state.x` (com `@Observable`, Bindable provê $). Ou explícito `Binding(get: { store.state.x }, set: { store.state.x = $0 })`. Trade-off: @Bindable é menos invasivo mas exige store mutável; manual binding é universal mas verboso.
