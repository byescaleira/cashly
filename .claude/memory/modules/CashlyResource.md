# Módulo: CashlyResource

## Identidade

- **Tipo**: Resource layer — assets e fixtures JSON
- **Path**: `CashlyKit/Sources/CashlyResource/`
- **Target SPM**: `CashlyResource` (com `.copy(...)` de 6 arquivos JSON em `Package.swift:48-55`)
- **Arquivos Swift**: 2
- **Dependências de target**: nenhuma de target Cashly
- **Dependências externas**: `Ryze`
- **Linkagem inversa**: `CashlyUI`, `CashlyMock`

## Responsabilidade aparente

- Empacota recursos (assets visuais) e mocks JSON de bootstrap:
  - `Mocks/MockUsers.json`
  - `Mocks/MockCategories.json`
  - `Mocks/MockBudgets.json`
  - `Mocks/MockTransactions.json`
  - `Mocks/MockTags.json`
  - `Mocks/MockParticipants.json`
- `Assets/`: ativos gráficos (estrutura não detalhada nesta passada).

## Observações / dívidas

1. **Apenas 2 arquivos Swift** — provavelmente um `Bundle.module` accessor + um helper genérico. Conteúdo predominantemente declarativo (JSON + assets).
2. **Mocks de bootstrap não são test fixtures puros**: são usados em `CashlyMock` para popular previews/simulator. Mudança de schema dos `*Entity` exige sincronizar JSON.
3. **Sem testes próprios**.
