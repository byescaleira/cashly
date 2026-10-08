# Plano de execução: escala e qualidade

Autorizado em 04/10/2026. Parte da reestruturação MVVM que já está no working tree; essas alterações serão preservadas. Testes automatizados permanecem fora desta etapa.

| Etapa | Entrega | Evidência de conclusão | Estado |
| --- | --- | --- | --- |
| 1 | Schema legado congelado, schema atual versionado e migração aditiva | Abrir cópia de armazenamento legado e comparar contagens/valores; sem apagar banco em caso de erro | Implementada; migração sintética verificada |
| 2 | Money e alocação determinística de centavos no domínio | Persistência em unidades menores; soma das participações e parcelas igual ao original | Implementada e diagnosticada |
| 3 | Contexto explícito de usuário por janela | Factories/contratos delimitados por usuário; seleção de uma janela não muda as demais | Implementada; duas instâncias verificadas |
| 4 | Consultas por ID/período e paginação estável | Dashboard separado da lista paginada; abertura de detalhe sem snapshot global | Implementada e medida; agregação ainda O(n) |
| 5 | Invalidação de dados e reconciliação de conflitos | Escritas idempotentes, referências pendentes sinalizadas, atualização após importação remota | Implementada e diagnosticada localmente; CloudKit físico pendente |
| 6 | Tags persistidas por ID | Associação explícita, preservada após renomear; classificação por descrição somente como sugestão | Implementada e diagnosticada |
| 7 | Inteligência com revisão de treinamento | Histórico próprio para treino; modelos desatualizados identificados e sugestões antigas suspensas | Implementada e diagnosticada |
| 8 | Rotas pequenas e recursos de preview separados | Rotas por IDs/seeds; mocks fora dos recursos de produção | Implementada; módulo e seed verificados |
| 9 | Observabilidade e builds automatizados | Logs técnicos sem conteúdo financeiro, signposts e comandos de build reproduzíveis | Implementada; CI remoto pendente |
| 10 | Verificação final e documentação atualizada | Builds Debug/Release/macOS, abertura do app e relatório de migração/performance | Compilações e diagnósticos locais concluídos; validações físicas pendentes |

## Decisões de implementação

- Dinheiro usa centavos inteiros e uma moeda explícita. A migração mantém os campos antigos para compatibilidade e acrescenta a representação monetária nova.
- A seleção de usuário pertence à janela. A preferência persistida só define o usuário inicial da próxima abertura.
- Consultas são delimitadas pelo usuário e pelo período, e a lista usa cursor com desempate por ID.
- Conflitos de orçamento usam a chave lógica usuário/categoria/mês. Valores conflitantes não serão descartados silenciosamente; a experiência deve pedir resolução quando necessário.
- A validação de iCloud depende de dispositivos assinados. A validação de banco real depende de uma instalação anterior disponível; a implementação e o diagnóstico de migração continuarão em paralelo.

## Limites de verificação

Compilação, auditoria do schema, diagnósticos de migração e medições de desempenho não equivalem à verificação de todos os fluxos em dispositivos reais. O relatório final distinguirá o que foi executado do que ainda depender de dados ou aparelhos disponíveis.

## Resultado e próximos passos

A implementação e os diagnósticos locais estão em `validation.md`; o review final está em `code-review.md`. O histórico remoto permaneceu intacto e as alterações desta entrega estão locais, sem commit/push.

Antes da distribuição, executar a migração com uma cópia de banco real e o roteiro de CloudKit em aparelhos assinados. Para escala extrema por período, priorizar projeções incrementais/revisão persistida: no diagnóstico de 100 mil registros, lista e detalhes foram rápidos, mas o dashboard completo consultou 50 mil transações e levou 12,1 segundos. Localização completa, avaliação preditiva e acessibilidade ampliada permanecem como próximas entregas de produto.

## Evolução autorizada: entradas e orçamento por período

Implementado: schema V3 com V1/V2 congelados; transações sem orçamento obrigatório; entrada/saída explícitas; comandos com IDs e Money; associação por perfil/categoria/competência; consultas e totais separados no domínio, sem novos controles ou indicadores na interface; estimativas restritas a saídas. Migrações e CRUD por ViewModel foram verificados com diagnósticos manuais. Os detalhes estão em [financial-flows.md](financial-flows.md). Integrações Apple, contas, obrigações e gamificação continuam propostas em [data-and-intelligence-review.md](data-and-intelligence-review.md).
