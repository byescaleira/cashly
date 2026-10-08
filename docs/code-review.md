# Code review da reestruturação

A evolução posterior desacoplou orçamento/transação e adicionou entradas no schema V3. O comportamento atual está em [financial-flows.md](financial-flows.md); as descrições de bloqueio de categoria/mês de orçamento abaixo são históricas e foram substituídas pela associação em leitura.

Revisão em 04/10/2026, sobre o código reestruturado a partir de `510d6be`. O foco foi arquitetura, isolamento, integridade, navegação e comportamento financeiro. Testes automatizados não foram analisados, alterados ou executados, conforme solicitado.

## Correções implementadas

| Problema | Efeito possível | Correção e localização |
| --- | --- | --- |
| Dependência do Ryze em estado, navegação e componentes | Projeto sem compilar após remover a biblioteca | Remoção da dependência; MVVM com Observation e componentes próprios. `CashlyKit/Package.swift`, `CashlyPresentation`, `CashlyDesignSystem`. |
| Rascunhos e apresentação com estado compartilhado | Abrir ou editar um formulário podia carregar o contexto de outro | ViewModel em `@State` por destino, draft próprio e carga por ID. `CashlyUI/Screens/Add*Screen.swift`. |
| Respostas assíncronas antigas | Requisição anterior podia sobrescrever o usuário ou filtro atual | Controle de revisão no MainViewModel; tasks de previsão canceláveis e proteção por usuário. `MainViewModel+Operations.swift`, `CashlyIntelligenceModifier.swift`. |
| Escritas de participantes separadas da transação | Falha intermediária podia deixar participantes órfãos ou dados parcialmente alterados | Aggregate salvo em uma operação no mesmo actor, com rollback. Exclusão da transação também remove seus participantes. `CashlyRepository+Transaction.swift`. |
| Exclusão de registros ainda referenciados | Orçamentos, categorias ou usuários removidos podiam quebrar o histórico | Guardas de integridade no repositório, inclusive para exclusões em lote. `CashlyRepository+Budget.swift`, `+Category.swift`, `+User.swift`. |
| Conversão silenciosa de referências ausentes | Uma transação compartilhada podia perder participantes no mapeamento e entrar nos totais pelo valor cheio | Mapeamento valida referências e participantes; sinaliza dados parciais e bloqueia IDs conflitantes. `CashlyRepository+Mapping.swift`. |
| Alterar categoria/mês de um orçamento usado | A alteração podia reinterpretar transações existentes | Bloqueio dessas alterações quando há transações; valor e descrição continuam editáveis. `CashlyRepository+Budget.swift`. |
| Mais de um orçamento da mesma categoria e mês | Planejamento e seleção do formulário ficavam ambíguos | Verificação antes da escrita local, com mensagem específica. `CashlyRepository+Budget.swift`. |
| Campos numéricos inválidos e saves concorrentes | Valores não finitos, parcelas inválidas ou operações duplicadas | Validação nos drafts e na fronteira de escrita; save/remove respeitam carregamento e conclusão. `Drafts`, `ViewModels`, repositório. |
| Parcelas atravessando anos ou agrupadas na data original | Meses futuros podiam faltar ou mostrar cabeçalhos de outro mês | Cálculo de deslocamento em meses, projeção da data de cobrança e calendário gregoriano explícito. `Transaction.swift`, `CashlyRepository+Queries.swift`, `TransactionScreen.swift`. |
| Totais de canceladas e totais inconsistentes ao compartilhar | Valores financeiros e texto exportado divergiam | Canceladas contribuem zero; totais sem filtro usam a participação inteira, e totais mensais usam a parcela. Compartilhamento segue o mesmo critério. `Transaction.swift`, `CashlyRepository+Queries.swift`. |
| Status geral deduzido do primeiro participante | Cancelar a participação de uma pessoa podia cancelar a despesa inteira; a ordem dos participantes alterava o resultado | Status geral editável e independente dos status individuais; salvar preserva a escolha do usuário. `TransactionViewModel.swift`, `AddTransactionScreen.swift`. |
| Bindings de participantes por índice | Remover uma linha podia editar outra pessoa ou acessar um índice inválido | Binding resolve o participante por ID, preservando a identidade dos demais. `AddTransactionScreen.swift`. |
| Seleções baseadas na igualdade de todo o DTO | Editar nome/cor podia deixar seleção antiga, marcar duplicados ou perder o item | Menu seleciona por ID; seleções visuais e de transações são reconciliadas após carga. `CashlyMenuSelectionView.swift`, `HomeScreen.swift`, `TransactionScreen.swift`. |
| Seletor de mês com estado separado da data | “Hoje”/“Limpar” podiam deixar mês e ano anteriores no picker | Bindings derivados diretamente da data de filtro. `FilterItemView.swift`. |
| Cadastro aberto de dentro de outro formulário | Opções de categorias/orçamentos não acompanhavam o novo registro | Atualização das opções quando os catálogos compartilhados mudam, sem apagar outros campos. `BudgetViewModel.swift`, `TransactionViewModel.swift`, telas correspondentes. |
| Tela inicial sem ação para começar | Banco vazio não oferecia o cadastro do primeiro usuário na Home | Cards de usuário, categoria e orçamento na Home. `HomeScreen.swift`. |
| Usuário atual salvo como cópia inteira | Seleção persistida podia continuar com dados antigos após editar o usuário | Persistência do ID e resolução contra registros atuais; leitura da seleção legada. `MainViewModel+Operations.swift`. |
| Falha de inicialização encerrando o app | Usuário não tinha forma de recuperar a abertura | Bootstrap com erro visível e botão de nova tentativa. `CashlyApp.swift`. |
| CloudKit no simulador sem capabilities assinadas | Processo encerrava por ausência de entitlement | Simulador usa armazenamento local real com sincronização desativada; dispositivo mantém CloudKit. `CashlyApp.swift`. |
| Recursos/previews com force unwrap | Recurso ausente ou fixture vazia derrubava preview | Leitura com erro/fallback; fixtures determinísticas e normalização dos dados históricos de exemplo. `CashlyResourceFile.swift`, `CashlyMock`. |
| Previsões compartilhadas ou aplicadas depois de editar manualmente | Sugestão de outro usuário ou uma entrada anterior podia alterar o formulário | Modelos por usuário; cancelamento/debounce e controle de previsão automática. A classificação retorna ID da categoria. `LocalIntelligenceService.swift`, `IntelligenceViewModel.swift`, `AddTransactionScreen.swift`. |

## Segunda etapa: escala e qualidade

O plano em `execution-plan.md` foi implementado no working tree, sem commit/push. As mudanças atacam as limitações identificadas na primeira revisão:

| Achado | Correção |
| --- | --- |
| Schema sem evolução explícita | V1 congelado, V2 e migração leve aditiva; os campos Double antigos são preservados. |
| Dinheiro em Double | Money em centavos BRL, overflow explícito e distribuição determinística entre participantes e parcelas. |
| Usuário global | Contexto imutável de usuário nas factories/gateways; a preferência só decide a abertura da próxima janela. |
| Histórico completo na UI | Catálogos por usuário/período, consultas por ID, lista de 50 itens por cursor e agregação em lotes de 500. |
| Filtros e navegação com cópias antigas | Filtros são convertidos para IDs; rotas transportam IDs e seeds; destinos resolvem o registro atual. |
| Importações remotas sem atualização | Hub de invalidação, stream coalescido e nova preparação após mudanças remotas. |
| Orçamentos concorrentes | Conflitos por usuário/categoria/mês; escolha explícita; valores originais preservados como aliases; resolução concorrente por timestamp/token. |
| Referências incompletas | Registros incompletos ficam preservados e fora dos totais, com aviso explícito; treino aguarda referências completas. |
| Tags dependentes da descrição | tagIDs persistidos, seleção explícita e texto apenas como sugestão por palavras/frases. |
| Modelos de inteligência antigos | Fingerprint dos inputs efetivos, dados de treino próprios, critérios de suficiência, modelo desatualizado visível e previsão suspensa. |
| Mocks no app | JSONs em CashlyMock e canvas em CashlyPreview, sem dependência da UI de produção nesses módulos. |
| Tarefas de animação antigas | Tasks vinculadas à seleção e canceláveis; animações de saldo respeitam Reduce Motion; labels de salvar explícitas. |
| Sem evidência de desempenho | CashlyAudit, signposts, logs técnicos, script de build e workflow de compilação. |

Também foram corrigidos problemas encontrados durante a execução: guardas em lote que consultavam outras contas locais, save de tag parcialmente aplicado em caso de erro, aliases circulares, associações removidas silenciosamente no formulário, ids duplicados em transações, resposta de seleção de usuário fora de ordem e previsões aplicadas depois de mudar a revisão.

Os gráficos e a seleção de seus valores também passaram a usar IDs; tags ou categorias com o mesmo nome não compartilham o eixo nem selecionam o valor de outro registro. O cabeçalho de parcelas mostra a faixa real de centavos, e os saldos subtraem unidades inteiras antes de converter para apresentação.

Os dados de terceiros visíveis no diretório são os usuários disponíveis para compartilhar despesas. As transações e os catálogos financeiros são delimitados pelo usuário da janela. Registros legados ainda sem referência suficiente para descobrir o proprietário produzem somente um aviso de incompletude.

## Pontos restantes por impacto

### [P1] Validar migração real e sincronização assinada antes de distribuir

**Local:** `CashlySchemaV1.swift`, `CashlySchema.swift`, `CashlyRepository+Normalization.swift`, `CashlyRepository+Conflicts.swift` e `CashlyChangeHub.swift`.

O banco legado sintético preservou entidades, valores, participantes e tags. Isso não substitui um banco de uma versão distribuída nem confirma a identidade de todas as variantes históricas do schema. A importação CloudKit também precisa de dispositivos assinados: o plano leve resolve o schema local, enquanto os campos novos dependem da disponibilidade do schema CloudKit no ambiente de produção.

A resolução concorrente escolhe timestamp e token, preserva os registros e converge no diagnóstico local. O timestamp depende do relógio do dispositivo; uma escolha feita mais tarde no tempo real pode perder para um aparelho com relógio adiantado. A política é determinística, mas precisa ser aceita como comportamento do produto. Registros sem metadados de uma resolução permanecem ativos e pedem uma nova escolha.

**Próxima ação:** executar o roteiro de aparelhos de `validation.md`; auditar a cópia de um banco real; verificar/implantar a evolução do schema CloudKit pelo fluxo normal de distribuição. Não apagar nem recriar o banco quando a abertura falhar.

### [P2] Agregação e primeira revisão ainda dependem do volume

**Local:** `CashlyRepository+Queries.swift` (`overview` e `datasetRevision`).

A lista e os detalhes são limitados e indexados. O painel precisa somar o período inteiro e a primeira revisão do treino precisa ler os inputs de todo o histórico do usuário. Isso ainda custa O(n); os batches limitam o material de cada consulta, mas o processamento continua compartilhando o actor de armazenamento. Grandes leituras podem atrasar outras operações nesse actor.

**Próxima ação, se os volumes medidos fizerem parte do uso esperado:** projeções mensais incrementais, revisão persistida e agenda de reconciliação para mudanças remotas. A projeção deve poder ser reconstruída a partir dos registros originais e respeitar tags, parcelas, status e participação. Não armazenar um total que não possa ser auditado.

### [P2] Clientes de versões diferentes precisam de uma política de suporte

**Local:** `CashlyRepository+Normalization.swift` e `datasetRevision`.

A preparação detecta mudanças nos campos legados de valor, data e parcelas. O fingerprint inclui descrição, status, relações, valores de participantes e tags efetivas, para perceber importações relacionadas posteriores. Ainda é necessário verificar o comportamento de um cliente antigo escrevendo durante a convivência com V2, inclusive exclusões e campos que o cliente antigo desconhece.

**Próxima ação:** definir se versões antigas poderão escrever depois da atualização. Verificar a combinação nos aparelhos ou estabelecer atualização mínima antes de ampliar o rollout.

### [P3] Completar localização, acessibilidade e restauração

A interface mantém textos em inglês e português; a etapa implementou as mensagens de integridade, mas ainda falta um String Catalog completo, pluralização e interpolação localizável. Acessibilidade deve ser exercitada com VoiceOver e Dynamic Type, sobretudo nos gráficos e seletores de ícones. As rotas pequenas permitem evoluir para deep links e restauração, mas esses fluxos não foram implementados nesta entrega.

### [P3] Avaliar a qualidade das sugestões com dados representativos

Revisão e critérios de suficiência evitam usar um modelo antigo ou sem dados mínimos. Não demonstram precisão preditiva. A média considera meses registrados e não interpreta ausência de lançamentos como gasto zero. O classificador local continua sendo Naive Bayes, sem conversão dos modelos CreateML antigos.

**Próxima ação:** definir o que representa um mês completo e medir qualidade por usuário/categoria antes de apresentar confiança ou automatizar escolhas financeiras.

## Evidências

O roteiro, resultados de migração, diagnósticos de integridade, números de desempenho e limites estão em `validation.md`. Os arquivos de testes não foram alterados ou executados. A compilação local não prova comportamento em aparelho físico, iCloud ou visionOS. O workflow ainda precisa ser executado no GitHub após o envio das alterações.
