# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Migration Wave 0
**Objetivo**: Obter aprovação humana do `migration/migration-plan.md` e das 8 decisões bloqueadoras antes de iniciar Wave 0
**Deadline**: _(none)_

## Em Progresso

- Aguardando aprovação humana do `migration/migration-plan.md` antes de Wave 0

## Bloqueios Conhecidos

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

- Resolver itens de "Decisões Pendentes" com o time antes de rodar `/migrate Wave 0`.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
- `migration/gap-analysis.md` contém 24 gaps priorizados (7 críticos, 11 importantes, 6 nice-to-have).
