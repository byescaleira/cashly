# Cashly

Planejamento financeiro pessoal em SwiftUI para iOS, iPadOS, macOS e visionOS 27, com SwiftData local e sincronização CloudKit em aparelhos assinados.

- [Arquitetura](docs/architecture.md): camadas, targets, padrões, receita de feature, ferramentas e CI.
- [Decisões](docs/decisions.md): o que foi decidido e por quê.
- [Backlog](docs/backlog.md): riscos, pendências e próximas features.
- [Roadmap](docs/roadmap.md): assinatura, integrações com o sistema e novas features, por fase.
- [Motor de análise](docs/analytics.md): matemática financeira, modelos e LLM para análises de passado, presente e futuro.
- [Entradas, saídas e orçamento por período](docs/financial-flows.md): regras financeiras.
- [Validação](docs/validation.md): verificações automáticas, diagnóstico e roteiro antes de distribuir.

## Começando

Abra `Cashly.xcworkspace` no Xcode 27 e use o scheme `Production` para o app ou `CashlyKitTests` para os testes. O pacote não tem dependências externas.

```sh
scripts/format.sh
scripts/lint.sh
scripts/build.sh Debug
scripts/test.sh
scripts/audit.sh
```

O simulador usa o banco local com CloudKit desligado. Nos aparelhos, o app usa o container `iCloud.cashly`.
