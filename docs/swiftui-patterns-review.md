# Revisão dos padrões SwiftUI

Branch: `refactor/swiftui-ui-patterns`.

O workspace já continha a reestruturação de domínio, persistência, MVVM, formatação e lint sem commits. Essas alterações foram preservadas ao criar a branch. O escopo abaixo descreve apenas o trabalho desta revisão; criar a branch não transforma as alterações anteriores em commits nem as isola em outra cópia física do workspace.

## Decisões de estrutura

| Responsabilidade | Propriedade e mecanismo |
| --- | --- |
| Persistência e serviço de inteligência | Raiz de composição; implementação isolada em CashlyData. |
| Perfil ativo, filtros e catálogos da janela | MainViewModel da CashlySession, compartilhado por Environment. |
| Seleção de seção, pilhas e modal | CashlyNavigation da janela; NavigationStack por seção e sheet(item:). |
| Mapear rotas e construir editores | CashlyRouteScreen, com factory delimitada pelo perfil. |
| Fechar a apresentação modal | CashlySheetScreen e dismiss do SwiftUI. |
| Rascunho do editor | ViewModel em State; Bindable apenas nos controles editáveis. |
| Usuários selecionados para divisão | Binding derivado dos participantes do rascunho. |
| Previsão exibida no início | State local em SpendingForecastSection; cálculo coordenado por IntelligenceViewModel. |

A separação em structs de View cria fronteiras de observação e composição sem introduzir interfaces ou ViewModels para cada seção visual. MVVM permanece para carregamento, validação e comandos de domínio. A arquitetura não utiliza AnyView nem serviços globais para coordenar as telas.

## Problemas corrigidos

1. **Participantes tinham duas fontes de estado.** O editor mantinha `selectedUsers` e `draft.participants`, sincronizados por onChange nos dois sentidos. Remover ou limpar a seleção podia disputar com uma sincronização pendente. O menu lê e altera o draft por Binding; swipe remove por ID. O ViewModel preserva IDs e informações dos participantes restantes e calcula as parcelas da divisão.
2. **A previsão não reagia ao desligamento do filtro de data.** A identidade da tarefa não incluía `isFilteringByDate`, embora o cálculo dependesse desse valor. O componente agora inclui esse critério e limpa o resultado ao começar uma nova solicitação. Categorias repetidas são consultadas uma única vez, evitando duplicar estimativas no mesmo período.
3. **A previsão ampliava o estado compartilhado.** Um único componente consumia `MainViewModel.predictedExpensesAmount`. Esse campo foi removido; o resultado pertence ao componente, reduzindo o acoplamento entre painel e inteligência.
4. **Catálogos criavam tarefas soltas em onChange.** Os editores de orçamento e transação agora usam tarefas vinculadas à identidade dos catálogos. O carregamento inicial aceita o reinício enquanto a requisição cancelada termina; revisões impedem que o defer de uma requisição antiga encerre o indicador da atual. Retornar ao editor atualiza opções sem recarregar os campos já editados.
5. **Dados podiam ser publicados depois de cancelamento.** Foram adicionadas verificações antes de publicar registros, páginas, modelos e sessão. Cancelamento de paginação e carregamento de modelos não produz alerta. A transação valida referências antes de publicar o novo catálogo completo, evitando uma atualização parcial quando a categoria ou tag está indisponível.
6. **O shell também construía os destinos.** O mapeamento saiu de MainScreen e passou para CashlyRouteScreen. O conteúdo de cada seção e a apresentação modal possuem structs próprias. Os históricos por seção e o padrão compacto/regular foram mantidos.
7. **Ambientes dos formulários não tinham consumidores.** Foram removidas cinco injeções de ViewModels de editor no ambiente. O modelo continua pertencendo ao editor e suas dependências continuam chegando pela factory explícita.
8. **Seleções do painel dependiam de uma alteração futura.** Categoria e tag agora são reconciliadas também no primeiro aparecimento da Home, cobrindo o caso de um catálogo já carregado antes de abrir essa seção.
9. **Limpeza de modelos permitia comandos concorrentes.** A limpeza usa o mesmo bloqueio de operação do treino e verifica o perfil ativo. Cargas anteriores de modelos são invalidadas ao iniciar treino ou limpeza.

## Pontos que ainda merecem evolução

- **P2 — Retry dos editores.** Um erro de carga inicial mantém o salvamento bloqueado até conseguir carregar. Hoje o usuário pode fechar e abrir novamente. Uma ação explícita de retry exige uma decisão de interface; não foi adicionada nesta revisão.
- **P2 — Atualização duplicada após escrita.** CashlyDismissModifier recarrega o painel, enquanto observeChanges também recebe a invalidação do repositório. As revisões protegem a aplicação do resultado, mas não eliminam todo o custo das leituras. Vale centralizar o refresh e manter apenas a seleção explícita de um perfil recém-criado no fluxo de conclusão.
- **P2 — Transformações nos corpos das telas.** HomeScreen e AddTransactionScreen ainda possuem seções extensas e transforms locais. As agregações financeiras principais já chegam prontas do dashboard; a próxima extração deve seguir medições de recomposição e de scroll, principalmente com muitos participantes, tags e categorias, sem criar abstrações para cada controle.
- **P2 — Identidade de seleção por objeto.** Algumas seleções do painel armazenam snapshots de Category/Tag, reconciliados por ID quando o catálogo muda. Migrar seleções persistentes para IDs simplificará restauração e deep links, quando essas features entrarem no escopo.
- **Validação interativa pendente.** Fechar uma sheet por gesto/botão, voltar a um formulário após criar uma categoria, alternar perfis com carga pendente, editar participantes existentes e alternar o filtro de data durante previsão devem ser percorridos manualmente em cada plataforma. Compilação não comprova essas interações nem renderização dos previews.

A revisão preservou layout, recursos, fontes e o suporte de entrada apenas no domínio/banco. Não adicionou funcionalidades de Siri ou Foundation Models. Essas integrações e a evolução do banco continuam descritas em data-and-intelligence-review.md.

## Verificação realizada

- Debug compilado para iOS Simulator, macOS e visionOS Simulator com Xcode 27 beta 6.
- CashlyPreview compilado separadamente. Previews de início e app sem perfis foram acrescentados; o preview de nova transação usa o perfil explícito da sessão. Os dados são em memória.
- swift-format e SwiftLint estrito aprovados: 128 arquivos, zero violações.
- git diff --check aprovado.
- Nenhuma suíte de testes foi executada ou alterada. Previews não foram renderizados nesta rodada.

Logs: `/tmp/cashly-swiftui-patterns-debug.log`, `/tmp/cashly-swiftui-patterns-previews-build.log`, `/tmp/cashly-swiftui-patterns-lint.log`.

## Referências

Aplicação da skill [swiftui-ui-patterns](https://github.com/openai/plugins/blob/main/plugins/build-ios-apps/skills/swiftui-ui-patterns/SKILL.md), respeitando MVVM e os padrões locais.

- [Model data — Apple](https://developer.apple.com/documentation/swiftui/model-data)
- [Understanding the navigation stack — Apple](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
- [sheet(item:onDismiss:content:) — Apple](https://developer.apple.com/documentation/swiftui/view/sheet(item:ondismiss:content:))
