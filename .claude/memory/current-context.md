# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Wave 0.5 Partial → Wave 2 (G030) + Wave 5 (G029)
**Objetivo**: Desbloquear build CLI resolvendo G029 (Reducers) + G030 (MainRoute Hashable)
**Deadline**: _(none)_

## Em Progresso

- Wave 0 partial (22f6034).
- Wave 1 partial: G012 + G013 (`6db8b65`, `7bab811`).
- Wave 0.5 partial: 23 files com explicit imports (`3047f6f`). Build progrediu até Reducers.
- Build CLI bloqueado por G029 (Reducers actor vs RyzeReducer global isolation) e G030 (MainRoute Hashable missing).

## Bloqueios Conhecidos

- **G029** — Reducers declarados como `actor` mas conformam `RyzeReducer` (global-isolated). Build CLI quebra. Xcode IDE compila por timing diferente. Fix exige Wave 5 (Ryze→Prism, PrismReducer pode ter isolation diferente) ou redesign isolado.
- **G030** — `MainRoute` declara `==` mas falta `hash(into:)`. Fix simples Wave 2.
- 8 decisões humanas pendentes bloqueiam Wave 5 (Ryze→Prism) — ver "Decisões Pendentes" abaixo.

## Decisões Pendentes

Detalhes completos em `.claude/memory/migration/migration-plan.md`. Resumo:

1. Estratégia da migração Ryze→Prism: big-bang vs gradual (typealiases de compatibilidade).
2. Manter `CashlyState`/`CashlyAction`/etc. como typealiases ou trocar para tipos próprios (decoupling do framework).
3. Domain ficar puro (zero dependências externas) ou continuar dependendo de Prism?
4. Resolver discrepância `swift-tools 6.2` (pacote) vs `SWIFT_VERSION = 5.0` (app target).
5. Definir significado canônico de **Tag vs Category** no domínio (ver `glossary.md`).
6. Confirmar se `RyzeStore` tem equivalente exato em Prism ou requer adaptador.
7. Decidir se UI call sites para Prism são reescritos em uma onda única (5a) ou por tela.
8. Aprovar escopo e sequência das 9 ondas antes da execução de Wave 0.

## Convenções Temporárias

_(nenhuma)_

## Notas para a Próxima Sessão

- Resolver G030 (MainRoute hash) em Wave 2 — fix simples, desbloqueia ~1 step do build.
- G029 (Reducers) precisa decisão: redesign isolado ou aguardar Wave 5. Sem build CLI, tests não rodam.
- Após build CLI verde: retomar G008 (CashlyKey + CashlyDataFactory throwing) e G007 (CashlyMock dep).
- G026, G027, G028, G029, G030 registrados em `migration/gap-analysis.md` — não duplicar aqui.
- 8 decisões humanas em "Decisões Pendentes" ainda abertas — resolver antes de Wave 5.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
