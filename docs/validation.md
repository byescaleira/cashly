# Diagnóstico de migração e escala

Executado em 04/10/2026. Estes comandos inspecionam o armazenamento, compilam e medem o código. Nenhum arquivo de testes foi alterado e nenhuma suíte de testes foi executada.

## Ferramentas reproduzíveis

```sh
# Use DEVELOPER_DIR para escolher o Xcode instalado.
scripts/build.sh Debug
scripts/build.sh Release

swift build -c release --package-path CashlyKit --product CashlyAudit
CashlyKit/.build/release/CashlyAudit create-legacy /tmp/cashly-legacy/legacy.store
CashlyKit/.build/release/CashlyAudit audit /tmp/cashly-legacy/legacy.store
CashlyKit/.build/release/CashlyAudit scenarios
CashlyKit/.build/release/CashlyAudit preview
CashlyKit/.build/release/CashlyAudit benchmark 1000
CashlyKit/.build/release/CashlyAudit benchmark 10000
CashlyKit/.build/release/CashlyAudit benchmark 100000
```

`audit` copia o arquivo SQLite e os sidecars WAL/SHM para outra pasta antes de abrir o schema novo. Feche a instalação de origem antes de copiar um banco real. Esse comando pode imprimir IDs e totais; o relatório de um banco real deve permanecer local. `profile` aceita somente um arquivo chamado `benchmark.store`, produzido pela ferramenta. Os bancos sintéticos são criados em pastas temporárias próprias; não substituem o banco do app.

## Migração

O diagnóstico criou um armazenamento **sem versionamento**, com os seis modelos congelados de V1, reproduzindo o layout anterior. A abertura com V2 e o plano de migração preservou:

| Entidade | Antes | Depois |
| --- | ---: | ---: |
| Usuários | 2 | 2 |
| Categorias | 1 | 1 |
| Orçamentos | 1 | 1 |
| Tags | 1 | 1 |
| Transações | 1 | 1 |
| Participantes | 1 | 1 |

A transação de R$ 100,01 passou para 10001 centavos. A divisão igual preservou 5001 centavos do responsável e 5000 do participante. As três parcelas do responsável somaram 5001 centavos. A tag legada foi materializada por ID. O outro usuário recebeu um catálogo próprio, sem as transações do responsável. Não houve referências pendentes nesse banco.

Uma cópia do banco vazio da instalação anterior do simulador também abriu. O diagnóstico macOS mostrou avisos de versões diferentes de CoreData entre o simulador iOS 27 e o host; a abertura no próprio simulador é a verificação da mesma plataforma. Esse banco vazio **não valida histórico real**.

## Diagnósticos de integridade

- Renomear a tag preservou o gasto associado por ID e alterou a revisão do treinamento.
- Excluir a tag removeu suas referências das transações, sem deixá-las incompletas.
- A divisão de um centavo entre dois participantes com 50% atribuiu o centavo ao menor ID, sem criar um total de dois centavos.
- Duas instâncias de MainViewModel mantiveram usuários diferentes após recarregar a primeira; a segunda continuou sem transações próprias.
- Duas resoluções de orçamento com aliases circulares convergiram para a escolha com maior timestamp/token. Os registros e seus valores foram preservados.
- Um histórico de uma transação foi recusado para treino. Um modelo treinado retornou o ID da categoria; a mesma solicitação com revisão diferente retornou vazio.
- O seed dos previews carregou cinco usuários e dez transações.

## Medições

As bases sintéticas possuem dois usuários e todas as transações no mesmo mês; o usuário consultado possui metade do volume. Isso força um caso pesado de agregação mensal. Não há participantes nessa medição de volume; o diagnóstico de integridade cobre participantes separadamente. As medidas são uma execução local, sem isolamento de CPU ou estatística de percentis. Não são uma promessa de latência em um iPhone.

Durante a implementação, o cenário de 100 mil registros levou cerca de 18 segundos em Debug. O perfil mostrou custo no fingerprint por offset e na ordenação das consultas. A paginação por cursor e os índices reduziram esse cenário para cerca de 9 segundos em uma execução intermediária. O mapeamento também passou a detectar IDs duplicados e o fingerprint passou a incluir os registros relacionados efetivos, para detectar importações parciais do CloudKit.

Resultados finais em Release, com o diagnóstico recompilado e os três volumes executados em sequência:

| Registros na base | Registros do usuário/período | Dashboard completo | Detalhe por ID | Próxima página de 50 |
| ---: | ---: | ---: | ---: | ---: |
| 1.000 | 500 | 0,138 s | 1,42 ms | 27,4 ms |
| 10.000 | 5.000 | 1,127 s | 1,37 ms | 28,6 ms |
| 100.000 | 50.000 | 12,096 s | 1,33 ms | 45,7 ms |

Em cada volume, a soma correspondeu a `quantidade do usuário × 1001 centavos`, a primeira página teve 50 itens, a página seguinte não repetiu IDs, o detalhe de outro usuário ficou oculto e a resolução de conflito preservou um alias. O cenário de 100 mil ainda demonstra a necessidade de projeções incrementais se esse volume por período for uma exigência de produto. Os resultados intermediários de Debug e os finais de Release não são diretamente comparáveis: a versão final também valida identidades duplicadas e inclui relacionamentos no fingerprint.

## Compilações e abertura

- App iOS Debug e Release, para simulador: passaram.
- Scheme Interface para macOS: passou; corresponde ao módulo de UI, não a um aplicativo macOS completo.
- Target CashlyPreview: compilou; o seed independente também executou.
- Executável CashlyAudit em Release: compilou e executou migração, integridade, seed e volume.
- Abertura no simulador iOS 27: passou, com o banco existente preservado; a captura mostrou a Home, as tabs e o cadastro inicial, sem tela de falha de armazenamento. Não foram exercitados todos os fluxos pela interface.
- O bundle Release não contém os JSONs de mocks. Os fontes de testes permaneceram inalterados; `git diff --check` não indicou erros.

Logs detalhados desta sessão foram salvos localmente em `/tmp/cashly-scale`. As medições sintéticas e os comandos acima permitem reproduzir as evidências; não houve execução de CI remoto.

## Limites antes da distribuição

- Migrar uma cópia de banco **real**, com histórico de uma versão distribuída.
- Validar CloudKit em dois aparelhos assinados: offline/reconexão, chegada de referências em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários.
- Avaliar atualizações simultâneas de clientes antigos e novos antes de permitir essa combinação em produção.
- Exercitar criação/edição/exclusão, sheets, múltiplas janelas e acessibilidade pela interface. O controle nativo estava indisponível porque o Mac estava bloqueado.
- A agregação completa e o fingerprint continuam proporcionais ao histórico consultado. Se o produto precisar responder instantaneamente com dezenas de milhares de lançamentos no mesmo período, a próxima entrega será uma projeção incremental dos totais e revisão persistida, com reconciliação após importações. Paginação e índices resolvem a lista e o detalhe, mas não tornam uma soma de todo o histórico uma operação constante.

O workflow compila Debug e Release para iOS Simulator, macOS e visionOS Simulator. Ele foi preparado localmente; uma execução no GitHub depende de enviar essas alterações. A configuração usa a [imagem xcode-27 em preview](https://github.com/actions/runner-images/issues/14404) e [checkout](https://github.com/actions/checkout). Os builds locais usam Xcode 27 beta 6; a versão do compilador na imagem remota é registrada no job e a execução remota ainda está pendente.

O único warning final dos builds do app foi a extração de metadados de AppIntents ignorada por ausência desse framework. Não houve warnings de compilação dos fontes Swift.

## Entradas e schema V3 — 04/10/2026

Os comandos atuais de diagnóstico são `CashlyKit/.build/debug/CashlyAudit flows`, `audit <store>`, `preview` e `scenarios`, após compilar o produto CashlyAudit. `audit` sempre copia o store antes de abri-lo com o novo schema. Nenhum teste automatizado foi executado ou alterado.

- V1 → V3 e V2 → V3: preservados 2 usuários, 1 categoria, 1 orçamento, 1 tag, 1 transação e 1 participante; nenhuma referência pendente. Valor original e soma dos rateios: 10.001 centavos; parcelas do proprietário: 5.001 centavos.
- Fluxos sem orçamento: entradas 120.005 centavos, saídas do mês 13.335, resultado 106.670.
- Associação por categoria/competência: criar/mover/remover orçamento preservou os lançamentos. Parcelas de 10.001 centavos: 3.334 / 3.334 / 3.333.
- Consulta filtrada por tipo no banco, isolamento de perfil, edição de data e cancelamento: verificados pelo diagnóstico, sem novo filtro na interface.
- ViewModel: entrada criada e editada sem orçamento. Treinamento estatístico: entradas excluídas das amostras.
- Preview e diagnósticos anteriores de tags/conflitos: preservados.

Logs desta etapa: `/tmp/cashly-flow-diagnostic.log`, `/tmp/cashly-flow-v1-migration.log`, `/tmp/cashly-flow-v2-migration.log`, `/tmp/cashly-flow-preview.log`, `/tmp/cashly-flow-scenarios.log`. Os benchmarks anteriores são baseline da implementação anterior; não representam medições do novo schema V3.

Compilação final, Xcode 27 beta 6, sem assinatura: Production Debug e Release aprovados para iOS Simulator, macOS e visionOS Simulator. Logs: `/tmp/cashly-flow-debug.log` e `/tmp/cashly-flow-release.log`. `CashlyPreview` também compilou (`/tmp/cashly-flow-preview-build.log`). O único aviso de compilação do app foi a ausência de metadados App Intents por não haver essa integração no projeto.

O app atualizado foi instalado e abriu no simulador iOS 27 mantendo o sandbox; o store anterior foi copiado para `/tmp/cashly-flow-simulator-before-upgrade`. Captura: `/tmp/cashly-flow-launch.png`, com tela inicial vazia sem falha de abertura. A criação/edição financeira foi exercitada pelo ViewModel no diagnóstico manual, não por cliques na UI. Sincronização CloudKit em dispositivos, Siri e geração Foundation Models não foram exercitadas.

## Correção do escopo de apresentação — 04/10/2026

Removidos o seletor de entrada/saída, o filtro de tipo, os novos totais do resumo, os rótulos e sinais da listagem e a legenda adicional de saídas. Foram restaurados os elementos de planejamento e a disposição anteriores ao trabalho do schema V3. As telas mantêm apenas as adaptações de contratos necessárias ao desacoplamento e as correções de compatibilidade entre plataformas. O formulário continua criando saídas por padrão; entradas permanecem suportadas no domínio, no banco e nos cálculos.

A comparação dos fontes de UI com o snapshot anterior à evolução financeira confirmou a remoção dessas mudanças visuais. Production Debug compilou novamente para iOS Simulator, macOS e visionOS Simulator com Xcode 27 beta 6, sem assinatura. Log: `/tmp/cashly-ui-scope-debug.log`. `git diff --check` passou. Não houve execução de testes nem nova validação por cliques na interface; os resultados Release acima antecedem esta correção.

## Formatação dos fontes — 04/10/2026

O app, os módulos em `CashlyKit/Sources` e o manifesto do pacote usam quatro espaços, com configuração em `.swift-format` e suporte aos editores por `.editorconfig`. `scripts/format.sh` aplica o formatter da Apple; `scripts/format.sh --check` faz a verificação estrita. O workflow verifica o padrão antes da compilação. Os testes continuam fora do escopo do comando.

A verificação de formatação e `git diff --check` passaram. Production Debug compilou para iOS Simulator, macOS e visionOS Simulator; log: `/tmp/cashly-original-visual-debug.log`. O catálogo visual mantém os 100 avatares e as cinco ilustrações originais, idênticos ao backup, e a tipografia anterior. Nenhum novo ícone foi configurado no app.

## Lint — 04/10/2026

`scripts/lint.sh` verificou formatação e 24 regras do SwiftLint 0.65.1 em 126 arquivos, com zero violações. A instalação local validou o SHA-256 da distribuição oficial; executável e cache ficam ignorados em `.tools`. Uma entrada isolada via stdin com unwrap forçado produziu o diagnóstico esperado e exit code 2, confirmando o bloqueio. O YAML e os scripts foram validados, e `git diff --check` passou.

Dois unwraps de datas no diagnóstico manual foram substituídos por guards que retornam erro explícito. `CashlyAudit` compilou após essa alteração. Logs: `/tmp/cashly-lint-final.log` e `/tmp/cashly-lint-audit-build.log`. Nenhum teste automatizado foi executado ou alterado. O job de lint foi integrado como requisito dos builds; a execução remota do CI permanece pendente.

## Refactors dos padrões SwiftUI — 04/10/2026

Na branch `refactor/swiftui-ui-patterns`, os builds Debug de iOS Simulator, macOS e visionOS Simulator foram aprovados após as mudanças de composição, catálogos e cancelamento. CashlyPreview também compilou separadamente. O lint estrito passou em 128 arquivos com zero violações. Nenhuma suíte de testes foi executada ou alterada, e os previews não foram renderizados nesta rodada.

Logs: `/tmp/cashly-swiftui-patterns-debug.log`, `/tmp/cashly-swiftui-patterns-previews-build.log` e `/tmp/cashly-swiftui-patterns-lint.log`. Escopo e limites: [revisão SwiftUI](swiftui-patterns-review.md).

## Liquid Glass — 05/10/2026

Na branch `refactor/swiftui-ui-patterns`, os materiais foram separados entre controles nativos de vidro e indicadores de conteúdo com preenchimento simples. Builds Debug de iOS Simulator, macOS e visionOS Simulator e o build separado de CashlyPreview foram aprovados. O lint estrito passou em 129 arquivos, sem violações. Nenhuma suíte de testes foi executada ou alterada.

Um host descartável de previews foi compilado e renderizado no iPhone 17 Pro/iOS 27 sem abrir o banco do Cashly. As três variantes de materiais foram percorridas por controles nativos: claro, escuro e controles desativados. A renderização foi confirmada por screenshots e snapshots; os controles desativados não aparecem como alvos de toque. O launcher havia emitido um timeout de prontidão antes da renderização, e o browser não conectou ao stream. Host e espelhamento foram encerrados ao terminar. Acessibilidade pelas preferências reais do sistema e desempenho de GPU continuam sem medição.

Logs: `/tmp/cashly-liquid-glass-debug.log`, `/tmp/cashly-liquid-glass-previews.log`, `/tmp/cashly-liquid-glass-lint.log`. Screenshots: `/tmp/cashly-liquid-glass-visual/{light,dark,disabled}.jpg`. Escopo e limites: [revisão de materiais](liquid-glass-review.md).
