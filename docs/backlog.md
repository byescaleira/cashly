# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md).

## Antes de distribuir

- **[P1] Validar CloudKit em dois aparelhos assinados:** offline e reconexão, referências que chegam em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários. Só dá para fazer com dois aparelhos (fica com o usuário); o lado automático está coberto: `scripts/audit.sh`, os `ScenarioTests` e, desde 12/10/2026, a resolução de conflito usa um carimbo monotônico (`max(agora, último visto + 1)`), então uma escolha feita depois de ver a anterior vence mesmo com o relógio atrasado.

## Desempenho e dados

- **[P2] Agregação proporcional ao volume.** Lista e detalhe são paginados e indexados, mas o resumo do período e a revisão do treino leem tudo, no mesmo actor das gravações. Medição anterior: 50 mil transações no mesmo mês levaram 12,1 s no resumo. Se esse volume for requisito, criar projeções mensais reconstruíveis e revisão persistida.
- **[P2] Competência depende do fuso do aparelho.** Separar instante, data civil, competência, vencimento e pagamento; persistir a competência escolhida.
- **[P2] Responsabilidades sobrepostas.** `Participant` aponta para `User`, que também é perfil financeiro; não há pagador, vencimento ou liquidação parcial. Proposta: `FinancialProfile`, `Counterparty`, `ExpenseAllocation`, `Obligation`, `Settlement`.
- **[P2] Fonte de verdade por associação.** Transação e participante guardam referências nos dois sentidos, e valores coexistem em quatro campos. Separar dados canônicos, legado de migração e projeções.
- **[P2] Atualização duplicada após salvar.** `.editorLifecycle` recarrega a sessão e o `CashlyChangeHub` também avisa; centralizar o refresh.
- **[P3] Múltiplas moedas.** O app tem uma moeda escolhida nos Ajustes, e cada registro grava a moeda em que foi salvo, mas os totais somam tudo sem conversão. Se contas em moedas diferentes entrarem no escopo, incluir a moeda no `Money` e tratar câmbio como operação explícita.

## Inteligência e integrações

- **[P2] Separar capacidades de inteligência.** Interpretação de texto, sugestão de categoria, explicação e previsão estatística precisam de contratos próprios antes de entrar Foundation Models. O serviço atual (médias e Naive Bayes) continua como implementação estatística.
- **[P2] Serviços fora da janela.** App Intents rodam sem tela; o bootstrap precisa de uma raiz de composição compartilhada, com perfil e conta como parâmetros explícitos.
- **[P3] Testes do StoreKit hospedados pelo app.** O `SKTestSession` falha nos testes do pacote (`xctest` não é um app instalado; `storekitd` responde `SKServiceErrorDomain 2`). Para exercitar o `Cashly.storekit` de verdade (compra, reembolso, expiração), criar um alvo de testes no `Cashly.xcodeproj` com o app como hospedeiro.
- **[P3] Sequência durante a pausa do Pro.** Sem assinatura a Jornada pausa, mas o motor continua contando os dias sem registro como perdidos; para "nada se perde" de verdade, o `GameSnapshot` precisa receber os períodos sem assinatura e tratá-los como cobertos.
- **[P3] Jornada no backup.** Os eventos da Jornada (`GameEventEntity`) sincronizam pelo iCloud, mas não entram no arquivo de backup; apagar tudo e restaurar zera dias acompanhados e desafios. O XP de transações, orçamentos e meses volta, porque é recalculado dos dados.
- **[P2] Ligar a inteligência.** A flag `intelligence` esconde sugestão de valor, de categoria e a tela de treino. Antes de ligar por padrão: treino automático (hoje é manual nos Ajustes), estado vazio e explicação na primeira sugestão, e a medição de qualidade abaixo.
- **[P3] Qualidade das sugestões.** Medir precisão por usuário e categoria antes de mostrar confiança ou automatizar escolhas.

## Produto

- **Configuração da distribuição.** Preencher no `Info.plist` as chaves de links (`CashlyAppStoreID`, `CashlySupportEmail`, `CashlyHelpURL`, `CashlyPrivacyURL`, `CashlyTermsURL`). Atualizar `ReleaseNote.current` a cada versão.
- **Integrações, assinatura e novas features.** Planejadas por fase em [roadmap.md](roadmap.md). Antes de App Intents e widgets, resolver "Serviços fora da janela" acima. Servidor MCP para o Claude Code continua como ideia futura.
- **[P3] Acessibilidade e restauração.** Dynamic Type conferido no iPhone até o tamanho de acessibilidade AX3; falta VoiceOver, principalmente gráficos e seletores de ícones. Rotas pequenas permitem deep links e restauração.
- **[P3] Seletor de mês além do orçamento.** O `MonthPicker` novo só é usado no editor de orçamento; avaliar o filtro de período (`FilterMenu`) e a escolha de mês das telas de Metas com o mesmo componente.
- **Ações de retry** nos editores quando a carga inicial falha (hoje é preciso fechar e abrir).

## Verificação visual pendente

- Ajustes › Aparência no Mac (`Form` agrupado, sem ícones) e no visionOS: só builds conferidos; as miniaturas de tema ainda não foram vistas fora do iPhone e do iPad. A troca de ícone com falha mostra o alerta pela página Aparência, inclusive com a galeria aberta por cima.
- iPhone em paisagem e app no Mac: só builds conferidos.
- Campo de valor muito grande (13 dígitos) corta o "R$" na borda.
- iPad de 11" em retrato: a barra de abas tem largura limitada pelo sistema; com Ajustes, a Buscar fica atrás da seta de rolagem.
- Folha lateral na horizontal: conferida com a posição forçada; falta girar um iPad de verdade.
- Histórico: o total do topo não tem filtro de tipo (gasto ou entrada); se o filtro ganhar tipo, a seção já troca para "Recebido" quando só há entradas.

## Qualidade de código

- Funções grandes nas camadas de dados e domínio (`CashlyStore+Normalization`, `TransactionAllocation`, `LocalIntelligenceService`): avaliar as regras `function_body_length` e `cyclomatic_complexity` do SwiftLint quando essas áreas forem tocadas, com testes cobrindo antes.
