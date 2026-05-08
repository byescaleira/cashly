# Módulo: CashlyTests

## Identidade

- **Tipo**: Test target (Swift Testing)
- **Path**: `CashlyKit/Tests/CashlyTests/`
- **Target SPM**: `CashlyTests` (`testTarget`)
- **Arquivos Swift**: 4 (1 teste real + 3 de infra/common)
- **Dependências**: TODOS os targets Cashly (`Domain`, `Data`, `Presentation`, `UI`, `Mock`) + `Ryze`
- **Test plan**: `Cashly.xctestplan`

## Conteúdo

```
Tests/CashlyTests/
├── Cashly.xctestplan
├── Actors/
│   └── BudgetActorTests.swift          ← único teste real
└── Common/
    ├── CommonTestSuite.swift           ← @Suite base com factories injetadas
    ├── CommonScenario.swift
    └── CommonTags.swift
```

`CommonTestSuite` (`Common/CommonTestSuite.swift`) instancia `MockCashlyFactory()` e expõe `budgetUseCase`, `categoryUseCase` para os testes. Helper `assertEqual<T>` envolve `#expect`.

## Observações / dívidas

1. **Cobertura crítica baixíssima**:
   - Domain: 0%
   - Data: parcial (apenas BudgetActor)
   - Presentation: 0% (Reducers, Middlewares, Stores nunca testados)
   - UI: 0%
2. **Sem snapshot tests**, sem XCUITest, sem perf tests.
3. **`Cashly.xctestplan` existe** mas configuração não foi inspecionada.
4. **Convenção de testes consistente**: usa Swift Testing (`@Test`, `@Suite`, `#expect`), nada de XCTest.
