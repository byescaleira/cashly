# ADR-0001 — Adoção do Apple Dev Setup + intenção de migrar Ryze → Prism

**Status:** Aceito
**Data:** 2026-05-08
**Decisores:** Rafael Escaleira (proprietário do projeto). Validação dos detalhes
de migração ficará registrada em ADRs subsequentes (0002+).

---

## Contexto

O projeto **Cashly** existe desde 29/08/2025 (~9 meses), com 122 arquivos Swift
e 11.201 linhas de código. Convenções foram estabelecidas implicitamente pelo
autor único, sem registro formal. Não há CI, lint, format, testes além de um
único `BudgetActorTests`, e nenhuma documentação de arquitetura formal.

O projeto é fortemente acoplado à dependência externa **Ryze**
(`github.com/rafaelesantos/ryze`), que fornece:
- `RyzeFoundation` (24 arquivos consumidores)
- `RyzeArchitecture` (13 — Store/Reducer/Middleware/Router)
- `RyzeUI` (10 + 26 typealiases em `CashlyUI`)
- `RyzeIntelligence` (3)

Ryze atravessa todas as camadas, inclusive Domain (`@_exported import RyzeFoundation`
em `CashlyDomain.swift`), violando a Dependency Rule de Clean Architecture.

Em paralelo, o autor mantém o pacote local **Prism**
(`/Users/rafael.escaleira/Documents/prism`), uma evolução conceitual de Ryze
com escopo significativamente mais amplo (PrismFoundation, PrismArchitecture,
PrismUI, PrismIntelligence, PrismSecurity, PrismStorage, PrismNetwork,
PrismCapabilities, PrismGamification, PrismServer). A intenção declarada é
migrar Cashly de Ryze para Prism.

## Decisão

1. **Adotar a config "Apple Dev Setup"** (`CLAUDE.md` + `.claude/memory/*` +
   subagentes definidos) como padrão de trabalho do projeto Cashly.

2. **Executar migração incremental em ondas** (ver
   `.claude/memory/migration/migration-plan.md`), começando por uma rede de
   segurança (Wave 0) e progredindo até Ryze → Prism (Wave 5) e modernização
   final (Waves 6–8).

3. **Migrar Ryze → Prism** em estratégia **B (por camada)** como recomendação,
   com possibilidade de fallback para C (adapter prolongado). Hard cutover
   (A) está descartado.

4. **Pausar antes de Wave 5** se decisões humanas pendentes (ver lista no
   `migration-plan.md`) não estiverem respondidas. As ondas 0–4 são executáveis
   sem essas respostas.

5. **Toda mudança arquitetural significativa gera novo ADR** numerado
   sequencialmente em `.claude/memory/adr/`.

## Consequências

### Curto prazo (ondas 0–2, ~1 semana de trabalho)
- Fricção em PRs em curso: pre-commit hook adicional, lint warnings.
- Estabilização da base: CI verde, snapshots gravados, force unwraps eliminados.
- Hierarquia de erros formalizada (preparando Wave 5a).

### Médio prazo (ondas 3–5, ~2–3 semanas adicionais)
- Refactor de Domain: SwiftData/SwiftUI removidos da camada interna; Entities
  passam para Data layer.
- Composition root explícito; singletons removidos.
- Migração Ryze → Prism completa; pacote Ryze removido do `Package.swift`.

### Longo prazo (ondas 6–8, ~1 semana)
- Property wrappers modernos (`@Observable`).
- God files quebrados, i18n e a11y corretos.
- Documentação (DocC, README, glossário) e observabilidade (Logger, analytics).

### Esforço total estimado
- **18–24 dias úteis** com migração Ryze → Prism completa.
- **9–12 dias** se a migração para Prism for adiada ou conduzida em paralelo.

## Alternativas consideradas

### Alt 1 — Não adotar a config
**Rejeitado.** A dívida arquitetural (Domain importando SwiftUI/SwiftData,
singletons, 0% de testes em domain/presentation/UI) já está grande; manter
implícitos só piora. A Dependency Rule continuará violada e o lock-in em Ryze
continuará crescendo.

### Alt 2 — Adoção parcial (só TDD, ou só lint)
**Rejeitado.** O valor da config vem do conjunto: princípios de arquitetura,
TDD, segurança, acessibilidade, observabilidade. Adoção fragmentada deixa
buracos previsíveis.

### Alt 3 — Reescrita do projeto do zero usando Prism
**Rejeitado.** 11k LOC + 6 features funcionais (Budget, Category, Tag,
Transaction, User, Participant + Intelligence). Custo proibitivo, risco alto,
nenhum benefício além de "código novinho". Migração incremental preserva
funcionalidade.

### Alt 4 — Hard cutover Ryze → Prism em PR único
**Rejeitado.** Sem cobertura de testes, hard cutover é apostar a casa.
Mantemos como Estratégia A apenas como referência teórica.

### Alt 5 — Manter Ryze indefinidamente
**Considerado.** Ryze funciona. Mas é mantido pelo mesmo autor que escreveu
Prism; o sinal claro é que Prism é a evolução. Continuar em Ryze acumula
divergência e duplica manutenção.

## Riscos e mitigações

| Risco                                              | Mitigação                                                |
|----------------------------------------------------|----------------------------------------------------------|
| Wave 0 atrasa por configuração de CI               | Usar `.github/workflows/ci.yml` mínimo; templates Apple. |
| Refactor de Domain (Wave 3) quebra features        | Wave 0 grava snapshots; Wave 2 sobe cobertura.           |
| Migração UI Ryze→Prism (5d) sem mapeamento 1:1     | Pré-decisão humana obrigatória; portar componentes faltantes para um `CashlyDesignSystem` próprio. |
| Snapshot tests viram fonte de fricção visual       | Re-record mode + revisão humana por PR.                  |
| Wave 5b: API de `PrismStore` divergir de `RyzeStore` | Confirmar antes de iniciar; reducers podem precisar de pequenos adaptadores. |

## Referências

- `.claude/memory/migration/baseline.md` — fotografia do projeto em 2026-05-08.
- `.claude/memory/migration/gap-analysis.md` — 24 gaps priorizados.
- `.claude/memory/migration/migration-plan.md` — 9 ondas (0..8) com critérios de pronto.
- `CLAUDE.md` — princípios inegociáveis e workflow de feature.
- `.claude/memory/conventions.md`, `.claude/memory/architecture.md`,
  `.claude/memory/tech-stack.md` — alvo (estado desejado).
- `/Users/rafael.escaleira/Documents/prism/Sources/` — package destino.

## Próximos ADRs previstos

- **ADR-0002** — Política de force unwrap, fatalError e logging em produção (Wave 1).
- **ADR-0003** — Hierarquia de erros e propagação por camada (Wave 2).
- **ADR-0004** — Domain puro: regras de import e separação Entity vs Model (Wave 3).
- **ADR-0005** — Composition root, DI por construtor e estratégia de routing (Wave 4).
- **ADR-0006** — Migração Ryze → Prism: estratégia, mapeamento e componentes portados (Wave 5).
- **ADR-0007** — Observation: política de @Observable e @MainActor (Wave 6).
- **ADR-0008** — Quebra de Views, i18n e acessibilidade (Wave 7).
