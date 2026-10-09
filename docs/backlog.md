# Backlog

O que falta, por prioridade. Itens concluídos saem daqui; o motivo das decisões fica em [decisions.md](decisions.md).

## Antes de distribuir

- **[P1] Migrar uma cópia de banco real.** O `CashlyAudit check` migra um banco V1 sintético; isso não substitui o histórico de uma versão distribuída. Roteiro em [validation.md](validation.md). Nunca apagar nem recriar o banco quando a abertura falhar.
- **[P1] Validar CloudKit em dois aparelhos assinados:** offline e reconexão, referências que chegam em momentos diferentes, conflitos concorrentes, exclusões e troca de usuários. A resolução de conflito usa timestamp e token; um relógio adiantado pode vencer uma escolha feita depois.
- **[P1] Modo de divisão "Quem pagou".** `TransactionAllocation` atribui zero a todos os participantes nesse modo, mas a interface promete que os outros ficam devendo. Retirar a opção da criação ou modelar pagador e dívida; não converter registros antigos em divisão igual.
- **[P2] Política para versões antigas.** Definir se clientes antigos podem escrever depois da atualização e verificar a convivência com V2 (exclusões e campos desconhecidos), ou exigir versão mínima.

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

- **Fase 7: Ajustes (`FeatureSettings`).** Feito: tema, sincronização com iCloud (vale na próxima abertura) e estado da conta, dados (backup em JSON, importar e apagar tudo), ajuda e sobre. Falta:
  - preencher as chaves de links no `Info.plist` (App Store, e-mail de suporte, central de ajuda, privacidade, termos) e o `NSUbiquitousContainerName`, que ainda tem o texto de exemplo;
  - exportar transações em CSV para planilhas e backup automático periódico;
  - iCloud: última sincronização (eventos do CloudKit) e backup;
  - ícone do app (exige ícones alternativos no projeto);
  - novidades da versão;
  - integrações futuras: Calendário, servidor MCP para Claude Code, Atalhos, importador, App Intents/Siri, Foundation Models.
- **[P3] Acessibilidade e restauração.** Exercitar VoiceOver e Dynamic Type, principalmente gráficos e seletores de ícones; rotas pequenas permitem deep links e restauração.
- **Ações de retry** nos editores quando a carga inicial falha (hoje é preciso fechar e abrir).
- **Estado vazio na abertura.** Antes de carregar os usuários, o Início mostra "Nenhum usuário ainda" por um instante; mostrar carregamento até a primeira leitura.

## Verificação visual pendente

- iPhone em paisagem e app no Mac: só builds conferidos.
- Campo de valor muito grande (13 dígitos) corta o "R$" na borda.
- iPad de 11" em retrato: na lista de transações, "Adicionar" fica no menu "…" por falta de espaço ao lado das abas.

## Qualidade de código

- Funções grandes nas camadas de dados e domínio (`CashlyStore+Normalization`, `TransactionAllocation`, `LocalIntelligenceService`): avaliar as regras `function_body_length` e `cyclomatic_complexity` do SwiftLint quando essas áreas forem tocadas, com testes cobrindo antes.
