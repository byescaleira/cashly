# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Migration Wave 0 → Wave 1
**Objetivo**: Concluir Wave 1 (smoke/snapshot tests) após desbloquear G027
**Deadline**: _(none)_

## Em Progresso

- Wave 0 partial commitada (22f6034). Smoke tests e snapshot tests deferidos — aguardam resolução de G027 (SPM CLI quebrado em CashlyResource).
- Wave 1 ainda não iniciada.

## Bloqueios Conhecidos

- **G027** — `swift test` CLI quebra em CashlyResource (falta de explicit imports de Foundation/SwiftUI; asset catalog não-bundled). Bloqueia smoke/snapshot tests. CI usa xcodebuild como workaround.
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

- Iniciar Wave 1 após resolver G027 (SPM CLI / CashlyResource explicit imports).
- G026, G027, G028 já registrados em `migration/gap-analysis.md` — não duplicar aqui.
- 8 decisões humanas em "Decisões Pendentes" ainda abertas — resolver antes de Wave 5.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
