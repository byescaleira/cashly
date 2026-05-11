# Contexto Atual

> **Mantido pelo `memory-curator`. Não edite manualmente sem ler o arquivo todo.**
> Este arquivo descreve o que está acontecendo AGORA. Histórico vai para `progress-log.md`.

## Sprint / Milestone

**Atual**: Migration quase concluída. Wave 5a (Architecture layer) validada. Wave 5b (CashlyDesignSystem / UI layer port) é o único bloco remanescente.
**Objetivo**: Completar Wave 5b — criar `CashlyDesignSystem` target com wrappers próprios sobre SwiftUI, eliminando 57 erros de tipos PrismUI inexistentes.
**Deadline**: _(none)_

## Em Progresso

_(vazio — nenhuma branch ativa no momento)_

## Bloqueios Conhecidos

- **G035** — PrismUI surface gaps: ~14 tipos e ~10+ modifiers usados em CashlyUI não existem em PrismUI (PrismView, PrismText, PrismLabel, PrismSymbol, PrismHStack/VStack/ZStack, PrismList, PrismHorizontalList, PrismBrowserView, PrismSystemMonitor, PrismColor, PrismShape, PrismSize, PrismSpacing, PrismCurrencyTextField). Bloqueia swap de typealiases em CashlyUI — requer criação de `CashlyDesignSystem` target (opção a de G035) ou reescrita per-call-site.

## Decisões Pendentes

- ADR-0002 orienta Wave 5a concluída. Wave 5b requer **ADR-0003** quando estratégia CashlyDesignSystem for confirmada (criar target vs. per-call-site SwiftUI swap).
- Diferença semântica **Tag vs Category** ainda não formalizada (ver `glossary.md` pendências).
- `MainDeeplink.swift` vazio — intenção (TabView deeplinks? URL routing?) precisa ser confirmada antes de Wave 4 (G021).

## Convenções Temporárias

- **`@retroactive @unchecked Sendable`** em `RyzeStore` e `RyzeIntelligencePredictionInput` — mitiga ausência de Sendable upstream enquanto Wave 5 não conclui. Remover após Wave 5 completa.
- **Ryze pinado em `revision: 15b047569bd780e5362c351140c49308da2e055e`** — pino tático para evitar quebra de build por renomeação upstream. Remover quando Wave 5 substituir por Prism.

## Notas para a Próxima Sessão

- **Wave 5b**: continuar com swap incremental de typealiases dentro de `CashlyDesignSystem.swift`. Estratégia recomendada (G035-a): criar `CashlyKit/Sources/CashlyDesignSystem/` com wrappers próprios sobre SwiftUI primitives para os ~14 tipos faltantes. Validar com `AddUserScreen` (menor screen) antes de ripple para demais.
- Após Wave 5b verde: escrever ADR-0003 (CashlyDesignSystem strategy).
- Waves deferred que não dependem de Wave 5: Wave 7 (god files — G019, i18n tail G020-tail, a11y tail) e Wave 8 (observabilidade — G024, README G016).
- G003/G022/G023 ainda abertos (Ryze cross-cutting completo) — resolvidos quando Wave 5 completa.
- `migration/baseline.md` é imutável — referência para comparar métricas futuras.
