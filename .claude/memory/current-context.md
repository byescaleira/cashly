# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Build CLI verde — retomar Wave 1 (G008, G007) + Wave 2 (G009, G010)
**Objetivo**: Escrever smoke tests/snapshots + retomar G008/G007/G009/G010
**Deadline**: _(none)_

## Em Progresso

- Wave 0 partial (`22f6034`).
- Wave 1 partial: G012 + G013 (`6db8b65`, `7bab811`).
- Wave 0.5 partial: 23 files imports (`3047f6f`).
- Wave 2 partial: G030 + Ryze re-pin + keypath (`0b203eb`).
- Wave 6 complete: G018 + G031 + G032 + Sendable + cashlyConfetti (`08e17b0`, `697dd16`, `fd7f73e`, `5bdbd6f`).
- **BUILD CLI VERDE** em iOS Simulator destination.

## Bloqueios Conhecidos

- 8 decisões humanas pendentes bloqueiam Wave 5 (Ryze→Prism).

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

- **Build CLI verde** — Wave 0 deferred items (smoke tests, snapshot tests, coverage baseline) podem ser executados.
- Retomar Wave 1: G008 (CashlyKey + CashlyDataFactory throwing) e G007 (CashlyMock dep).
- Wave 2: G009 (CashlyError hierarchy) e G010 (~85 force unwraps).
- G026, G027, G028, G029, G030, G031, G032 registrados em `migration/gap-analysis.md`.
- 8 decisões humanas em "Decisões Pendentes" ainda abertas — resolver antes de Wave 5.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
