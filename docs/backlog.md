# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md).

## Antes de distribuir

- **[P1] Build de envio pelo Xcode Cloud (feito pelo usuário),** com o Xcode 27 final: o Xcode local é o 27.0 beta 6, e a App Store recusa builds feitos com beta. O Xcode Cloud só vê o que estiver no GitHub.
- **[P1] App Store Connect, o que falta.** Feito em 17/10/2026: textos da versão 1.0 (promocional, descrição, palavras-chave, URLs de suporte e marketing) nos 10 idiomas, nome e subtítulo por idioma, categorias Finanças e Produtividade, classificação 4+, URL de privacidade, respostas "Dados não coletados" salvas, notas de revisão e lançamento manual. Falta: (1) **contato da revisão** (nome, e-mail e telefone; sem eles "Sign-in required" não desmarca); (2) **Publish** das respostas de privacidade, que exige a declaração do usuário; (3) capturas, imagem de cabeçalho e App Preview (em produção); (4) **textos das 27 compras no app nos outros 8 idiomas**, que hoje só têm en-US e pt-BR: os textos do catálogo passam do limite de 45 caracteres do App Store Connect e precisam de versões curtas; sem eles a Apple mostra o inglês; (5) captura de revisão de cada compra e "Add for Review" junto com o build; Molduras (`cashly.avatar.frames`) e Sons (`cashly.sounds`) não vão; (6) a versão de tvOS aparece criada no app e não deve ser enviada; (7) status de trader no DSA (UE), decisão do usuário.
- **Nomes na loja:** o nome "Cashly" com ":" e benefício estava ocupado em vários idiomas; os aceitos estão em `docs/app-store/metadata.json` (en "Cashly: Expenses & Budget", pt-BR "Cashly: Gastos do Mês"). Os avisos de erro do App Store Connect chegam um salvamento atrasado; conferir recarregando a página.

- **[P1] Publicar o schema no CloudKit de produção.** Em 17/10/2026 a produção estava vazia (nada publicado desde o V1) e o desenvolvimento não tinha `CaptureEntity`, `MerchantMemoryEntity` nem os campos do V6. O schema de desenvolvimento foi completado rodando no iPhone o build de Debug com `-CashlyInitializeCloudSchema` (`initializeCloudKitSchema()` num banco temporário). Falta o usuário clicar em Deploy Schema Changes no CloudKit Console (14 tipos, só criações); a publicação é irreversível e ficou com ele. O tipo `FeatureFlag` foi criado e publicado em 18/10/2026; as flags remotas agora se editam pelo admin (`docs/admin.md`).
- **[P1] Testar moedas no iPhone físico** (etapa e de [currency.md](currency.md)): a instalação migra o banco do aparelho para o V6, e as branches que ainda estão no V5 deixam de abrir esse banco. Por decisão do usuário em 15/10/2026, o teste fica para depois do merge.

- **[P1] Validar CloudKit em dois aparelhos assinados:** offline e reconexão, referências que chegam em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários. Só dá para fazer com dois aparelhos (fica com o usuário); o lado automático está coberto: `scripts/audit.sh`, os `ScenarioTests` e, desde 12/10/2026, a resolução de conflito usa um carimbo monotônico (`max(agora, último visto + 1)`), então uma escolha feita depois de ver a anterior vence mesmo com o relógio atrasado.

- **[P2] Mac e Apple Vision Pro na 1.x.** Capturas reais do app nativo (macOS 27 e simulador ou aparelho de visionOS; `python3 docs/app-store/media/source/compose.py mac vision`), revisão visual dessas plataformas e envio das versões de macOS e visionOS que já existem no App Store Connect. Ao lançar, religar nada: as versões nativas substituem a de iPad.

## Desempenho e dados

- **[P3] Adiar conta em outra moeda.** `IntentActions.postpone` muda a data e mantém a cotação da data original. Buscar a cotação da nova data ou avisar.
- **[P3] Orçamento estimado sem "≈" na linha.** Metas mostra o aviso de estimativa no rodapé do mês, mas as linhas de orçamento não marcam qual valor foi convertido.

- **[P2] Agregação proporcional ao volume.** Lista e detalhe são paginados e indexados, mas o resumo do período e o retrato do motor leem tudo, no mesmo actor das gravações. Medição anterior: 50 mil transações no mesmo mês levaram 12,1 s no resumo. Se esse volume for requisito, criar projeções mensais reconstruíveis e revisão persistida.
- **[P2] Competência depende do fuso do aparelho.** Separar instante, data civil, competência, vencimento e pagamento; persistir a competência escolhida.
- **[P2] Responsabilidades sobrepostas.** `Participant` aponta para `User`, que também é perfil financeiro; não há pagador, vencimento ou liquidação parcial. Proposta: `FinancialProfile`, `Counterparty`, `ExpenseAllocation`, `Obligation`, `Settlement`.
- **[P2] Fonte de verdade por associação.** Transação e participante guardam referências nos dois sentidos, e valores coexistem em quatro campos. Separar dados canônicos, legado de migração e projeções.
- **[P2] Resumo de Dados e Backup lê o banco inteiro.** `DataModel.refreshInventory()` usa `backup.export()` para contar registros, período e tamanho a cada visita à página. Em 15/10/2026 isso, somado à recarga a cada mudança do banco (sincronização do iCloud), fez a página piscar e travar no iPhone; a recarga passou a ser só ao abrir e ao trocar de perfil. Trocar por contagens no repositório e estimar o tamanho.
- **[P3] Data do arquivo de backup em UTC.** `BackupFolder.name(on:)` usa `.iso8601`, que formata em GMT; à noite no Brasil a cópia leva o dia seguinte no nome. As datas relativas da página usam o mesmo calendário GMT para não divergir do nome.
- **[P2] Atualização duplicada após salvar.** `.editorLifecycle` recarrega a sessão e o `CashlyChangeHub` também avisa; centralizar o refresh.

## Inteligência e integrações

- **[P2] Serviços fora da janela.** App Intents rodam sem tela; o bootstrap precisa de uma raiz de composição compartilhada, com perfil e conta como parâmetros explícitos.
- **[P3] Testes do StoreKit hospedados pelo app.** O `SKTestSession` falha nos testes do pacote (`xctest` não é um app instalado; `storekitd` responde `SKServiceErrorDomain 2`). Para exercitar o `Cashly.storekit` de verdade (compra, reembolso, expiração), criar um alvo de testes no `Cashly.xcodeproj` com o app como hospedeiro.
- **[P3] Sequência durante a pausa do Pro.** Sem assinatura a Jornada pausa, mas o motor continua contando os dias sem registro como perdidos; para "nada se perde" de verdade, o `GameSnapshot` precisa receber os períodos sem assinatura e tratá-los como cobertos.
- **[P3] Jornada no backup.** Os eventos da Jornada (`GameEventEntity`) sincronizam pelo iCloud, mas não entram no arquivo de backup; apagar tudo e restaurar zera dias acompanhados e desafios. O XP de transações, orçamentos e meses volta, porque é recalculado dos dados.
- **[P2] Ligar a inteligência.** A flag `intelligence` esconde a sugestão de valor do orçamento e a de categoria no editor. Elas já são calculadas do histórico, sem treino. Antes de ligar por padrão: explicação na primeira sugestão e a medição abaixo; desde a I4, embeddings de frase disputam com o Naive Bayes pela precisão nos dados da própria pessoa ([analytics.md](analytics.md)).
- **[P3] Previsão do mês com parcelas novas.** A `MonthPace` usa `max(agendado, típico)`: uma parcela nova perto do fim do mês esconde o gasto variável que ainda vem. Trocar por `parcelas agendadas + max(avulsas agendadas, típico sem parcelas)`; a chance de passar do planejado acompanha, porque gira em torno dela.
- **[P2] Conferir o Resumo do Cashly na tela.** Na rodada final de capturas: se o modelo do sistema escreve um texto que passa na validação com dados de exemplo (pt-BR e en), a entrada da seção com e sem Reduzir movimento, no iPhone e no iPad. Um "Ocultar" no Resumo fica como decisão do usuário.
- **[P3] Resumo semanal por notificação.** O texto do Resumo do Cashly é gerado com o app aberto; uma notificação semanal precisaria gerar em segundo plano (`BGAppRefreshTask` não garante horário) ou cair para um texto de modelo pronto. Decidir com o usuário qual dos dois.
- **[P3] Boosted trees na previsão.** O `MLBoostedTreeRegressor` (Create ML) ficou fora da I4: com o histórico de uma pessoa, os modelos estatísticos ganham no backtest. Entra no `Forecaster` como candidato quando houver meses suficientes para medir.
- **[P3] Qualidade das sugestões.** Medir precisão por usuário e categoria antes de mostrar confiança ou automatizar escolhas.

## Produto

- **[P3] Vitrine do Pro no Início com 13 argumentos.** Cada análise do Início tem um argumento; para quem não assina, a lista ficou longa. Decidir com o usuário se fica um argumento por pergunta (como está o mês, para onde vai, onde economizar, o que vem aí).
- **[P3] Reajuste de cobrança recorrente.** Acima de 15% a cobrança abre uma faixa nova e só reaparece depois de três meses no preço novo; detectar a continuação pela descrição e avisar do reajuste. Tolerar uma compra extra na mesma faixa (aceitar a faixa quando tirar uma única compra deixa os intervalos regulares).
- **A cada versão,** acrescentar um `Release` em `Release.all` (a tela Novidades destaca a versão instalada e lista as anteriores) e atualizar `docs/app-store/metadata.json` (novidades nos 10 idiomas).
- **Integrações, assinatura e novas features.** Planejadas por fase em [roadmap.md](roadmap.md). Antes de App Intents e widgets, resolver "Serviços fora da janela" acima. Servidor MCP para o Claude Code continua como ideia futura.
- **[P3] Acessibilidade e restauração.** Dynamic Type conferido no iPhone até o tamanho de acessibilidade AX3; falta VoiceOver, principalmente gráficos e seletores de ícones. Rotas pequenas permitem deep links e restauração.
- **[P3] Seletor de mês além do orçamento.** O `MonthPicker` novo só é usado no editor de orçamento; avaliar o filtro de período (`FilterMenu`) e a escolha de mês das telas de Metas com o mesmo componente.
- **[P2] Telas grandes e multiplataforma.** As rotas abrem num `.inspector` quando a janela comporta coluna e inspector (ver decisions.md, 15/10/2026); o visual foi aprovado e a regra já está no apple-sdd (adaptive-layout.md §7.2). Conferido no simulador do iPad 13" (em pé, deitado e girando com o inspector aberto, pelo `CashlyUITests`) e do 11" em pé. Falta rodar o `CashlyUITests` no Xcode Cloud nos destinos que o Mac de trabalho não roda (iPad 11" deitado, iPhone dobrável, Mac e Apple Vision Pro: o app de Mac pede macOS 27 e não há runtime de visionOS aqui) e conferir Split View e Stage Manager, que o teste não cobre.
- **Ações de retry** nos editores quando a carga inicial falha (hoje é preciso fechar e abrir).

## Widgets

- **[P2] Publicar o widget sem o resto.** Trocar a escolha reinicia o `.task(id: extrasKey)` inteiro do `MainScreen` (notificações, Spotlight, capturas e modelos); separar a publicação do snapshot.
- **[P3] Um orçamento por cópia.** Hoje a escolha é global. Com `AppIntentConfiguration` e opções lidas do snapshot, cada cópia poderia seguir uma categoria, com "a escolha do app" como padrão.
- **[P3] Modo discreto nos widgets.** Os widgets mostram valores mesmo com o modo discreto ligado.
- **[P3] Duas janelas, um snapshot.** Com perfis diferentes em duas janelas (iPad, Mac), a última publicação vence.

## Verificação visual pendente

- Ajustes gerais (raiz, Idioma, Moeda, Notificações, Privacidade e Jornada): só builds conferidos; falta ver no iPhone, no iPad em colunas, no Mac (sem busca, `Form`) e no visionOS. Trocar o idioma recria as abas (`.id(locale)` na `MainScreen`), o que deve voltar à raiz dos Ajustes: conferir no aparelho e, se voltar, manter a página Idioma aberta na troca. A janela de Ajustes do Mac não recebe sessão, finanças nem loja: o cabeçalho mostra só "Cashly" e a sincronização.
- Ajustes › Widgets no Mac (`Form` agrupado, sem Tela Bloqueada nem Controles) e no visionOS: só builds conferidos.
- Ajustes › Aparência no Mac (`Form` agrupado, sem ícones) e no visionOS: só builds conferidos; as miniaturas de tema ainda não foram vistas fora do iPhone e do iPad. A troca de ícone com falha mostra o alerta pela página Aparência, inclusive com a galeria aberta por cima.
- iPhone em paisagem e app no Mac: só builds conferidos.
- Campo de valor muito grande (13 dígitos) corta o "R$" na borda.
- iPad de 11" em retrato: a barra de abas tem largura limitada pelo sistema; com Ajustes, a Buscar fica atrás da seta de rolagem.
- Folha lateral na horizontal: conferida com a posição forçada; falta girar um iPad de verdade.
- Ajustes › Sobre: herói, números e compartilhar só conferidos em build; falta ver no iPhone (inclusive tamanhos de acessibilidade, com os quadros em uma coluna), no iPad em colunas e no Mac.
- Histórico: o total do topo não tem filtro de tipo (gasto ou entrada); se o filtro ganhar tipo, a seção já troca para "Recebido" quando só há entradas.

- Ajustes › iCloud, Dados e Backup (com o guia de importar e o de apagar tudo), Novidades e Desenvolvedor: só builds conferidos; falta ver no iPhone, no iPad, no Mac (`Form` agrupado) e no visionOS, inclusive o vermelho do botão "Apagar todos os dados" na segunda etapa e o seletor de arquivo aberto de dentro da folha de apagar.

## Qualidade de código

- `SettingsModel.cloudFooter` e `lastSyncText` ficaram usados só pelos testes depois que a página iCloud passou para `SettingsModel+Cloud`; remover junto com os testes quando ninguém mais estiver mexendo em `SettingsModel.swift`.

- Funções grandes nas camadas de dados e domínio (`CashlyStore+Normalization`, `TransactionAllocation`): avaliar as regras `function_body_length` e `cyclomatic_complexity` do SwiftLint quando essas áreas forem tocadas, com testes cobrindo antes.

## Social (perfil compartilhado)

Fase 1 entregue em 18/10/2026 (ver [social.md](social.md)). Próximas fases e limites conhecidos:

- **[P1] Fase 2, juntos no dia a dia:** "quem lançou" em cada transação, Jornada do perfil compartilhado (sincronizar `GameEvent` com deduplicação dos créditos únicos e sem levar meses de Pro de uma pessoa para outra), aviso quando outra pessoa registra.
- **[P1] Validação em duas contas iCloud, o que falta:** aceite, dados do dono para o convidado, edição do convidado até o servidor e sair foram verificados em 19/10/2026. Faltam offline e reconexão, conflito de edição simultânea, remover pessoa, parar de compartilhar e apagar para todos, de preferência em dois aparelhos físicos (com push).
- **[P1] Busca sem push:** sem push o `CKSyncEngine` não pergunta ao banco quais zonas mudaram. Plano B: ao abrir e ao puxar para atualizar, ler as zonas conhecidas direto (`recordZoneChanges` com o token guardado por zona) e entregar ao motor.
- **[P2] Fase 3:** transformar um perfil pessoal em compartilhado (copiar para a zona e apagar do banco principal registro a registro).
- **[P2] Campos novos nos registros:** um aparelho com versão antiga não reenvia o que recebe, mas, se editar a linha, envia sem os campos que não conhece. Preservar as chaves desconhecidas do payload do servidor antes da fase 2 mudar o formato.
- **[P2] Desempenho da comparação:** cada gravação local recodifica e calcula o SHA-256 de todas as linhas dos perfis compartilhados, e o estado (com os campos de sistema de cada registro) é regravado inteiro. Limitar ao perfil alterado (o `CashlyChangeHub` descarta o `userID`) e guardar o estado por zona.
- **[P2] Participantes da divisão entre pessoas:** hoje escondidos num perfil compartilhado; voltam na fase 2 com "quem lançou".
- **[P3] Backup e "apagar tudo"** dos perfis compartilhados.
- **[P3] Desenho C1 (cobrança com Pix)** e, se fizer sentido, desenho B (cartão de progresso para amigos).

