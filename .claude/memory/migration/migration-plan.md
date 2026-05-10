# Migration Plan — Cashly (2026-05-08)

> Plano em **ondas pequenas**, executável uma por sessão (≤1 dia útil cada).
> Cada onda termina com **testes verdes**, é **revertível** por `git revert`,
> e gera **um ADR** quando há decisão arquitetural.
>
> Ordem importa. Não pular ondas para "ir mais rápido".
> Wave 5 (Ryze→Prism) está condicionada a sub-decisões humanas e pode ser
> reordenada; o restante do plano é incremental e seguro.

---

## Mapa de dependências

```
Wave 0 (rede de segurança)
   │
   ├──► Wave 1 (higiene)
   │       │
   │       └──► Wave 2 (testes + erros granulares + force unwraps)
   │              │
   │              ├──► Wave 3 (Domain limpo: SwiftData/SwiftUI fora)
   │              │       │
   │              │       └──► Wave 4 (DI + composition root + routing)
   │              │              │
   │              │              └──► Wave 5 (Ryze→Prism, fatiada em 5a..5d)
   │              │                     │
   │              │                     └──► Wave 6 (@Observable + ViewModels)
   │              │                            │
   │              │                            └──► Wave 7 (god files + i18n + a11y)
   │              │                                   │
   │              │                                   └──► Wave 8 (docs + observability + ADR retroativos)
   │              │
   │              └─ (paralelo possível) Wave 7 a11y após Wave 4 se UI estável
   │
   └─ Wave 0 deve estar 100% antes de qualquer outra
```

Onda N só começa quando N-1 está **mergeada e estável (24h em main sem revert)**.

---

## Wave 0 — Rede de segurança (PRÉ-REQUISITO INEGOCIÁVEL)

**Objetivo:** garantir que ondas seguintes não quebrem silenciosamente.

**Gaps endereçados:** G011, G014 (parcial), G015, G017 (setup).

**Tarefas:**
- [ ] Adicionar `.github/workflows/ci.yml` rodando `swift test` (CashlyKit) em cada PR
- [ ] Adicionar `.swiftlint.yml` em config inicial **permissiva** (apenas warnings, nada quebra build); incluir regras alvo: `force_unwrapping`, `force_try`, `force_cast`, `large_tuple`, `function_body_length`, `type_body_length` — desligadas inicialmente como warning-only
- [ ] Adicionar `.swift-format` config básica seguindo `conventions.md` (largura 120, indent 4)
- [ ] Adicionar `.editorconfig`
- [ ] Adicionar pre-commit hook (`.claude/hooks/pre-commit`) que roda `swift-format --lint` + `swiftlint --quiet` (sem `--strict`)
- [ ] Bumpar `SWIFT_VERSION` do app target de `5.0` → `6.0` (G011); investigar warnings sem corrigir ainda
- [ ] Gerar relatório baseline de cobertura via `xcrun xccov view --report` ou `swift test --enable-code-coverage`; salvar em `.claude/memory/migration/coverage-baseline.txt`
- [ ] Adicionar **smoke test** em todas as 6 actors de `CashlyData/Actors/` (`init` + `getAll` retorna não-nil)
- [ ] Adicionar **snapshot tests** (swift-snapshot-testing) para cada uma das 8 telas em `CashlyUI/Screens/` — record mode na primeira execução; Wave 0 estabelece a baseline visual

**Critério de pronto:**
- CI verde em main (last commit + 1 PR-teste).
- Pre-commit hook bloqueia commit com lint error em arquivos novos.
- 8 snapshots gravados em `CashlyKit/Tests/CashlyTests/__Snapshots__/`.
- Cobertura conhecida e baselineada (mesmo que ainda baixa).
- Build do app continua passando em `Production.xcscheme`.

**Estimativa:** 1.5 dias.

**ADR:** **ADR-0001** — Adoção de Apple Dev Setup (já criado neste batch — registra a intenção; outros ADRs nascerão durante as ondas).

**Risco:** Baixo. Pode atrapalhar PRs em curso (warning de lint), mas hook é warning-only. Aviso ao "time" (autor único): re-run `swiftlint` antes de commitar.

**Rollback:** `git revert` da PR de Wave 0.

---

## Wave 0.5 — Explicit import audit (INSERIDO POR DESCOBERTA)

**Contexto:** Durante Wave 1, descoberto que xcodebuild CLI nunca constrói Cashly limpo — Xcode IDE faz implicit imports que CLI não replica. Bloqueia CI real, tests, e qualquer refactor que toque Domain/Resource.

**Objetivo:** Tornar build CLI verde via explicit imports nos arquivos que dependem de Foundation/SwiftUI transitivos.

**Gaps endereçados:** G027 (completa), G024 (parcial).

**Status (2026-05-10):** PARCIAL. Commit `3047f6f`. 23 files patched (CashlyDomain, CashlyData, CashlyResource, CashlyPresentation Actions/States/Route). Build progredido até Reducers — bloqueado por G029 (actor vs global-isolated protocol) e G030 (MainRoute Hashable).

**Tarefas:**
- [x] Audit + add explicit imports em CashlyDomain (5 files), CashlyData (7 files), CashlyResource (2 files), CashlyPresentation (9 files).
- [x] CashlyResourceImage: removido ImageResource, usa `Image(rawValue, bundle: .module)`.
- [x] Qualificar `CashlyDomain.Category` em States e AdapterActor para resolver ambiguidade.
- [ ] CashlyUI/CashlyMock audit — DEFERIDO (build não chega lá ainda).
- [ ] xcodebuild build verde — BLOQUEADO por G029 (Reducers actor) e G030 (MainRoute Hashable).
- [ ] swift build CashlyKit verde — mesmo bloqueio.
- [ ] SwiftLint rule para prevenir regressão — deferido para depois do build verde.

**Critério de pronto (atualizado):**
- Wave 0.5 considerada **funcionalmente completa** para imports; bloqueios remanescentes (G029, G030) são pre-existing bugs structurais que não são "import audit". Movidos para Wave 2.
- Build verde adiado até Wave 2 resolver G030 + Wave 5 resolver G029.

**Estimativa:** 0.5–1 dia.

**ADR:** Não necessário (mudança mecânica).

**Risco:** Médio. Mexer em 12+ arquivos. Cascading diagnostics esperadas — fazer 1 arquivo por vez, build após cada batch.

**Rollback:** `git revert` por arquivo se algum import quebrar algo.

---

## Wave 1 — Higiene básica + boundary fixes seguros

**Objetivo:** eliminar problemas óbvios sem mudança arquitetural.

**Gaps endereçados:** G007, G008, G012, G013.

**Status (2026-05-10):** PARCIAL. G012 + G013 commitados (`6db8b65`, `7bab811`). G008, G007 deferidos para após Wave 0.5 (G008 requer build CLI verde para validação).

**Tarefas:**
- [x] **G012** — `Info.plist`: `NSUbiquitousContainerName = "iCloud.cashly"` ✅ commit `6db8b65`
- [x] **G013** — entitlements Debug/Release split ✅ commit `7bab811`
- [ ] **G008** — substituir `fatalError` em `CashlyDataFactory.swift:39` e `CashlyKey.swift:29` por `throws` — **DEFERIDO até Wave 0.5 concluída**. Tentativa anterior cascateou breakage por interação com imports faltantes.
- [ ] **G007** — `CashlyMock` dep em `CashlyUI` — **DEFERIDO até Wave 0.5 concluída**

**Critério de pronto:**
- 0 `fatalError` em produção (grep deve retornar 0 fora de testes).
- Info.plist sem placeholder.
- Build de Release usa entitlements corretas.
- `CashlyMock` não aparece como dependência transitiva em build de Release de `CashlyUI`.
- Snapshots de Wave 0 continuam passando.

**Estimativa:** 0.5–1 dia.

**ADR:** **ADR-0002** — Política de force unwrap, fatalError e logging em produção.

**Risco:** Baixo, mas **G012 exige decisão humana** sobre o nome do container iCloud antes de mudar.

---

## Wave 2 — Erros granulares + força do safety

**Objetivo:** estabelecer hierarquia de erros e eliminar force unwraps.

**Gaps endereçados:** G009, G010, G017 (parcial: testes para os caminhos de erro).

**Tarefas:**
- [ ] **G009** — refatorar `CashlyError` em hierarquia:
  - `PersistenceError: CashlyError` (`fetchFailed(underlying:)`, `saveFailed(underlying:)`, `removeFailed(underlying:)`, `notFound(id:)`)
  - `DomainError: CashlyError` (`invalidInput(field:reason:)`, `businessRuleViolated(_:)`)
  - Manter `CashlyError` como conformance comum mas sem cases genéricos
  - Implementar `description`/`failureReason`/`recoverySuggestion` mínimos (preparando G022)
- [ ] **G010** — auditar todos os `!` em CashlyKit + `Cashly/`:
  - Listar com `rg '(?<![=!])\!(?!\=|\.)' --type swift -n` (refinar regex)
  - Para cada: `guard let` + propagação ou justificativa + comentário `// FORCE_UNWRAP_OK: <razão>`
  - Habilitar SwiftLint `force_unwrapping` como **error** (deixou de ser warning-only)
- [ ] Adicionar testes para os caminhos de erro novos em `MainState`, actors de Data, e ao menos um middleware

**Critério de pronto:**
- 0 force unwraps sem allowlist explícita (allowlist auditada).
- `CashlyError` substituído por hierarquia em todas as call sites.
- Cobertura subiu em ≥5 pontos percentuais nos paths de erro.
- Snapshots verdes.

**Estimativa:** 1.5–2 dias.

**ADR:** **ADR-0003** — Hierarquia de erros e propagação por camada.

**Risco:** Médio. Alguns `!` mascaram bugs reais; o aumento de cobertura vai expô-los — orçar tempo para correções.

---

## Wave 3 — Domain limpo

**Objetivo:** zerar imports proibidos no Domain.

**Gaps endereçados:** G001, G002, G004.

**Tarefas:**
- [ ] **G004** — `Score.swift`:
  - Adicionar `enum SeverityLevel: String, Sendable, Codable, CaseIterable { case critical, atRisk, overBudget, healthy }`
  - `Score` carrega `severity: SeverityLevel` em vez de `color: Color`
  - Remover `import SwiftUI` de `CashlyDomain/Models/Score.swift`
  - Adicionar em `CashlyUI/Extensions/SeverityLevel+Color.swift`: `extension SeverityLevel { var tint: Color { … } }`
  - Atualizar call sites em UI/Presentation
- [ ] **G002** — mover entities `@Model` SwiftData para CashlyData:
  - Criar `CashlyKit/Sources/CashlyData/Persistence/Entities/` e mover os 6 arquivos `*Entity.swift`
  - Atualizar `CashlyDataFactoryProtocol.swift`: tirar `import SwiftData` do Domain; o protocolo expõe apenas use cases (não Entity types)
  - Adapter actors em `CashlyData/Actors/` continuam fazendo a tradução `Entity → Model`
- [ ] **G001** — verificar que `CashlyDomain/CashlyDomain.swift` não usa `@_exported import RyzeFoundation`. Substituir por imports explícitos onde necessário (Wave 5 vai eliminar os Ryze; aqui apenas tira o re-export).
  - Manter `RyzeFoundation` apenas em `CashlyDomain/Utils/CashlyError.swift`, `CashlyKey.swift`, `CashlyIntelligence.swift` por enquanto (será migrado em Wave 5a/5c).

**Critério de pronto:**
- `grep "import SwiftData\|import SwiftUI\|import RyzeIntelligence" CashlyKit/Sources/CashlyDomain/` retorna 0 linhas (`RyzeFoundation` ainda permitido até Wave 5a).
- `BudgetActor` (e os outros 5) continuam compilando e seus testes passam.
- Snapshots verdes; cobertura mantida.

**Estimativa:** 1.5–2 dias.

**ADR:** **ADR-0004** — Domain puro: regras de import e separação Entity vs Model.

**Risco:** Alto. Refactor toca em Domain + Data simultaneamente. Mitigação: rodar com a rede de Wave 0/1/2 garantida; commits pequenos.

---

## Wave 4 — DI + composition root + routing

**Objetivo:** eliminar singletons, consertar DI, documentar/consolidar routing.

**Gaps endereçados:** G005, G006, G021.

**Tarefas:**
- [ ] **G005/G006** — eliminar `.shared`:
  - Criar `Composer.swift` em `Cashly/Cashly/` que recebe `ModelContainer` e produz factories.
  - `CashlyApp` instancia o `Composer` e injeta via `@Environment` (definir `EnvironmentKey` em `CashlyPresentation/Extensions/EnvironmentValues+Extension.swift`).
  - Remover `static let shared` de `CashlyPresentationFactory` e `MockCashlyFactory`.
  - `BudgetActor` (e os outros 5 actors) recebem `adapter: AdapterUseCase` via `init` em vez de instanciar `CashlyDataFactory()` localmente.
- [ ] **G021** — routing:
  - Documentar em `.claude/memory/architecture.md` (via `memory-curator`) a semântica dos 4 routers: provavelmente um por aba do `TabView` raiz.
  - Definir `MainDeeplink` como `enum` que produz `MainRoute`s a partir de URLs.
  - **DECISÃO HUMANA PENDENTE**: consolidar em 1 router só (com path enum por aba) ou manter 4? Decidir com o usuário antes de refactor.

**Critério de pronto:**
- 0 ocorrências de `.shared` em código de produção.
- `Composer` é o único lugar que conhece factory concreta.
- Testes de UI/Presentation podem injetar fakes (criar 1 teste exemplo provando isso).
- `MainDeeplink` tem ao menos uma rota implementada e testada.

**Estimativa:** 1.5 dias.

**ADR:** **ADR-0005** — Composition root, DI por construtor e estratégia de routing.

**Risco:** Médio.

---

## Wave 5 — Migração Ryze → Prism (TRANSVERSAL)

> **DECISÃO HUMANA PENDENTE — bloqueador.**
> Esta onda só pode ser executada após o usuário responder:
> 1. Estratégia: A (hard cutover), B (por camada — recomendada), C (adapter prolongado)?
> 2. Mantemos os typealiases `Cashly*` (apontando para `Prism*`) ou eliminamos a indireção?
> 3. Para componentes sem equivalente direto em PrismUI (`RyzeView`, `RyzeText`, `RyzeLabel`, `RyzeHorizontalList`, `RyzeBrowserView`, `RyzeSystemMonitor`, `RyzeSymbol`, design tokens):
>    - portar implementação de Ryze para um novo módulo `CashlyDesignSystem`?
>    - contribuir upstream para Prism?
>    - aceitar perda?
> 4. Tokens de design (Color/Size/Spacing/Shape) — Prism oferece sistema equivalente em `PrismUI/Tokens` ou precisamos manter `CashlyColor`/`CashlySize`/etc. como tipos próprios?
>
> Sem essas respostas, esta onda **não é executável** — apenas preparada.

**Pré-requisitos técnicos (não-negociáveis antes de iniciar 5a):**
- [ ] Wave 0–4 mergeadas e estáveis em main por ≥3 dias.
- [ ] Cobertura ≥60% em Domain + Data + Presentation (Domain ideal 90%).
- [ ] Snapshot tests cobrindo as 8 telas + componentes reutilizáveis (≥15 snapshots no total).
- [ ] Leitura completa de `PrismUI/Primitives/`, `PrismUI/Composites/`, `PrismUI/Layout/`, `PrismUI/Tokens/` por humano + agente.
- [ ] Adicionar `Prism` como dependência local em `Package.swift` (path: `../prism`) **sem remover Ryze ainda**.

### Wave 5a — Foundation (Ryze→Prism)
**Gap:** G022 (parte 1).

**Tarefas:**
- [ ] Substituir `import RyzeFoundation` → `import PrismFoundation` em todos os arquivos (24 ocorrências hoje).
- [ ] `RyzeEntity` → `PrismEntity` (verificar conformance: PrismEntity exige `CustomStringConvertible` + `PrismLogger`; Cashly entities provavelmente já têm).
- [ ] `RyzeError` → `PrismError`: **CashlyError precisa implementar** `errorDescription`, `failureReason`, `recoverySuggestion` (já preparado em Wave 2).
- [ ] `RyzeLocale` → equivalente em `PrismFoundation/Locale/`.
- [ ] Atualizar `CashlyDomain/CashlyDomain.swift`: remover `@_exported import RyzeFoundation`; expor types necessários via re-export explícito de `PrismFoundation` ou eliminar typealiases.

**Critério de pronto:** 0 `import RyzeFoundation` em CashlyKit; testes verdes; snapshots verdes.
**Estimativa:** 1 dia.

### Wave 5b — Architecture (Ryze→Prism)
**Gap:** G022 (parte 2).

**Tarefas:**
- [ ] `import RyzeArchitecture` → `import PrismArchitecture` (13 ocorrências).
- [ ] Atualizar `CashlyPresentation.swift` typealiases: `CashlyState = PrismState`, `CashlyAction = PrismAction`, `CashlyReducer = PrismReducer`, `CashlyMiddleware = PrismMiddleware`, `CashlyStore = PrismStore`, `CashlyRoutable = PrismRoutable`, `CashlyNavigationStyle = PrismNavigationStyle`, `CashlyRouter = PrismRouter`.
- [ ] Verificar **diferenças de API** entre `RyzeStore` e `PrismStore`:
  - `PrismStore` usa `PrismEffect<Action>` como retorno do reducer; se `RyzeStore` usa outro tipo (Combine publisher? AsyncStream?), call sites precisam adaptar.
  - `PrismStore.scope` aceita keypath; verificar se sintaxe Cashly atual é compatível.
  - **DECISÃO HUMANA PENDENTE**: validar que reducers/middlewares atuais cabem na assinatura `PrismReducer.reduce(into:action:) -> PrismEffect<Action>`.

**Critério de pronto:** 0 `import RyzeArchitecture`; reducers/middlewares todos compilando; ações fluindo (testes de Store passam).
**Estimativa:** 1.5–2 dias (depende de divergência de API).

### Wave 5c — Intelligence (Ryze→Prism)
**Gap:** G022 (parte 3).

**Tarefas:**
- [ ] Inspecionar `RyzeIntelligence` (3 usos: `Utils/CashlyIntelligence.swift`, `States/MainState.swift`, mais um).
- [ ] Mapear para sub-módulo apropriado em `PrismIntelligence` (ModelManager, NLP, Vision, RAG, Output).
- [ ] **DECISÃO HUMANA PENDENTE**: o caso de uso atual (predição de transações, ver `predictedTransactionsAmount`) usa qual API Ryze? Tem equivalente em Prism?

**Critério de pronto:** 0 `import RyzeIntelligence`; predição funcional.
**Estimativa:** 1 dia (se equivalência existir; pode dobrar se precisar reescrever).

### Wave 5d — UI (Ryze→Prism)
**Gap:** G022 (parte 4) + G023.

> **MAIOR ONDA. DECISÃO HUMANA PENDENTE crítica.**

**Pré-decisão obrigatória:** humano + agente leem PrismUI inteiro (Primitives, Composites, Layout, Forms, Tokens, Theme) e produzem **mapeamento concreto** (tabela ampliando G022/G023). Sem essa tabela, a onda não inicia.

**Tarefas (estrutura, não execução):**
- [ ] Substituir os 26 typealiases em `CashlyUI/CashlyUI.swift` por imports diretos `PrismUI` ou tipos próprios em `CashlyDesignSystem` (ver decisão).
- [ ] Reescrever call sites de:
  - `RyzeHStack`/`VStack`/`ZStack` → `PrismStack(.horizontal/.vertical/.depth)` — mecânico, mas alto volume.
  - `RyzeText` / `RyzeLabel` → `Text` nativo + modifiers Prism (ou portar componente para `CashlyDesignSystem`).
  - `RyzeView` (protocolo) → eliminar abstração ou criar `CashlyView` próprio.
  - `RyzeHorizontalList` → `PrismCarousel` ou portar.
  - `RyzeBrowserView` → portar de Ryze (provável) ou usar `WKWebView` nativo.
  - `RyzeSystemMonitor` → `PrismCapabilities/Metrics` (verificar API).
- [ ] Validar 8 snapshots: aceitar diff visual mínimo ou re-record após validação humana.

**Critério de pronto:**
- 0 `import RyzeUI` e 0 `Ryze*` em todo o repositório.
- Pacote `Ryze` **removido de** `Package.swift` e `Package.resolved`.
- Snapshots aprovados (humano confirma diffs visuais aceitáveis).
- Build de Release passa em todas as plataformas alvo.

**Estimativa:** 3–6 dias (alta variância — depende quanto vai precisar portar).

**ADR (toda Wave 5):** **ADR-0006** — Migração de Ryze para Prism: estratégia, mapeamento, componentes portados.

**Risco:** Alto. Mitigação: snapshot-first, pequenos PRs por feature, rollback trivial enquanto Ryze ainda estiver no Package.swift (até final de 5d).

---

## Wave 6 — `@Observable` em ViewModels

**Objetivo:** modernizar property wrappers de observação.

**Gaps endereçados:** G018.

**Pré-requisito:** Wave 5b concluída (PrismStore já é `@Observable`).

**Tarefas:**
- [ ] Auditar 12 usos de `@StateObject`/`@ObservedObject`. Determinar quantos são herdados de `RyzeStore`/`PrismStore` (devem desaparecer com Wave 5b) e quantos são ViewModels próprios.
- [ ] Para os próprios: converter classe para `@Observable` (macro Observation), substituir `@Published` por propriedades simples, ajustar Views para usar `@Bindable` ou `@State` conforme caso.
- [ ] Garantir `@MainActor` onde precisa.

**Critério de pronto:**
- 0 `@StateObject` / `@ObservedObject` em código novo.
- Lista de exceções (se houver) documentada com motivo.
- Snapshots verdes; nenhum re-render desnecessário (verificar com Instruments — opcional).

**Estimativa:** 1 dia.

**ADR:** **ADR-0007** — Observation: política de @Observable e @MainActor.

**Risco:** Baixo (após Wave 5b, mecânico).

---

## Wave 7 — God files + i18n + acessibilidade

**Objetivo:** quebrar arquivos grandes, ativar acessibilidade, traduzir.

**Gaps endereçados:** G019, G020, parcial a11y (não há gap específico mas é convention obrigatória).

**Tarefas:**
- [ ] **G019** — quebrar god files:
  - `AddTransactionScreen.swift` (497) → extrair seções para `Components/AddTransaction*View.swift`.
  - `HomeScreen.swift` (466) → idem.
  - `TransactionScreen.swift` (282) → idem.
  - `CashlySymbolCategory.swift` (486) → mover catálogo para String Catalog ou `Resource/`.
- [ ] **G020** — i18n:
  - Criar String Catalog (`*.xcstrings`) em `CashlyResource/`.
  - Extrair strings hardcoded; gerar entradas em pt-BR + en.
  - Usar `LocalizedStringResource` em call sites.
- [ ] **Acessibilidade**:
  - Auditar Views custom: adicionar `.accessibilityLabel(_:)`, `.accessibilityHint(_:)`, `.accessibilityAddTraits(_:)`.
  - Verificar Dynamic Type (não quebrar layout em xxxLarge).
  - Suporte a `reduceMotion`/`reduceTransparency`.
  - Snapshot tests com `accessibilityEnabled` e Dynamic Type variantes.

**Critério de pronto:**
- Nenhum arquivo `.swift` em `CashlyUI/Screens/` > 250 linhas.
- 100% das strings user-facing em String Catalog.
- Lint de a11y (manual checklist em PR template) preenchido.

**Estimativa:** 2–3 dias.

**ADR:** **ADR-0008** — Política de quebra de Views, i18n e acessibilidade.

**Risco:** Médio. Snapshot tests cobrem regressão visual.

---

## Wave 8 — Documentação + observabilidade + ADRs retroativos

**Objetivo:** fechar a casa.

**Gaps endereçados:** G016, G024, glossário, módulos.

**Tarefas:**
- [ ] **G016** — README com setup, arquitetura, links para `.claude/memory/`.
- [ ] **G024** — observabilidade:
  - `Logger` per-subsystem em `CashlyResource/Observability/`.
  - Hooks de analytics via `protocol AnalyticsTracker` (injeção pelo Composer).
  - `OSSignposter` em pelo menos 1 hot path (ex: cálculo de `score` em `MainState`).
- [ ] DocC em todos os types `public` de Domain (use cases, models).
- [ ] Atualizar `.claude/memory/glossary.md` com termos do domínio (Budget, Transaction, Participant, Score, etc.).
- [ ] Atualizar `.claude/memory/modules/*.md` para refletir estado pós-migração.
- [ ] ADRs retroativos para decisões que foram feitas mas não documentadas (ex: por que SwiftData? por que `@ModelActor`?).

**Critério de pronto:**
- README ≥1 página utilizável.
- DocC build sem warnings.
- Glossário tem ≥10 termos.
- ≥2 ADRs retroativos.

**Estimativa:** 1–1.5 dias.

**ADR:** N/A (esta onda **gera** ADRs em vez de definir um único).

**Risco:** Baixo.

---

## Quadro consolidado

| Onda | Tema                                  | Duração | Risco | ADR(s)         | Bloqueador humano? |
|------|----------------------------------------|---------|-------|----------------|--------------------|
| 0    | Rede de segurança                      | 1.5d    | B     | 0001           | Não                |
| 1    | Higiene + boundary                     | 0.5–1d  | B     | 0002           | G012 sim           |
| 2    | Erros + force unwraps                  | 1.5–2d  | M     | 0003           | Não                |
| 3    | Domain limpo                           | 1.5–2d  | A     | 0004           | Não                |
| 4    | DI + Composition Root + Routing        | 1.5d    | M     | 0005           | G021 sim           |
| 5a   | Ryze→Prism: Foundation                 | 1d      | M     | 0006 (parcial) | **Sim**            |
| 5b   | Ryze→Prism: Architecture               | 1.5–2d  | A     | 0006 (parcial) | **Sim**            |
| 5c   | Ryze→Prism: Intelligence               | 1d      | M     | 0006 (parcial) | **Sim**            |
| 5d   | Ryze→Prism: UI                         | 3–6d    | A     | 0006 (final)   | **Sim**            |
| 6    | @Observable                            | 1d      | B     | 0007           | Não                |
| 7    | God files + i18n + a11y                | 2–3d    | M     | 0008           | Não                |
| 8    | Docs + Observability + ADRs            | 1–1.5d  | B     | 0009+ (vários) | Não                |
| **Total (com 5)** |                            | **18–24d** | — | 8+         | —                  |
| **Total (sem 5)** |                            | **9–12d**  | — | 6+         | —                  |

---

## Tracking

Cada onda concluída deve ter entrada em `.claude/memory/migration/migration-log.md`
(criado pelo `memory-curator` ao finalizar a onda) com:

- Wave N — `<nome>`
- Iniciada em / concluída em
- ADR(s) gerados
- Métricas antes/depois (linhas mudadas, arquivos afetados, gaps fechados, cobertura)
- Surpresas / lições aprendidas
- Hash do commit final da onda

---

## Decisões humanas pendentes (consolidado)

Antes de iniciar **qualquer** onda além da 0:

1. **Wave 1 / G012** — `NSUbiquitousContainerName`: há instalações em prod usando o placeholder?
2. **Wave 1 / G013** — `aps-environment`: push notifications já estão em uso?
3. **Wave 4 / G021** — Consolidar 4 routers em 1 com path enum, ou manter 4 (1 por aba)?
4. **Wave 5 (todas as sub-ondas)** — ver bloco de decisão pendente em Wave 5.
5. **Wave 5d** — Lista concreta de componentes RyzeUI sem equivalente PrismUI: portar para `CashlyDesignSystem` (novo target) ou aceitar perda?
6. **Wave 5c** — Apple Intelligence vs OpenAI vs outro: o que `RyzeIntelligence` está fazendo hoje?

Sem respostas, o plano executa até **Wave 4 inclusive**, então **pausa**.
