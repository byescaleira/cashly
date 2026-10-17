# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md).

## Antes de distribuir

- **[P1] Publicar o schema V6 no CloudKit de produção** (moeda paga e cotação da transação) no CloudKit Console antes de distribuir uma build com a branch de moedas.
- **[P1] Testar moedas no iPhone físico** (etapa e de [currency.md](currency.md)): a instalação migra o banco do aparelho para o V6, e as branches que ainda estão no V5 deixam de abrir esse banco. Por decisão do usuário em 15/10/2026, o teste fica para depois do merge.

- **[P1] Validar CloudKit em dois aparelhos assinados:** offline e reconexão, referências que chegam em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários. Só dá para fazer com dois aparelhos (fica com o usuário); o lado automático está coberto: `scripts/audit.sh`, os `ScenarioTests` e, desde 12/10/2026, a resolução de conflito usa um carimbo monotônico (`max(agora, último visto + 1)`), então uma escolha feita depois de ver a anterior vence mesmo com o relógio atrasado.

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
- **[P2] Ligar a inteligência.** A flag `intelligence` esconde a sugestão de valor do orçamento e a de categoria no editor. Elas já são calculadas do histórico, sem treino. Antes de ligar por padrão: explicação na primeira sugestão e a medição abaixo; a troca do Naive Bayes por embeddings vem na I4 de [analytics.md](analytics.md).
- **[P3] Qualidade das sugestões.** Medir precisão por usuário e categoria antes de mostrar confiança ou automatizar escolhas.

## Produto

- **[P3] Vitrine do Pro no Início com 13 argumentos.** Cada análise do Início tem um argumento; para quem não assina, a lista ficou longa. Decidir com o usuário se fica um argumento por pergunta (como está o mês, para onde vai, onde economizar, o que vem aí).
- **[P3] Reajuste de cobrança recorrente.** Acima de 15% a cobrança abre uma faixa nova e só reaparece depois de três meses no preço novo; detectar a continuação pela descrição e avisar do reajuste. Tolerar uma compra extra na mesma faixa (aceitar a faixa quando tirar uma única compra deixa os intervalos regulares).
- **Configuração da distribuição.** Preencher no `Info.plist` as chaves de links (`CashlyAppStoreID`, `CashlySupportEmail`, `CashlyHelpURL`, `CashlyPrivacyURL`, `CashlyTermsURL`, `CashlyWebsiteURL`). Sem elas, Ajustes › Sobre mostra só "Avaliar" (pelo `requestReview`) e "Novidades", e o compartilhar manda só o texto; o id 6821986667 do App Store Connect só deve entrar quando a página do app estiver no ar. A cada versão, acrescentar um `Release` em `Release.all` (a tela Novidades destaca a versão instalada e lista as anteriores).
- **Integrações, assinatura e novas features.** Planejadas por fase em [roadmap.md](roadmap.md). Antes de App Intents e widgets, resolver "Serviços fora da janela" acima. Servidor MCP para o Claude Code continua como ideia futura.
- **[P3] Acessibilidade e restauração.** Dynamic Type conferido no iPhone até o tamanho de acessibilidade AX3; falta VoiceOver, principalmente gráficos e seletores de ícones. Rotas pequenas permitem deep links e restauração.
- **[P3] Seletor de mês além do orçamento.** O `MonthPicker` novo só é usado no editor de orçamento; avaliar o filtro de período (`FilterMenu`) e a escolha de mês das telas de Metas com o mesmo componente.
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
