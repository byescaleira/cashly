# Cashly

Aplicativo de planejamento financeiro em SwiftUI, com persistência local em SwiftData e sincronização CloudKit em dispositivos assinados.

O código usa models `@Observable` por responsabilidade (sessão, finanças, lista de transações, inteligência e um editor por formulário). As telas recebem todos os models pelo `@Environment`; a rota cria o editor de cada formulário. A arquitetura e as fases de refatoração estão em [docs/refactor-plan.md](docs/refactor-plan.md). A navegação tem uma pilha por seção e apresentações modais em telas regulares.

- [Arquitetura, isolamento e escolha dos patterns](docs/architecture.md)
- [Code review, correções e próximos pontos de atenção](docs/code-review.md)
- [Refactors e revisão dos padrões SwiftUI](docs/swiftui-patterns-review.md)
- [Revisão de Liquid Glass e materiais](docs/liquid-glass-review.md)
- [Revisão do banco e integrações Apple Intelligence](docs/data-and-intelligence-review.md)
- [Entradas, saídas e relacionamento por período](docs/financial-flows.md)
- [Plano de execução](docs/execution-plan.md)
- [Diagnósticos de migração, integridade e escala](docs/validation.md)

Abra `Cashly.xcworkspace` no Xcode e selecione o scheme `Production`. O pacote requer Swift 6.2 e iOS/iPadOS, macOS e visionOS 27 ou posteriores. A compilação foi verificada com Xcode 27 beta 6.

O simulador usa o banco local real com CloudKit desativado. Nos dispositivos, o app usa o container `iCloud.cashly` e precisa das capabilities e assinatura correspondentes.

Não há dependências externas no pacote. `CashlyDesignSystem` reúne os componentes SwiftUI usados pelo app; `CashlyMock` fornece dados em memória para o módulo separado `CashlyPreview`. Esses módulos não são dependências do app. `CashlyAudit` reúne os diagnósticos sobre bancos reais (migração, integridade, volume).

Valores financeiros usam `Money` em centavos BRL. O schema V3 mantém V1/V2 congelados e os campos de migração. Transações não dependem de orçamento; planejamento e despesas se relacionam por proprietário, categoria e competência. Entradas possuem tipo e total separados no domínio e no banco; o layout existente não ganhou controles de entrada. Cada janela possui seu usuário e navegação; consultas financeiras usam esse contexto explicitamente.

Para compilar, use `scripts/build.sh Debug` ou `scripts/build.sh Release`, com `DEVELOPER_DIR` apontando para o Xcode desejado. O script compila iOS, os apps macOS e visionOS, sem executar testes.

Para rodar os testes, use `scripts/test.sh`. Há um target por camada: `CashlyDomainTests` (regras puras), `CashlyDataTests` (repositórios com banco em memória), `FeatureCoreTests` (sessão, navegação, filtro) e um `Feature…Tests` por feature (models das telas). O script executa o scheme `CashlyKit-Package` no simulador do iPhone 17 com iOS 27; `CASHLY_TEST_DESTINATION` troca o destino.

Para formatar os fontes, use `scripts/format.sh`; para verificar o padrão, use `scripts/format.sh --check`. O projeto utiliza o `swift-format` incluído no toolchain da Apple, com quatro espaços e as demais regras padrão, configurado em `.swift-format`. O comando abrange o app, os módulos, os testes e o manifesto do pacote.

Para verificar formatação e qualidade, use `scripts/lint.sh`. O comando instala o SwiftLint 0.65.1 em `.tools` na primeira execução, validando o SHA-256 da distribuição oficial, e aplica `.swiftlint.yml` em modo estrito. Comentários no código Swift são proibidos pela regra `no_comments`. O job de lint bloqueia os builds do CI em caso de violação. Veja [o escopo e as regras](docs/lint.md).

A reestruturação parte do commit `510d6be` (`Add Intelligence`). O histórico posterior foi preservado na branch local `backup/pre-ai-rollback-2026-10-04`; o remoto não foi alterado.
