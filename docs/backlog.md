# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md).

## Antes de distribuir

- **[P1] Validar CloudKit em dois aparelhos assinados:** offline e reconexão, referências que chegam em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários. A resolução de conflito usa timestamp e token; um relógio adiantado pode vencer uma escolha feita depois.
- **[P1] Modo de divisão "Quem pagou".** `TransactionAllocation` atribui zero a todos os participantes nesse modo, mas a interface promete que os outros ficam devendo. Retirar a opção da criação ou modelar pagador e dívida; não converter registros antigos em divisão igual.

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
- **[P2] Eventos de negócio duráveis** antes de gamificação: o `CashlyChangeHub` só invalida a tela e pode descartar sinais.
- **[P3] Qualidade das sugestões.** Medir precisão por usuário e categoria antes de mostrar confiança ou automatizar escolhas.

## Produto

- **Configuração da distribuição.** Preencher no `Info.plist` as chaves de links (`CashlyAppStoreID`, `CashlySupportEmail`, `CashlyHelpURL`, `CashlyPrivacyURL`, `CashlyTermsURL`) e o `NSUbiquitousContainerName`, que ainda tem o texto de exemplo. Atualizar `ReleaseNote.current` a cada versão.
- **Integrações, assinatura e novas features.** Planejadas por fase em [roadmap.md](roadmap.md). Antes de App Intents e widgets, resolver "Serviços fora da janela" acima. Servidor MCP para o Claude Code continua como ideia futura.
- **Backup no iCloud Drive.** O backup automático é local; para guardar no iCloud Drive, configurar o container de documentos no `Info.plist`.
- **[P3] Acessibilidade e restauração.** Dynamic Type conferido no iPhone até o tamanho de acessibilidade AX3; falta VoiceOver, principalmente gráficos e seletores de ícones. Rotas pequenas permitem deep links e restauração.
- **Datas seguem o idioma do aparelho.** Com o aparelho em inglês, meses e dias da semana aparecem em inglês, enquanto o resto da interface está em português.
- **Ações de retry** nos editores quando a carga inicial falha (hoje é preciso fechar e abrir).

## Verificação visual pendente

- iPhone em paisagem e app no Mac: só builds conferidos.
- Campo de valor muito grande (13 dígitos) corta o "R$" na borda.
- iPad de 11" em retrato: a barra de abas tem largura limitada pelo sistema; com Ajustes, a Buscar fica atrás da seta de rolagem.
- Folha lateral na horizontal: conferida com a posição forçada; falta girar um iPad de verdade. Na lista de transações, "Adicionar" fica no menu "…".

## Qualidade de código

- Funções grandes nas camadas de dados e domínio (`CashlyStore+Normalization`, `TransactionAllocation`, `LocalIntelligenceService`): avaliar as regras `function_body_length` e `cyclomatic_complexity` do SwiftLint quando essas áreas forem tocadas, com testes cobrindo antes.
