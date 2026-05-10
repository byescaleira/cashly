# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Wave 1 Partial → Wave 0.5
**Objetivo**: Executar Wave 0.5 (audit de imports explícitos) para desbloquear G008 + G007 + tests
**Deadline**: _(none)_

## Em Progresso

- Wave 0 partial commitada (22f6034).
- Wave 1 PARCIAL: G012 + G013 commitados (`6db8b65`, `7bab811`). G008 + G007 deferidos.
- Wave 0.5 NOVA: inserida no plano após descoberta de que xcodebuild CLI nunca compila Cashly (Xcode IDE faz implicit imports). Wave 0.5 = audit de explicit imports em CashlyDomain/Resource/etc.

## Bloqueios Conhecidos

- **xcodebuild CLI não compila Cashly** (descoberto durante Wave 1). Bloqueia CI real, tests, e qualquer refactor downstream (G008). Resolve em Wave 0.5.
- **G027** (parcial) — só CashlyResource imports adicionados originalmente; cascateou para Domain. Wave 0.5 endereça completo.
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

- Wave 0.5 é next: audit explícito de imports em CashlyDomain/Resource/Data/Presentation/UI. Validar via xcodebuild + swift build após cada batch. Lista mínima conhecida: 12 arquivos em CashlyDomain sem import (Models/*.swift, Use Cases/*.swift).
- Após Wave 0.5 verde: retomar G008 (CashlyKey + CashlyDataFactory throwing) e G007 (CashlyMock dep).
- G026, G027, G028 já registrados em `migration/gap-analysis.md` — não duplicar aqui.
- 8 decisões humanas em "Decisões Pendentes" ainda abertas — resolver antes de Wave 5.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
- Backup branch removido durante recovery (não havia mais conteúdo único após reset).
