# Decisões

Registro das decisões que moldam o código, em ordem. Cada entrada diz o que foi decidido e por quê; o detalhe de implementação está no código e no histórico do git.

## 04/10/2026: base de dados e domínio

- **Dinheiro em centavos.** `Money` guarda `Int64` de unidades menores e uma moeda explícita (BRL). A migração manteve os campos antigos para compatibilidade e acrescentou os novos. Somas e rateios precisam fechar exatamente; `Double` acumulava erro.
- **Schemas congelados.** V1 e V2 são cópias fixas dos modelos de cada versão; V3 é o atual. Alterar uma classe de modelo não pode mudar a definição de uma versão já distribuída.
- **Usuário por janela.** A seleção pertence à janela; a preferência salva só escolhe o usuário inicial da próxima abertura. Consultas são delimitadas por usuário e período.
- **Paginação por cursor** com desempate por ID, separada do resumo do período.
- **Conflitos de orçamento** pela chave usuário/categoria/mês: valores em conflito saem dos totais e o usuário escolhe qual prevalece. Nada é descartado em silêncio.
- **Tags por ID**, preservadas ao renomear; a descrição só sugere tags.
- **Transação independe de orçamento.** Entradas e saídas existem sem planejamento; orçamento se associa na leitura, por categoria e competência.
- **Inteligência com revisão de treino.** Modelos guardam a revisão dos dados; modelo desatualizado não sugere.

## 05/10/2026: materiais

- **Liquid Glass só em controles.** Conteúdo informativo usa preenchimento simples (`contentSurface`); controles personalizados usam vidro (`surface`), interativo só quando habilitado. Segue a separação de conteúdo e controles das diretrizes da Apple.

## 08/10/2026: arquitetura por features

- **Um target por feature**, com `FeatureCore` para o que é compartilhado e `AppShell` como único ponto que conhece todas. Adicionar uma tela não deve exigir entender o resto do app.
- **Repositórios por agregado** atrás de protocolos do domínio; `CashlyStore` é um único `@ModelActor`.
- **Models `@Observable` pelo ambiente.** Views leem models por `@Environment` e criam `@Bindable` no `body`; dados e ações ficam nos models.
- **Sem comentários no código.** A intenção fica nos nomes e na estrutura; o lint bloqueia comentários.
- **UI só em pt-BR**, com String Catalog por target. Substituída em 12/10/2026 pela localização em dez idiomas (ver abaixo).
- **`CashlyAudit` como ferramenta de diagnóstico e validação automatizada** (comando `check`), separada dos testes.

## 08/10/2026: visual

- **Visual nativo mantido.** Duas propostas de identidade nova foram testadas e rejeitadas (inspirada no Claude e o design system byescaleira). O app segue com `List`/`Form`, vidro e cores do sistema.
- **Diretrizes da Apple acima de qualquer design system.** Um design system só veste componentes nativos (cor, fontes, conteúdo); navegação, títulos, formulários e folhas ficam como o sistema define.
- **`AdaptiveList`.** As telas de painel recebem as mesmas `Section` de uma `List` e se dividem em colunas quando a largura permite (iPad, iPhone em paisagem, dobrável). O Histórico também usa o `AdaptiveList` (12/10/2026): na `List` mantém deslizar e seleção nativa; nas colunas, excluir fica no menu de toque longo e a seleção usa o `SelectionMark`.
- **Nenhuma tela estica (12/10/2026).** Painéis, Histórico e Busca viram colunas; formulários (editores, conflito de orçamento, ícone, novidades) ficam numa coluna central de até 560 pt com `readableWidth()`.
- **Inspector para rotas em largura regular**, preso à janela: preso a cada aba, ele empurrava a barra da tela para baixo da barra de abas.

## 08/10/2026: correções de comportamento

- **Campo de valor em centavos.** Os dígitos digitados entram como centavos (`CurrencyInput`).
- **Impacto da edição no orçamento.** O editor de transação guarda a original e mede só a diferença no período filtrado; antes a transação era contada duas vezes.
- **Gráficos com rolagem só quando há pontos sobrando**: com menos pontos que o domínio visível, o Swift Charts derrubava o app no iPad.

## 08/10/2026: ferramentas

- **Testes no simulador.** `scripts/test.sh` usa o scheme compartilhado `CashlyKitTests` e `-collect-test-diagnostics never` (com falha, o sysdiagnose travava o `xcodebuild` por mais de 10 minutos).
- **Xcode Cloud no lugar do GitHub Actions.** Lint e `CashlyAudit check` rodam em `ci_scripts/ci_pre_xcodebuild.sh`.
- **Limites de tamanho no lint:** 400 linhas por arquivo, 250 por corpo de tipo, 7 parâmetros por função.

## 09/10/2026: ajustes

- **Ajustes no menu do avatar**, não numa aba: no iPad de 11" as abas já ocupam a barra. No Mac, a cena `Settings` do sistema.
- **Um `SettingsModel` por processo.** Preferências valem para todas as janelas; por janela, duas cópias divergiriam.
- **Tema pela janela, não por `preferredColorScheme`.** Voltar de "Escuro" para "Automático" com `preferredColorScheme(nil)` deixava a folha aberta escura. O tema define `overrideUserInterfaceStyle` nas janelas (UIKit) e `NSApp.appearance` no Mac.
- **Sincronização com iCloud vale na próxima abertura.** O container do SwiftData é configurado ao abrir o banco; trocar com o app aberto exigiria recriar todo o estado das janelas. No simulador a opção fica desligada.
- **Links configuráveis no `Info.plist`**, sem URLs fixas no código; sem valor, a linha não aparece.

## 09/10/2026: dados

- **Backup em JSON versionado** (`CashlyBackup`, formato `cashly-backup`, versão 1): usuários, categorias, tags, orçamentos ativos e transações com participantes, valores em centavos e datas ISO 8601. Legível fora do app e independente do schema do SwiftData. Uma versão mais nova que o app é recusada.
- **Importar mescla por ID, numa única gravação.** Registros com o mesmo ID são substituídos pelos do arquivo; o resto fica. Cada registro passa pelas mesmas validações dos editores, e qualquer falha desfaz tudo. Importar o mesmo arquivo duas vezes não duplica nada.
- **Orçamento repetido vira conflito**, como na sincronização: se o arquivo traz outro orçamento para a mesma categoria e mês, os dois ficam e o usuário escolhe. Nada é descartado em silêncio.
- **Apagar tudo remove registro por registro** (não em lote), para a exclusão chegar ao CloudKit, e limpa os modelos de inteligência. A confirmação avisa que os outros aparelhos também perdem os dados.
- **`fileImporter` no contêiner da seção, `fileExporter` no botão.** Com os dois em botões irmãos, o SwiftUI abria o seletor de importação ao exportar.

## 09/10/2026: moeda

- **Uma moeda para o app**, escolhida nos Ajustes entre moedas de duas casas decimais (o campo de valor digita em centavos). Os valores não são convertidos: trocar a moeda muda o símbolo e a moeda gravada nos registros novos. Registros antigos guardam a moeda em que foram salvos, o que prepara uma futura fase de várias moedas.
- **`CurrencySetting` global e observável**, como o locale: a formatação acontece em views e models de todas as features, e passar a moeda por parâmetro tocaria quase tudo. O valor fica num `Mutex`, porque o store grava a moeda fora da thread principal. Os testes usam uma instância própria.

## 09/10/2026: notificações

- **Lembretes locais**, sem servidor: no dia de cada conta pendente (a pagar ou a receber, por parcela) e no primeiro dia de cada mês para o planejamento. A permissão só é pedida quando o usuário liga um dos avisos.
- **Até 50 vencimentos agendados**, os mais próximos: o iOS guarda no máximo 64 pedidos pendentes por app, e o planejamento mensal usa um. A lista é refeita a cada recarga da sessão, então novas contas entram sozinhas.
- **Agendamento pelo usuário da janela.** Com usuários diferentes em duas janelas, cada uma agenda os próprios vencimentos com um prefixo por usuário.

## 09/10/2026: ícone do app

- **Três variações do ícone atual** (Escuro, Laranja, Grafite), feitas no formato do Icon Composer com as mesmas camadas e só as cores trocadas; cada uma mantém as aparências clara, escura e tingida do sistema. A troca existe só no iOS e iPadOS, onde o sistema permite.

## 09/10/2026: planilha e backup automático

- **Planilha em CSV com ponto e vírgula**, valores com vírgula decimal e datas no fuso do aparelho: abre direto no Numbers e no Excel em português. Uma linha por transação, com usuário, categoria, tipo, situação, valor, moeda, parcelas e tags.
- **Backup automático semanal e local**, ao abrir o app, em `Documents/Backups`, que aparece no app Arquivos (`UIFileSharingEnabled`). Ficam as 5 cópias mais recentes. Não depende do iCloud Drive, porque o container de documentos ainda não está configurado no `Info.plist`.

## 09/10/2026: fim da fase 7

- **Última sincronização** vem dos eventos do `NSPersistentCloudKitContainer` (importação e exportação concluídas), que o SwiftData publica. `CashlyDatabase.syncEvents()` assina antes de abrir o banco, e o app grava a data mais recente nos Ajustes.
- **Novidades por versão** numa lista fixa (`ReleaseNote.current`), aberta em Sobre. Não aparece sozinha ao abrir o app, para não interromper.
- **Integrações ficam para depois**, por decisão de produto; estão no backlog.

## 09/10/2026: abas

- **Início, Transações, Planejamento, Relatórios e Buscar.** O Início fica com o resumo do mês; gráficos, comparações e previsão vão para Relatórios. Categorias e orçamentos viram Planejamento.
- **Busca como aba de sistema** (`TabRole.search`) em vez de um botão "+" no meio da barra: aba é destino, não ação. A busca procura transações em todos os períodos, pela descrição ou pela categoria, e lista categorias e tags pelo nome.
- **Inteligência sai das abas** e vai para os Ajustes; quando não há modelo treinado, Relatórios oferece o treino no lugar da previsão.
- **Ícones** que dizem o conteúdo: setas de entrada e saída para Transações, pizza para Planejamento e linha para Relatórios.

## 09/10/2026: texto grande

- **`ViewThatFits` para pares curtos, tamanho de acessibilidade para linhas com texto livre.** O `ViewThatFits` mede a largura ideal, sem quebra; numa linha com a descrição de uma transação, ele empilharia sempre que a descrição fosse longa, mesmo no tamanho padrão. Por isso essas linhas mudam de forma só nos tamanhos de acessibilidade (`AdaptiveRow`).
- **Valor nunca quebra no meio.** "R$ 497.500,0 / 0" é ilegível; o valor fica numa linha e a fonte reduz até a metade.
- **"/ R$ 500,00" virou "de R$ 500,00"**, que continua claro quando o total desce para a linha de baixo.

## 09/10/2026: assinatura

- **Cashly Pro, com teste grátis e depois pago.** Sem plano grátis permanente: a pessoa usa tudo no período de teste e depois assina. Como o app não foi publicado, não há usuários antigos a preservar.
- **Mensal e anual**, sem vitalício: R$ 14,90/mês e R$ 99,90/ano. O teste grátis de 7 dias é a oferta introdutória do StoreKit, e a Apple controla a elegibilidade.
- **Os dados nunca ficam presos.** Sem assinatura, o app abre em modo leitura e a exportação continua liberada.
- **StoreKit 2 sem servidor**, com a tela de assinatura nativa e métricas do App Store Connect, sem SDK de terceiros.

## 10/10/2026: abas e cores

- **Relatórios voltam para o Início** (planejado × gasto, tags, previsão e treino), dentro do `FeatureDashboard`; o target `FeatureReports` deixou de existir. A aba liberada virou **Ajustes**, que sai do menu do avatar.
- **Paleta retrô** em `Color+Retro`: mostarda, laranja queimado, ferrugem, oliva, petróleo, jeans, ameixa e marrom, cada uma com variante clara e escura. As cores semânticas (`positive`, `negative`, `warning`, `info`), estados de orçamento, saúde, status de transação, gráficos e interruptores usam a paleta. O `AccentColor` do app é o laranja queimado.
- **Ilustrações** trocaram o verde da Apple pela mostarda. As cores que a pessoa escolhe para categorias e tags não mudam.

## 10/10/2026: seletor de cores

- **Um seletor só** (`RetroColorPicker`, grade de bolinhas no padrão do seletor de ícones) para a cor de destaque do app, categorias e tags. São 26 cores retrô com nome (`RetroColor`), em ordem de matiz. O seletor de cores do sistema saiu dos editores.
- **Cores guardadas em hex**, como antes: registros com cor fora da paleta continuam funcionando e aparecem como "Personalizada". Categorias e tags novas começam em Laranja queimado.
- **Cor de destaque** em Ajustes > Aparência, salva no aparelho. Ela vira o `.tint` do app e o `\.appTint` do ambiente, que as views usam no lugar de `Color.accentColor`, e também pinta a janela do UIKit (alertas e menus). O `AccentColor` do catálogo continua como valor inicial.

## 10/10/2026: folha lateral e ícones

- **Folha lateral no lugar do inspector** no iPhone e iPad (iOS 27, `presentationPlacement`). Na horizontal fica presa à direita; na vertical, centralizada. Abre grande e pode recolher até a barra de ações, com o conteúdo de trás usável. O Mac continua com o inspector nativo, e o visionOS com sheet, porque lá a posição não existe.
- **Seletor de ícones em tela própria com busca** (a versão com fichas no editor foi descartada por pesar no formulário). O editor mostra só uma linha com o ícone atual; a tela lista as categorias em seções, abre na categoria do ícone escolhido, volta ao escolher e busca em português sem acento ("remedio", "carro"): as palavras-chave em pt-BR casam pelo começo e os nomes em inglês só por igualdade. A paleta foi refeita em 18 categorias pensadas para finanças (Alimentação, Mercado, Transporte, Viagem, Casa, Contas e serviços, Finanças, Saúde, Esportes, Compras e estilo, Cuidados pessoais, Família e pets, Lazer, Educação, Trabalho, Tecnologia, Presentes e festas, Outros), com 333 símbolos conferidos no sistema e sem repetição dentro de cada categoria. Ícones salvos que saíram da paleta continuam aparecendo.

## 10/10/2026: estados vazios

- **Um padrão só** (`EmptyStateView`, sobre o `ContentUnavailableView`, como na busca): centralizado, com a ilustração colorida, título, descrição e o botão no estilo dos antigos cards (negrito, arredondado, grande). Os cards grandes de usuário, categoria e orçamento no meio das listas saíram.
- **Estado vazio de acordo com a tela** (`.emptyState(_:when:)`): Transações mostra "Nenhuma transação neste período", Planejamento mostra "Nenhuma categoria ainda", e o editor só pede categoria onde ela é necessária. O Início não bloqueia por falta de categoria ou orçamento.
- **Onboarding no lugar do estado vazio de usuário** (`FeatureOnboarding`): na primeira abertura, uma folha pequena de vidro no estilo da configuração dos AirPods, que se ajusta ao conteúdo de cada passo: boas-vindas → perfil (nome e avatar) → categorias sugeridas com a paleta retrô → pronto. Não fecha arrastando; dá para voltar e pular as categorias.

## 10/10/2026: ilustrações mid-century

- **Ilustrações de objeto no estilo mid-century:** formas planas sem contorno, estrela atômica mostarda, bumerangue oliva, círculos e pontos, na paleta retrô. Cinco artes vetoriais: busca (recibo e lupa), categorias (blocos com ícones), tags (etiquetas), transações (cartão e moedas) e boas-vindas (carteira). Pessoas saíram das ilustrações.
- **A busca usa o mesmo `EmptyStateView`**, sem botão, para "Buscar no Cashly" e "Nada encontrado".

## 10/10/2026: ícone retrô

- **Ícone no Icon Composer com vidro**, na paleta retrô: fundo creme (ou noturno), cartão de vidro colorido, "$" creme e bolso creme. A estrela atômica mostarda sai por trás do cartão. O cartão e o bolso têm cantos concêntricos com o ícone (raio do ícone menos a margem), com margem de 100 e 80 pt.
- **Variações:** Clássico (laranja queimado), Noturno, Mostarda e Petróleo. Para outubro: Sangue, Morcego, Caveira e Frankenstein.
- **Seletor de ícone com prévia** (`AppIconScreen`): grade com a imagem real de cada ícone, exportada do Icon Composer por `scripts/icons.sh` (clara e escura) para o catálogo do `CashlyResource`. A coleção do mês aparece em destaque no topo, num cartão com o degradê do tema (em outubro, Halloween); fora do mês ela fica numa seção comum. Rode `scripts/icons.sh` sempre que um `.icon` mudar.

## 10/10/2026: guias e importação

- **O layout do onboarding virou o padrão oficial** para tutoriais e configurações (`GuideSheet`, `GuidePage`, `GuideAction` no `FeatureCore`): folha que se ajusta ao conteúdo, indicador de passos, ilustração ou símbolo, título, texto e botão grande da cor de destaque. Um guia novo é um caso em `Guide` com suas páginas.
- **Ajustes > Guias** lista os guias (Conheça o Cashly, Importar planilha, Planejar o mês, Dividir despesas), abertos por `\.showGuide`. A janela de Ajustes do Mac (⌘,) não tem sessão e esconde a seção.
- **Importar planilha** em quatro passos: como montar (colunas, exemplo e modelo para baixar), escolher o arquivo, conferir (válidas, totais, categorias e tags que serão criadas, linhas com problema) e concluído. Aceita a planilha exportada pelo Cashly. A leitura (`SpreadsheetParser`) fica no domínio e é testada.
- **Importar backup** segue o mesmo padrão: explicação, conferência com as contagens e concluído.
- **Abertura:** o "Abrindo Cashly" fica até usuários e o primeiro resumo carregarem (`SessionModel.isReady`), sem o Início aparecer vazio e depois com zeros. A demora longa em branco vista no simulador era do simulador com vários aparelhos ligados.

## 10/10/2026: aba Metas e guia da pontuação

- **Metas separa orçamentos e categorias.** No topo, o **Resumo do mês**: planejado, gasto e disponível, a barra de uso, quanto dá para gastar por dia até o fim do mês, o fechamento projetado no ritmo atual e quanto foi gasto em categorias sem orçamento. Depois, os **orçamentos agrupados pela situação**, em linguagem simples: Passaram do limite, Perto do limite (80% ou mais), No caminho e Sem gastos ainda, os piores primeiro, cada um com barra, "Sobram"/"Passou" e gasto de planejado. Por fim, **Categorias** numa seção, com a quantidade e o total de orçamentos e o gasto do período.
- **Menu de contexto** em orçamentos (Editar, Ver categoria, Apagar) e em categorias (Editar, Novo orçamento, Apagar), com confirmação antes de apagar. O "+" da barra oferece nova categoria ou novo orçamento.
- **O cálculo fica em `BudgetOverview` e `BudgetProgress`**, testados; o `GoalsModel` só junta os dados e apaga.
- **Guia da pontuação:** tocar no cartão da Pontuação (ou no ⓘ) abre um guia: o que é, as faixas com o limite de gasto de cada uma, os números do período atual (quanto ainda pode gastar mantendo 1.000 e Saudável) e como subir. As faixas vêm da mesma fórmula da pontuação (`BudgetHealth.usage(for:)`).

## 10/10/2026: Ajustes adaptáveis

- **Ajustes usam o `AdaptiveList`** como as outras abas: uma coluna no iPhone em pé, duas ou mais no iPad e no iPhone deitado. No Mac continua o `Form` agrupado da janela de Ajustes.
- **`DisclosureLink`** (DesignSystem) desenha a seta de navegação quando a linha está nas colunas, onde o `NavigationLink` não tem seta. Os seletores de Tema e Moeda usam `LabeledContent` para manter o rótulo fora da lista.
- **Guias com transição no sentido certo:** avançar entra pela direita, voltar entra pela esquerda; a página que sai só esmaece.

## 10/10/2026: motor de análise, MCP e plugin

- **`CashlyAnalytics` (fase A):** retrato do livro em lançamentos por mês de parcela, séries mensais, estatística robusta, valor do dinheiro no tempo, tabelas Price e SAC e taxa efetiva de compras parceladas. O `AnalysisEngine` roda análises registradas com origem e cache por revisão. Primeiras análises: parcelas já assumidas, ritmo do mês e quanto posso gastar por dia. Modelos de linguagem: só os da Apple, por enquanto.
- **MCP dentro do app do Mac**, e não como executável separado: o app roda em sandbox e outro processo não leria o banco sem pedir permissão ao sistema. O servidor ouve só em 127.0.0.1, exige token, recusa origens de fora e liga nos Ajustes. Protocolo próprio e enxuto (`CashlyMCP`), sem dependência externa.
- **Escrita pelo MCP passa pela conferência do app:** `import_transactions` valida os itens e abre a mesma tela da importação de planilha, com "Recusar". A ferramenta espera a decisão por até ~3 minutos e responde importado, recusado ou aguardando.
- **Plugin do Claude Code** no próprio repositório (`.claude-plugin/marketplace.json`, `plugins/cashly`): configuração do MCP por variáveis de ambiente e duas skills, `cashly-import` (extratos do Open Finance, OFX, CSV, PDF: limpeza, parcelas, transferências, duplicatas) e `cashly-insights`.

## 11/10/2026: feature flags e MCP em qualquer aparelho

- **Feature flags** (`FeatureFlag`, `FeatureFlags` no `FeatureCore`): padrão no código, valor remoto pelo banco público do iCloud (`CloudKitFlagSource`, registro `FeatureFlag` com `name`, `isOn`, `rollout`) e ajuste manual em Ajustes › Desenvolvimento, só em builds de desenvolvimento. Lançamento gradual por um grupo estável de 0 a 99 derivado de um identificador anônimo do aparelho. Servidor MCP, rede local, guias, importação de planilha e motor de análise já nascem atrás de flags.
- **Analytics de uso: só da Apple** (MetricKit e App Store Connect), por decisão do usuário. O TelemetryDeck fica de fora.
- **MCP em qualquer aparelho**, com aprovação de conexão no app e sessão `Mcp-Session-Id`; escrita sempre pela conferência. Sem login com Apple: sem servidor próprio ele não acrescenta segurança ao MCP (detalhes em [social.md](social.md)).

## 11/10/2026: valor em tempo real, mês do orçamento e guias

- **`CurrencyField` como teclado de caixa:** um `TextField` invisível guarda só os dígitos e o valor aparece num `Text` formatado, com troca animada e um traço na cor do app enquanto tem foco. Cada dígito entra pela direita, apagar remove o último, e o valor é atualizado a cada toque. Reformatar o próprio texto do campo gerava um segundo `onChange` e embaralhava os dígitos.
- **Orçamento escolhe mês e ano** (`MonthPicker` no `FeatureCore`): ano com setas e grade de meses em cápsulas, o mês atual destacado. Orçamento é mensal, então não há dia.
- **Listas dos guias** (`GuideFeatureList` e `GuideValueList`): itens com símbolo, título e detalhe, como nas telas de novidades da Apple, e valores em linhas agrupadas com divisórias. Usadas na importação de planilha e no guia da pontuação.
- **Resumo do mês em Metas:** anel de uso no estilo Atividade, com o disponível e a legenda de gasto e planejado ao lado, no lugar das três métricas em fila.
- **Guias com exemplos, sem ícones nem ilustrações:** cada página mostra um exemplo preenchido e simplificado da própria feature, montado com os componentes do app (`GuideExample`, `ExampleRow`, `ExampleBar`, `ExampleChip`, `ExampleHeadline`, `ExampleFile`, `ExampleDone`): resumo do mês, histórico, barras de uso, busca, orçamento, pontuação, divisão, planilha, arquivo e conclusão. Onde há dados reais (pontuação atual, linhas da planilha, cliente do MCP), o exemplo usa esses dados. Os estados vazios (`EmptyStateView`) seguem o mesmo padrão, com exemplos de categorias, transações, tags e busca; as ilustrações saíram do app.
- **Tags na descrição:** a tela de transação não tem mais a lista de tags com interruptores. As tags cujo nome aparece na descrição entram sozinhas como chips (texto na cor da tag, fundo da cor a 20%, cantos arredondados); tocar no chip tira a tag até a palavra sair e voltar ao texto.
- **Tipo e situação:** Entrada ou Saída fica num menu na barra (Saída por padrão); a Situação passou de cima do valor para a seção Descrição. Trocar para Entrada tira os participantes e inverte "A pagar" e "A receber".
- **Barra sem `.fill`:** símbolos da barra de ferramentas sempre na versão sem preenchimento.

## 11/10/2026: análises no Início

- **Passado, presente e futuro no Início**, em seções com linguagem simples e números grandes:
  - **Este mês:** em quanto o mês fecha no ritmo atual, a diferença para o planejado, o gasto até hoje e quanto dá para gastar por dia (`MonthPace` e `DailyAllowance`).
  - **Comparado aos outros meses:** quanto se gastou a mais ou a menos que a média dos três meses anteriores **até o mesmo dia**, com barras por mês (`SamePointComparison`, nova).
  - **Fora do padrão:** categorias com gasto até hoje bem acima da mediana dos últimos meses no mesmo ponto (1,5× e R$ 50 a mais, z-score robusto), ou novas no mês (`UnusualCategories`, nova).
  - **Próximos meses:** total já comprometido em parcelas e contas futuras, com barras por mês (`InstallmentCommitments`).
- **`InsightsModel`** (FeatureDashboard) lê o livro pelo `RepositoriesLedgerSource`, roda o `AnalysisEngine` (cache por revisão) e entrega estruturas prontas para a tela. Cada seção só aparece quando a análise tem dados.
- **Guias com fundo próprio:** a folha dos guias usa o fundo do sistema (`sheetBackground`: branco no claro, cinza escuro elevado no escuro) e cartões em `sheetCard` (cinza claro ou cinza médio). Preto puro no escuro se misturava com a tela de trás. No visionOS continua o vidro do sistema.
- **Folhas do MCP em fila:** a aprovação de conexão e a conferência de importação passam por um único apresentador, que só abre a próxima depois que a anterior fecha. Antes, uma importação logo após a aprovação era descartada pelo sistema e contava como recusa.
- **Número grande no cabeçalho só onde a seção tem um total que se desdobra:** "Disponível" (total livre no cabeçalho; no grupo, centralizados, o planejado e o percentual usado com o estado, sem lista por categoria) e "Próximos meses" (total comprometido; no grupo, as barras por mês). As outras seções mantêm o destaque dentro do cartão. O seletor de uma categoria por vez saiu, e categorias sem orçamento não mostram mais percentual (antes aparecia "-29.900%").
- **Posição dos guias:** no iPhone em pé, folha de baixo com a altura do conteúdo; no iPad, centralizada e com a altura do conteúdo; no iPhone deitado, na lateral direita, como os editores.
- **Cantos concêntricos no ícone:** o cartão e o bolso da carteira não usam mais arcos de círculo (raios 129 e 149). O contorno de cada um é a máscara do ícone (superelipse do Icon Composer, renderizada pelo `ictool`) deslocada para dentro pelo espaçamento da peça: 100 pt no cartão e 80 pt no bolso. Vale para as 8 variações; as prévias do seletor foram regeneradas com `scripts/icons.sh`.
- **Coleções de ícones:** Cores, Moda (Jeans, Alfaiataria, Couro), Países (Brasil, Portugal, Argentina), Esportes (Futebol, Basquete, Tênis) e as sazonais Festa Junina (junho: Bandeirinhas, Xadrez), Halloween (outubro) e Natal (dezembro: Presente, Neve), destacadas no mês. Todas partem do Clássico: a carteira vira o tema (tecido, cor, costura) e os enfeites do cartão ficam entre o cartão e o cifrão.
- **Maiores gastos em blocos:** barra segmentada no estilo do armazenamento do iPhone com a fatia de cada um dos 5 maiores nas saídas; o maior em cartão de destaque com fundo na cor da categoria; os outros em blocos de duas colunas (o último ocupa a linha inteira quando sobra). Tocar abre a transação. Saiu o carrossel de um por vez.
- **Previsão do mês unificada:** "Previsão de gastos" (modelo treinado no aparelho, com botão "Treinar modelos") e "Este mês" viraram uma seção só. O `MonthPace` v2 soma o já gasto, as contas agendadas e a mediana do que saiu depois deste dia nos últimos 6 meses; sem histórico, volta ao ritmo linear. A barra mostra já gasto, o que ainda deve sair e a marca do planejado.

## 11/10/2026: Metas reorganizada

- **Metas tem duas partes:** um cartão "Orçamentos" com o acumulado do mês (disponível, percentual usado, barra pela situação dos orçamentos e a contagem de cada situação) que leva à tela **Orçamentos**, e a lista de **Categorias** (tocar edita, deslizar apaga, + na barra cria).
- **Tela Orçamentos** (`Route.budgets`): resumo do mês (cartão, valor por dia, gasto fora dos orçamentos), orçamentos agrupados por situação (tocar edita, deslizar ou menu apaga) e as categorias sem orçamento em cápsulas para criar um. O + da barra cria orçamento.
- **Saíram:** a tela de detalhe da categoria (`Route.detailCategory`; a busca agora abre o editor), o resumo antigo com anel, a seção "Quer mais controle?" e a projeção linear do `BudgetOverview` (a previsão vive no Início).

## 11/10/2026: design system tokenizado

- **Tokens no `CashlyDesignSystem`:** espaçamento, raio, opacidade, tamanho e tipografia (ver [design-system.md](design-system.md)). As 51 telas que tinham números soltos passaram a usar os tokens; valores próximos foram unificados (10 e 14 viraram 12, 18 virou 16, badges de 34 e 40 viraram 36 e 44).
- **Componentes únicos:** `Chip` substitui quatro chips iguais (exemplos dos guias, análises, tags da transação, selo do Início) e `SymbolBadge` substitui três badges de categoria.
- **Lint:** `design_token_spacing`, `design_token_radius`, `design_token_opacity` e `design_token_font` acusam número solto nas features.
- **Segunda etapa:** escala `IconSize` com `.font(.icon(_:weight:))` para os 13 ícones de tamanho fixo; fontes por papel (`.amountRow`, `.amountTitle`, `.titleLarge`, `.titleMedium`, `.rowTitle`, `.buttonLabel`); `FigureHeader`, `FigureBlock` e os cartões de exemplo dos guias foram para o design system, recebendo texto, com atalhos de moeda no `FeatureCore`.

## 11/10/2026: Ajustes reorganizados

- **Tela principal no estilo dos Ajustes do iPhone:** três grupos (Geral: Aparência, Moeda, Notificações; Dados: iCloud, Dados e backup, Inteligência, Claude Code; Ajuda: Guias, Sobre o Cashly) e Desenvolvimento só nas versões de desenvolvimento. Cada linha mostra o valor atual (tema, moeda, ligado ou desligado, versão) e abre a sua tela.
- **`IconRow`** (design system): símbolo sem preenchimento num quadrado tingido, título, detalhe e valor. Usado nas linhas da tela principal e em todas as ações e links das telas internas.
- **Duas cores intercaladas:** a cor de destaque e o `.companion` (azul denim, o mesmo par de "Orçamento × Gasto" no Início) alternam linha a linha. "Apagar" usa `.negative`.
- **Telas internas** com `SettingsPage` (lista adaptável no iPhone e iPad, `Form` no Mac); os títulos de seção que repetiam o título da tela saíram. "Apagar todos os dados" fica no fim de Dados e backup; ajuda e contato ficam em Sobre o Cashly. Ícones dos guias e dos modelos de inteligência passaram para as versões sem preenchimento.


## 12/10/2026: correções da revisão de código

- **Análises do Início:** o cache do `AnalysisEngine` usa a impressão digital do livro (revisão, dia, orçamentos e categorias), e a chave de recarga do `InsightsModel` passa a ser usuário + `session.generation` + dia (com `NSCalendarDayChanged`). As seções de análise só aparecem com o filtro padrão do mês atual, porque descrevem o mês inteiro.
- **MonthPace v3:** "Ainda deve sair" compara os mesmos últimos dias de cada mês anterior, então no último dia não sobra nada. **UnusualCategories v2:** uma conta paga antes do dia de costume não vira "Novo este mês" quando a categoria teve gasto nos meses anteriores.
- **CurrencyField:** o campo invisível não recebe toques e o cursor fica sempre no fim, então digitar e apagar mexem só nos últimos dígitos.
- **Claude Code:** um pedido novo (conexão ou outro lote) não fecha a conferência aberta; enquanto há um lote pendente, um segundo `import_transactions` recebe "aguardando".
- **Importação (`prepare.py`):** parcelas da mesma compra com centavo de arredondamento ficam juntas e o total é a soma das parcelas; nome do titular, nome do emissor e termos de investimento casam por palavra inteira, e investimento só vale para linhas de conta; transferências só formam par quando uma ponta tem o nome do titular ou as duas são TED/TEF/DOC/transferência.
- **Outros:** orçamento novo sem categoria abre no mês do filtro; o `MonthPicker` acompanha a seleção carregada; trocar Saída/Entrada leva o status pendente para "A pagar"/"A receber"; a grade de categorias do onboarding volta a ser acessível e fica abaixo do título.

## 12/10/2026: backup no iCloud Drive, Inteligência oculta e ferramentas de desenvolvimento

- **Backup no iCloud Drive.** Em Dados e backup, "Salvar backups no iCloud Drive" manda o backup automático e o "Fazer backup agora" para `Documents/Backups` do container `iCloud.cashly`, que aparece no app Arquivos em iCloud Drive › Cashly › Backups (`NSUbiquitousContainers` no `Info.plist`, com o nome Cashly). Leitura e escrita passam por `NSFileCoordinator`, e arquivos ainda não baixados (`.icloud`) entram na lista e são baixados ao abrir. Sem iCloud Drive, o backup continua no aparelho e a tela diz por quê. "Backups salvos" lista as cópias do destino atual e abre a conferência antes de importar.
- **Inteligência fora dos Ajustes por enquanto.** A linha saiu da tela principal; o código continua no `FeatureSettings` para a próxima etapa.
- **Desenvolvimento** (só em DEBUG) reúne, além dos recursos: dados de exemplo (`SampleDatabase.seed`, por isso `CashlyMock` entrou no produto `CashlyKit`), recarregar dados, abrir as boas-vindas, notificação de teste, backup agora, reiniciar a agenda do backup automático, apagar preferências (`cashly.*`), apagar todos os dados e informações do app (versão, identificador, container, conta, caminhos do banco e dos backups). As ações ficam no `DeveloperModel`.

## 12/10/2026: quatro ícones por coleção e três coleções novas

- **Toda coleção tem 4 ícones.** Entraram Poá (Moda), Japão (Países), Vôlei (Esportes), Fogueira e Milho (Festa Junina), Pisca-pisca e Bengala (Natal).
- **Coleções novas:** Anos 80 (Neon, Fita K7, Fliperama, Portátil), Verão (Pôr do sol, Calçadão, Guarda-sol, Melancia; em destaque em janeiro) e Carnaval (Confete, Serpentina, Frevo, Paetê; em destaque em fevereiro).
- Cada ícone reaproveita o cartão, o bolso e o "$" do clássico (e a estrela quando cabe), com camadas temáticas em SVG recortadas no contorno do bolso ou do cartão, versões clara, escura e tingida. O nome do asset passou a sair do `rawValue` (`CashlyIcon` + nome com inicial maiúscula).

## 12/10/2026: inglês como idioma principal e dez idiomas

- **Inglês é o idioma de desenvolvimento** (pacote e projeto em `en`); o português virou tradução.
- **Idiomas traduzidos:** português (Brasil), espanhol (Espanha), alemão (Alemanha), francês (França), italiano, japonês, coreano, chinês simplificado e russo. Todas as traduções estão marcadas como prontas.
- **Catálogo único no app.** Os catálogos por feature nunca eram lidos, porque `Text("…")` num pacote procura no bundle principal. Agora todas as chaves ficam em `Cashly/Cashly/Localizable.xcstrings`.
- **Troca na hora, pelos Ajustes.** Ajustes › Idioma tem "Sistema" e os dez idiomas com o nome no próprio idioma.
  - O `LanguageSetting` (domínio) guarda o idioma, o `Locale` e o bundle `.lproj` resolvidos.
  - As telas leem o `\.locale` do ambiente; os modelos usam `String(appLocalized:)`.
  - O `MainScreen` recria as abas quando o idioma muda, para os títulos da barra acompanharem.
  - A escolha também grava `AppleLanguages`, e o iOS usa esse idioma nos textos do sistema a partir da próxima abertura.
- **Plurais pelo catálogo.** As contagens viraram uma chave com variações (o russo tem `one`, `few` e `many`), no lugar de ternários com o número 1.
- **Planilha CSV:**
  - A exportação sai com cabeçalhos e valores no idioma do app.
  - A importação aceita cabeçalhos, tipos e situações em qualquer idioma suportado (mais os apelidos antigos em português) e reconhece datas no formato mês/dia.
- **Busca de ícones:** as palavras-chave têm base em inglês e tradução por idioma; a busca considera o idioma do app e o inglês.
- **Fora da tradução:** textos que só o Claude lê. As narrativas do motor de análise passaram para o inglês; as descrições das ferramentas do `CashlyMCP` continuam em português por enquanto. O `CashlyAudit` e os dados de exemplo, ferramentas internas, também ficam em português.

## 12/10/2026: motor da Jornada (fase 8.1)

- **`CashlyGame` recalcula tudo dos dados.** XP, nível, sequência, conquistas, missões e desafios saem de um `GameSnapshot` (o retrato do `CashlyAnalytics` mais os eventos). Nada de saldo de XP guardado: apagar uma transação tira o XP dela e dois aparelhos chegam ao mesmo número.
- **Eventos duráveis no schema V4.** `GameEventEntity` guarda só o que não está nos dados: "hoje não gastei", guia concluído, desafio escolhido ou abandonado, congelamento creditado, sequência recuperada, backup e importação. Transação nova grava `transactionRecorded` na mesma gravação; restaurar um backup não grava. Créditos e recuperações têm chave única, para uma compra não valer duas vezes.
- **"Mês no azul" é o nível saudável da saúde do orçamento** (pontuação ≥ 895, dentro do orçado). O 850 da primeira versão do plano deixava passar meses até 6,6% acima do orçado.
- **Missões sorteadas sem servidor:** gerador congruente semeado pela semana e pelo perfil, com semanas de segunda a segunda. Missões irmãs (5 e 10 registros, 4 e 6 dias) não saem juntas.
- **Desafios por código** (`tipo|categoria|limite`) no valor do evento. Começar outro desafio abandona o atual; o que já tinha falhado continua como falha.

## 12/10/2026: aba Jornada (fase 8.2) e fim da Busca

- **A Jornada ocupa o lugar da Busca** como aba proeminente. A `FeatureSearch` saiu do app, com testes, prévias e textos; o tour mostra a Jornada no lugar da página de busca.
- **`FeatureJourney`:** `JourneyModel` monta o `GameSnapshot` pelo `RepositoriesGameSource` e recarrega com a sessão. Seções: nível (anel de XP), sequência com "Hoje não gastei", missões da semana, desafio (escolher, trocar, desistir) e grade de conquistas com detalhe; as secretas aparecem como "?".
- **Comemorações sem repetir:** o modelo guarda por perfil, no `UserDefaults`, o último nível e as conquistas já vistas. A primeira abertura só registra o estado; depois, cada nível ou conquista nova vira uma folha curta com efeito de símbolo e vibração, em fila.
- **Eventos gravados pelo app:** guia concluído (tutoriais, pontuação e importação), planilha importada e backup criado (cada exportação grava um evento para cada perfil).
- **Ajustes › Jornada** liga e desliga a aba; esconder não apaga o progresso. A flag remota `journey` também esconde a aba e a linha dos Ajustes.

## 12/10/2026: bloqueio e modo discreto (fase 9.6)

- **`AppLockModel`** (`FeatureCore`) sobre `LocalAuthentication` com a política `deviceOwnerAuthentication` (Face ID, Touch ID, Optic ID ou código); o `Authenticating` é injetável para testes. Nasce bloqueado quando a preferência está ligada; `PrivacyShield` na `MainScreen` bloqueia ao ir para o fundo, cobre a tela sempre que a cena não está ativa (seletor de apps) e tenta desbloquear ao voltar, com o botão "Desbloquear" para repetir.
- **Modo discreto** usa `redacted(reason: .privacy)` na raiz e `privacySensitive()` dentro de `amountLine()`, então todo valor que usa o modificador de valores fica borrado; texto comum continua legível.
- **Ajustes › Privacidade** com "Bloquear com Face ID" (o título segue a biometria do aparelho) e "Modo discreto"; as duas preferências ficam no `SettingsModel`.

## 12/10/2026: notificações com ação (fase 9.5)

- **Categorias registradas na abertura** (`SystemNotifications.registerCategories`): `cashly.bill` com "Marcar como paga" e "Adiar 1 dia" (exigem desbloqueio), `cashly.budget` e `cashly.weekly`. O `NotificationResponder` (`AppShell`) é o delegate: executa as ações pelo `IntentActions` (respeitando o Cashly Pro) e, no toque, guarda `cashly://transactions/<id>` em `CashlyServices.pendingURL`, que o `DeepLinks` da `MainScreen` consome.
- **Vencimentos são Sensíveis ao Tempo** (entitlement `usernotifications.time-sensitive` e `interruptionLevel`), com o id da transação no `userInfo`.
- **Alertas de orçamento em 80% e 100%**, uma vez por orçamento, mês e patamar (chave no `UserDefaults`), entregues na hora em que o retrato do mês muda (`NotificationsModel.review(_:)` roda junto com o `publishSnapshot`). **Resumo semanal** reagendado a cada mudança para o próximo domingo às 18h com os totais atuais, porque uma notificação repetida não pode mudar o texto.
- **Ajustes › Notificações** ganhou "Alertas de orçamento" e "Resumo semanal"; o rodapé explica os quatro tipos. O `Reminder` carrega categoria, `userInfo` e sensibilidade; o `NotificationScheduling` ganhou `deliver(_:)` para entrega imediata.

## 12/10/2026: Central de Controle, Botão de Ação e Wallet (fase 9.4)

- **Controle "Novo gasto"** (`ControlWidget`, só iOS) na extensão de widgets: o botão roda um intent com `openAppWhenRun` que devolve `OpenURLIntent(cashly://transactions/new)`; o app abre o editor pela mesma rota dos widgets. O mesmo controle serve ao Botão de Ação, e o atalho "Registrar gasto" também pode ser atribuído a ele.
- **Wallet sem código próprio.** A automação "Transação" do app Atalhos chama o intent `AddExpenseIntent` com valor e estabelecimento; não há API para o app criar a automação, então o guia "Registrar num toque" (três páginas: Siri, Wallet, Central de Controle/widgets; animação `capture`) explica o passo a passo e entra na lista de guias e no cômputo da conquista "Estudioso".

## 12/10/2026: widgets (fase 9.3)

- **Extensão `CashlyWidgets`** no projeto (target `com.apple.product-type.app-extension`, pasta sincronizada `Cashly/CashlyWidgets`, embutida pelo app), com o produto leve `CashlyWidgetKit` do pacote (só `CashlyDomain` e `CashlyDesignSystem`, sem Lottie nem features) por causa do limite de memória dos widgets.
- **Três widgets, só leitura, no desenho do `budget`** (refeitos em 13/10/2026 a partir dos widgets do repositório privado `byescaleira/budget`, que o usuário considera o padrão): título "Cashly" com etiqueta do mês na cor do uso (verde até 80%, mostarda até 100%, ferrugem acima), rótulos pequenos em caixa alta (GASTO, TOTAL PLANEJADO, RESTANTE), gasto na cor do uso, planejado em negrito, restante com percentual que sobra e barra grossa. "Este mês": pequeno (cabeçalho, gasto/planejado, restante), médio (cabeçalho com planejado à esquerda; etiqueta com o número de lançamentos, gasto, % e barra à direita; gráfico planejado × gasto por categoria com eixo à direita, planejado na cor de destaque e gasto na cor do uso), grande (o mesmo mais a grade de seis categorias) e Tela Bloqueada no iOS; **configurável por categoria** (`AppIntentConfiguration` lendo as categorias do próprio retrato; com filtro, a categoria aparece como etiqueta e some o contador). "Orçamentos" (médio e grande): grade com badge, nome, % e barra por categoria e etiqueta "estouradas/total". "Próximas contas" (pequeno, médio, grande): etiqueta com a quantidade, PENDENTE com o total e lista com badge, descrição, data (ferrugem se vencida) e valor. Todos leem o retrato do App Group, atualizam a cada hora e, sem retrato, mostram "Abra o Cashly". Sem anéis, conforme a direção visual. Tokens de fonte só dos widgets em `WidgetSupport.swift`.
- **Recarga dos widgets.** `publishSnapshot()` chama `WidgetCenter.reloadAllTimelines()` depois de gravar, e a `MainScreen` repete a chamada quando o app vai para o fundo: o WidgetKit adia recargas pedidas com o app em primeiro plano e as descarta se ninguém insistir, e era por isso que o widget ficava com dados velhos.
- **Trocar `StaticConfiguration` por `AppIntentConfiguration` exige nova identidade.** O widget "Este mês" nasceu estático como `cashly.month`; ao virar configurável com a mesma `kind`, as instâncias já colocadas na tela não tinham intent e toda recarga falhava com `CHSErrorDomain 1103` ("Intent configuration is required"), o que o usuário viu como "o widget não carrega". Em 13/10/2026 "Este mês" voltou a ser estático na identidade original `cashly.month` (zero dependência de intent) e o filtro por categoria virou um widget próprio, "Um orçamento". A versão configurável (`AppIntentConfiguration`) nunca saiu do placeholder no iPhone do usuário (iOS 27.2, Xcode 27.0 beta 6): o rastro gravado pela extensão mostrou que o sistema só pedia o placeholder e nunca o snapshot/timeline, sem crash e sem instanciar o intent — falha antes de chegar na extensão, provavelmente incompatibilidade dos metadados de App Intents entre o beta do SDK e o do aparelho. Decisão do usuário: **"Um orçamento" é estático** (`cashly.focus`) e segue a categoria escolhida em Ajustes › Widgets (`SettingsModel.widgetCategoryID`), que o app grava no retrato como `focusCategory`; todas as cópias do widget mostram a mesma categoria. Voltar ao configurável quando houver Xcode com SDK da mesma versão do aparelho. Não trocar o tipo de configuração de uma `kind` existente. O target da extensão usa isolamento padrão `nonisolated` (o app continua na `MainActor`), porque o WidgetKit e o AppIntents chamam os provedores fora da main actor.
- **Splash única, com todo o carregamento** (pedido do usuário em 13/10/2026, no padrão do `budget`): `SplashScreen` no `AppShell` mostra o ícone atual do app (`AppIconImage`), o nome, uma barra de etapas e a etapa em curso; `LaunchProgress` (banco, perfis, mês, Cashly Pro, widgets) é criado pela raiz do app e marcado pela `MainScreen` conforme cada `.task` termina; concluído tudo, espera 0,6 s e some com fade, e em no máximo 8 s some de qualquer jeito. Spotlight, revisão de notificações e modelos de insights rodam depois, fora da splash: são XPC do sistema que podem demorar ou travar e a interface não depende deles. A animação Lottie `launch` saiu da abertura (continua no guia). A tela de bloqueio segue o estilo dos guias (`GuidePage`: título em cima, animação Lottie `launch`, texto) com o botão proeminente "Desbloquear com Face ID/Touch ID/código" embaixo (pedido do usuário em 13/10/2026). O onboarding só abre depois que a splash some.
- **Face ID exige `NSFaceIDUsageDescription`.** Sem a chave o iOS nem tenta a biometria e cai direto na senha ("só código dá certo"); a chave está no `Info.plist` e traduzida em `InfoPlist.xcstrings`. Além disso, `AppLockModel` deixou de criar `LAContext` na `init` (a consulta `biometry()` virou assíncrona e roda numa `Task`): criar o contexto é uma chamada XPC síncrona ao daemon de autenticação e, com ele lento ou travado, o app ficava na tela branca sem nem desenhar a splash.
- **Cache de build em `$TMPDIR` pode ser podado pelo macOS.** Em 13/10/2026 os `Info.plist` do `Lottie.xcframework` sumiram de todos os derived data em `cashly-build` e o `XCBuildData` guardou a ausência; o conserto é apagar `SourcePackages` e `Build/Intermediates.noindex/XCBuildData` do derived data afetado e resolver os pacotes de novo. Build sem assinatura (`CODE_SIGNING_ALLOWED=NO`) não serve para testar App Group no simulador: o contêiner do grupo só aparece com o build assinado.
- **Marcar como paga ficou para o app.** O banco não está no App Group, então um botão interativo no widget não teria como gravar; a linha da conta é um `Link` `cashly://transactions/<id>` que abre o editor (respeitando o Cashly Pro). O URL scheme `cashly://` também cobre `home` e `budgets`; `DeepLinks` no `AppShell` trata.
- **Strings da extensão** ficam em `Cashly/CashlyWidgets/Localizable.xcstrings` (a extensão tem o próprio bundle); `scripts/strings.sh` sincroniza os dois catálogos.

## 12/10/2026: App Intents (fase 9.2)

- **Lógica fora do AppIntents.** `IntentActions` (`FeatureCore`) recebe repositórios e perfil e faz o trabalho: categorias e tags do perfil, contas pendentes, registrar gasto (categoria nomeada ou a primeira, valor positivo, data opcional), resumo do mês, saldo por categoria e marcar como paga. Testado com banco em memória; os `AppIntent`s no `AppShell` só traduzem parâmetros e diálogos.
- **Quatro intents** (`AddExpenseIntent`, `MonthSpentIntent`, `CategoryRemainingIntent`, `MarkBillPaidIntent`) com `AppEntity` de categoria, tag, perfil e conta pendente, e `CashlyShortcuts` no app com as frases em inglês (o `AppShortcuts.xcstrings` é obrigatório e separado do catálogo principal). As categorias entram no Spotlight como `IndexedEntity` a cada revisão dos dados.
- **Sem janela:** os intents usam `CashlyServices.workspace()` (banco único por processo, perfil selecionado, iCloud conforme a preferência de abertura) e `canWrite()`, que consulta o StoreKit e a flag `pro`; sem assinatura, registrar e marcar como paga falham com a mensagem "Registrar exige o Cashly Pro".
- **Compartilhamento:** os intents não dividem gastos nem escolhem status; tudo entra como quitado e sem participantes, para editar no app.

## 12/10/2026: base fora da janela (fase 9.1)

- **App Group `group.com.byescaleira`**, compartilhado por todos os apps da byescaleira (pedido do usuário em 12/10/2026: os próximos apps terão o mesmo estilo e precisam se comunicar). Dentro dele cada app tem a sua pasta (`cashly/`) com um `manifest.json` (app, bundle, versão, URL scheme, arquivos publicados), que o app regrava na abertura; `AppGroup.manifests()` lista os apps presentes. O retrato dos widgets fica em `cashly/widget-snapshot.json`. O banco SwiftData continua no contêiner do app (mover para o grupo exigiria migração e exporia o banco às extensões).
- **Retrato do mês para widgets.** `WidgetSnapshot` (domínio, `Codable`) resume o mês corrente do perfil selecionado: planejado, gasto, receita e uma linha por orçamento (categoria, cor, símbolo, planejado, gasto). `FinanceModel.publishSnapshot()` recalcula pelo `overview` do mês corrente (não pelo filtro da tela) a cada `datasetRevision` e grava em `widget-snapshot.json` no App Group via `WidgetSnapshotStore`; sem perfil, apaga. Os vencimentos entram na 9.3, com os widgets.
- **`CashlyServices` no `AppShell`:** abre o banco uma vez por processo (`database(cloudSync:)`) e entrega `workspace()` com os repositórios e o perfil selecionado, sem janela. O `CashlyBootstrap` do app passou a usar o mesmo serviço, então App Intents e o app compartilham um único `ModelContainer`.

## 12/10/2026: pendências antes de distribuir

- **"Quem pagou" saiu da criação.** O modo atribuía zero a todos e a interface prometia dívida. O seletor de divisão só mostra `payerBased` quando o registro já usa esse modo (registros antigos não são convertidos), e a descrição passou a dizer o que o modo faz de verdade: você pagou tudo e não há parte registrada para os outros. Modelar pagador e dívida fica para a fase 10 (acerto de contas com Pix).
- **Resolução de conflito com carimbo monotônico.** `resolveBudgetConflict` grava `max(agora, maior carimbo já visto + 1)`, então quem resolve depois de ver a resolução anterior sempre vence, mesmo com o relógio atrasado; dois aparelhos que resolvem sem se ver continuam decididos por carimbo e token. Teste em `ScenarioTests`.

## 12/10/2026: dicas com TipKit (fase 8.6)

- **Cinco dicas, cada uma no seu target.** Sequência em dia sem gastos e escolher um desafio (`FeatureJourney`), deslizar para excluir e dividir um gasto (`FeatureTransactions`), conectar o Claude Code (`FeatureMCP`, mostrada pelo `MCPSettingsSlot` do `AppShell`). Dicas de Siri e widgets ficam para quando esses recursos existirem (fase 9).
- **Regras por evento e parâmetro.** `CashlyTips` no `FeatureCore` guarda os eventos compartilhados: `transactionSaved` (doado pelo editor depois de salvar) e `journeyOpened` (doado ao abrir a aba). As dicas aparecem depois de 2 a 10 doações, e as de desafio e Claude Code somem quando já há desafio ou servidor ligado (`@Parameter` com tipo explícito, exigido pela macro).
- **Discrição.** `Tips.configure` com uma dica por dia e, fora do simulador, o estado no contêiner `iCloud.cashly`, para a dica fechada num aparelho não voltar no outro. `TipView` nas listas com fundo transparente; a de dividir é um `popoverTip` no botão de participantes da toolbar.
- **Desenvolvedor › "Mostrar todas as dicas na próxima abertura"** grava uma flag; na abertura seguinte o app zera o armazenamento e liga `showAllTipsForTesting` antes do `Tips.configure`, porque as duas chamadas só valem antes da configuração.

## 12/10/2026: Cashly Pro (fase 8.5)

- **Um só portão: `ProAccess` no ambiente (`\.pro`).** A `MainScreen` monta o valor com o `Entitlement` do `StoreModel` e a flag `pro`; `canWrite` é verdadeiro no teste grátis, na assinatura ativa ou com a flag desligada. As ações de escrita chamam `pro.perform { }`, que executa ou abre o paywall. As rotas de editor (`Route.requiresPro`) são barradas no `CashlyDestination`, então toolbar, linhas, menus e o menu de perfil ficam cobertos sem tocar em cada tela.
- **Modo leitura de verdade.** Sem assinatura ficam bloqueados: criar e editar transações, categorias, orçamentos, tags e perfis; excluir (deslizar, menu e seleção); resolver conflito de orçamento; importar backup e planilha; e as ações da Jornada. Continuam livres: ler tudo, exportar JSON e CSV, backups automáticos, apagar tudo, loja e Ajustes.
- **Claude Code respeita o bloqueio.** `MCPModel.canWrite` acompanha o ambiente; sem assinatura o importador devolve `ImportOutcome.locked` e a ferramenta `import_transactions` explica que precisa do Cashly Pro, sem abrir a folha de conferência.
- **Paywall nativo.** `PaywallScreen` usa `SubscriptionStoreView(productIDs:)` com os dois planos (o teste grátis vem da oferta introdutória), cabeçalho com coroa e três benefícios, botões de restaurar e cancelar, resgate de código no iOS/visionOS e links de termos e privacidade quando `CashlyTermsURL`/`CashlyPrivacyURL` estiverem no `Info.plist`. Toque no plano da loja abre o paywall; a folha de item ficou só para itens.
- **Quando aparece.** Uma vez por abertura, depois que o StoreKit respondeu e os dados carregaram, se não há assinatura: isso cobre o fim do onboarding (a folha abre meio segundo depois de fechar o onboarding) e a abertura sem assinatura. Além disso, sempre que uma ação bloqueada é tocada.
- **Ajustes › Cashly Pro** é a primeira linha dos Ajustes, com o estado (sem assinatura, teste grátis, ativa, expirada e a data), "Começar teste grátis"/"Assinar", gerenciar assinatura (folha nativa no iOS/visionOS, link no macOS), resgatar código e restaurar compras.
- **A Jornada pausa.** Sem assinatura a aba mostra "Jornada pausada" no topo e as ações abrem o paywall; XP e conquistas não mudam porque nada é registrado. A sequência ainda conta os dias perdidos durante a pausa — congelar o relógio da sequência fica no backlog.
- **Flag `pro`** (`Cashly Pro paywall`) desliga o portão por controle remoto ou pelo Desenvolvedor em DEBUG, para testar sem assinatura e para emergências na revisão.

## 12/10/2026: loja na Jornada e itens bloqueados (fase 8.4)

- **A loja mora na Jornada.** A seção "Loja" mostra os dois planos, o destaque do mês (coleção de ícones da estação: Carnaval, Festa Junina, Halloween, Natal, senão Verão) e "Ver a loja", que abre a `ShopScreen` agrupada (planos, ícones, personalização, ajudas) com "Restaurar compras" no fim. Cada item abre uma folha (`ShopItemScreen`) com símbolo, descrição, preço e o botão de compra; os planos mostram "7 dias grátis" e "Começar teste grátis".
- **A folha do item é um guia.** `ShopItemScreen` usa `GuideSheet` de uma página (sem os pontinhos, que o `GuideTopBar` esconde quando há só uma) com `GuidePage(verbatim:)`, a animação do grupo (`shopIcons`, `shopColors`, `shopHelps`, `pro`), as linhas "Preço" e "Depois da compra" e os botões "Comprar por X" / "Agora não"; comprado vira "Concluído". Pedido do usuário em 12/10/2026: a primeira versão com símbolo e botão estava feia.
- **`ShopAccess` no ambiente.** `MainScreen` injeta `\.shop` com os itens possuídos do `StoreModel` e um `open(_:)` que preenche `CashlyNavigation.shopItem`, apresentado como folha em qualquer aba. As features não dependem da `FeatureStore`: só do `ShopItem` do domínio.
- **Cadeados nos Ajustes.** Cada coleção de ícones carrega o seu `ShopItem`; a grade mostra o cadeado e, no toque, abre o item em vez de trocar o ícone. As cores metálicas e neon (`PremiumColor`, seção própria no seletor de cor) seguem a mesma regra. "Todos os ícones" conta como posse de todas as coleções.
- **Ajudas com regra no motor.** `Streak.restorable` guarda o tamanho da última sequência perdida por até 48 h, e o botão "Recuperar a sequência de n dias" só aparece nesse prazo. O primeiro desafio do mês é grátis; cada começo a mais consome uma troca (`GameProgress.rerolls` = créditos − usos), e sem troca o botão de trocar mostra cadeado e abre o item.
- **Itens sem conteúdo ficam escondidos.** Molduras, avatares extras, comemorações e sons têm `isAvailable = false` até existirem; não aparecem na loja nem nos destaques, mas continuam no catálogo e no App Store Connect.

## 12/10/2026: StoreKit (fase 8.3)

- **Catálogo no domínio.** `ShopItem` é um enum com o identificador de produto como `rawValue`, o grupo (planos, ícones, personalização, ajudas) e o tipo (assinatura, não consumível, consumível). As ajudas carregam um `ShopCredit` (congelamentos, recuperação de sequência, trocas de desafio). `Entitlement` (nenhum, teste, ativo, expirado) é o que as features consultam; `EntitlementProviding` e `PurchaseProviding` escondem o StoreKit delas.
- **`StoreModel` sem servidor.** Carrega os produtos, lê `Transaction.currentEntitlements` (itens possuídos e o plano com a maior validade) e escuta `Transaction.updates` desde a abertura do app, pela `MainScreen`. Teste grátis vem de `transaction.offer?.paymentMode == .freeTrial`; sem assinatura ativa, a validade mais recente entre os planos vira `expired`.
- **Consumíveis viram eventos da Jornada.** Cada compra grava um `GameEvent` com o `transaction.id` como chave, no perfil atual, antes de `finish()`; o `CashlyStore` ignora chaves repetidas. Sem perfil escolhido a transação fica sem terminar e é creditada na próxima entrega. Recuperar sequência aplica na hora da compra.
- **StoreKit atrás de um `StoreClient`.** O `StoreModel` fala com um protocolo pequeno (produtos, compra, direitos atuais, última transação, pendentes, concluir, sincronizar) e o `StoreKitClient` (actor) faz a ponte com o StoreKit 2, guardando as transações verificadas para o `finish()`. Os testes usam um cliente falso: compra, pendente e cancelada, reembolso, crédito único com quantidade, compra sem perfil, teste → ativo → expirado e restauração.
- **Sem `SKTestSession` nos testes do pacote.** Os testes do `CashlyKit` rodam sem app hospedeiro, e o `storekitd` do simulador recusa a sessão de teste porque o processo `xctest` não é um app instalado (`kLSApplicationNotFoundErr`). Fica no backlog um alvo de testes hospedado pelo app para exercitar o `Cashly.storekit` de verdade.
- **`Cashly.storekit`** em `Cashly/Cashly`, com os 22 produtos em BRL e o grupo Cashly Pro com 7 dias grátis, ligado ao esquema Production para compras no simulador.
- **visionOS** usa `purchase(confirmIn:)` com a primeira cena conectada, porque `purchase()` não existe lá.
- **Esquema Sandbox.** Igual ao Production, sem o `Cashly.storekit`: serve para testar compras na sandbox da App Store com uma conta de testador (Users and Access › Sandbox). O teste grátis dura 3 minutos e a assinatura mensal renova a cada 5 na sandbox.

## 12/10/2026: Metas no padrão do design system

- **O cartão "Orçamentos" em Metas ficou compacto:** sem o número gigante fora do grupo (ele continua só na tela Orçamentos, como "Resumo do mês"). Dentro do grupo: disponível em `amountRow` com a legenda "disponível de X planejado", chip com o percentual usado, barra de uso na cor da situação e a contagem de cada situação como chips. A linha "Ver os n orçamentos" é uma linha própria com chevron, e o rodapé diz quanto dá para gastar por dia até o fim do mês.
- **A barra empilhada por situação e a legenda de pontinhos saíram:** a barra de uso e os chips dizem a mesma coisa no padrão das outras telas.
- **Resumo do mês (tela Orçamentos):** o cartão reaproveita o mesmo componente sem o valor (o número grande já está no cabeçalho) e as linhas "Você pode gastar" e "Fora dos orçamentos" viraram linhas com badge, título, valor à direita e detalhe embaixo, sem `LabeledContent` empilhando.
- **Conflito de orçamento:** a tela usa `AdaptiveList`, mostra a categoria e o mês no topo, uma seção "Opção n" por orçamento (valor em `amountRow`, descrição e o botão "Manter este orçamento") e a explicação no rodapé. A seção "Conflitos de orçamento" nas listas usa `sectionTitle()` e a explicação no rodapé.
- **Legenda das categorias:** "R$ X planejado" em uma linha, encolhendo antes de quebrar.

## 12/10/2026: guias com animações Lottie

- **Título e texto no topo da página do guia** (`GuidePage`): primeiro o título e a mensagem, depois a animação, depois o conteúdo. Vale para tutoriais, guia da pontuação, importação de planilha e de backup, onboarding e aprovação do MCP.
- **Os cartões de exemplo saíram dos guias.** Cada página mostra uma animação Lottie sem fundo, em `GuideAnimationView(_:)`, com o JSON embutido em código (`CashlyResourceAnimation.json(named:)`, gerado), porque recursos de pacote SwiftPM não entraram no bundle do app em todos os builds; os `.json` de referência ficam em `scripts/animations/`. Os estados vazios continuam com os exemplos preenchidos.
- **Dependência nova:** `lottie-spm` (Airbnb), a primeira dependência externa do pacote, usada só pelo `FeatureCore`.
- **As animações são geradas por `scripts/animations.py`**, que escreve o JSON do Lottie e o arquivo Swift que o embute, a partir de formas simples (barras, anéis, círculos, estrela, check). As camadas têm o nome da cor da paleta (`olive`, `mustard`, `rust`, `orange`, `teal`, `denim`, `plum`, `brown`, `tint`, `ink`, `paper`) e o app substitui as cores em tempo de execução com `ColorValueProvider`, por isso a animação acompanha o modo escuro e a cor de destaque. Com "Reduzir movimento" a animação fica parada no último quadro. Para trocar uma animação por uma de um designer, basta substituir o JSON mantendo os nomes das camadas.
- **Animações:** `month`, `history`, `budgetPace`, `journey`, `budget`, `score`, `participants`, `splitModes`, `paid`, `table`, `file`, `done`, `connect`, `launch`, da loja `pro`, `shopIcons`, `shopColors` e `shopHelps`, e `capture` (registro rápido).
- **Tela de abertura** (`LaunchView`): a animação `launch` em loop (quadrado na cor de destaque, carteira creme e uma moeda caindo dentro) no lugar do indicador de progresso, com "Abrindo o Cashly" embaixo.
- **Ordem das camadas no Lottie:** a primeira camada da lista fica por cima; o gerador recebe as camadas de baixo para cima e inverte ao escrever.
- **Página curta:** título, texto, animação e no máximo três linhas de conteúdo; o que passa disso vira outra página (as faixas da pontuação e as colunas opcionais da planilha ganharam página própria). A folha nunca deve passar da altura da tela.

## 13/10/2026: animações com SF Symbols

- **As animações passaram a ser desenhadas só com glifos de SF Symbols**, no estilo dos gráficos de movimento da Apple: um símbolo herói no centro, símbolos de apoio escalonados em volta, movimento com ease-in-out e leve overshoot, entrada com escala 0,6→1 mais fade, respiração e flutuação suaves, transições de substituição (um símbolo encolhe e some enquanto outro cresce), rotação de partes, um símbolo pequeno orbitando, revelações com máscara e o visual monocromático com acento (cor de destaque mais `ink` em opacidade baixa e no máximo um acento secundário). Barras continuam barras (retângulos arredondados), sem anéis de progresso.
- **`scripts/symbols.swift` extrai os contornos** das fontes SF Pro instaladas: desenha cada símbolo com `NSImage` em modo monocromático e procura o glifo da fonte com a mesma silhueta (IoU de máscaras 40×40). O mapeamento nome → glifo fica em `scripts/symbols-map.json`, por isso o matching só roda para símbolos novos; o score sai no stderr e abaixo de 0,85 vale trocar o símbolo. O modo paleta não serve para o matching porque a camada interna fica da mesma cor e some o recorte.
- **`symbol(name, color, height, weight)` em `animations.py`** vira um grupo Lottie com um `sh` por subcaminho e um único preenchimento (nonzero), já em pixels; o binário é compilado em `$TMPDIR` quando a fonte muda. `scripts/animations-preview.html` mostra as 19 animações em grade, com os JSON embutidos (funciona de `file://`), tema claro/escuro recolorindo `ink` como o app faz, e botão de reiniciar.

## 13/10/2026: captura (9.2a)

- **Caixa de entrada no domínio.** `Capture` (valor em `Money`, estabelecimento, cartão, data, origem `wallet`/`share`/`manual`, sugestão de categoria, descrição e tags, estado `pending`/`accepted`/`dismissed`, vínculo com a transação e data de criação) e `MerchantMemory` (chave normalizada → última categoria, descrição, tags e contagem). A chave tira acentos e maiúsculas, troca tudo que não é letra por espaço (some o "*" e os números) e descarta palavras de uma letra e sufixos e prefixos de maquininha (`ltda`, `me`, `sa`, `pag`, `mp`, `ifd`, `cielo`, `stone`…); se não sobrar nada, vale o texto original em minúsculas. Duas capturas são a mesma quando têm o mesmo dono, valor, chave e minuto (`Capture.isDuplicate(of:)`).
- **Schema V5.** `CaptureEntity` (índices por dono/estado/data e dono/chave/minuto) e `MerchantMemoryEntity` (dono/chave), ambas com valores padrão para o CloudKit; V4 congelado em `CashlySchemaV4.swift` como as anteriores e migração leve V4 → V5. O `CaptureRepository` (listar por estado, buscar, salvar, memória, lembrar) entra em `Repositories.captures`; `saveCapture` atualiza quando o id já existe, devolve a captura gêmea quando é duplicata e só insere quando é nova. "Apagar tudo" também limpa capturas e memória; o backup não as exporta (são transitórias).
- **`CaptureActions` no `FeatureCore`.** `capture(amount:merchant:card:date:)` grava e devolve `(capture, isNew)`; a sugestão vem da memória do estabelecimento e, sem memória, da categoria mais usada no mês corrente (contagem de gastos, até 500). `accept(captureID:categoryID:)` cria o gasto quitado pelo mesmo `IntentActions.addExpense` da Siri (tags da memória só se ainda existirem), liga a captura à transação e reforça a memória (`count + 1`); aceitar de novo devolve a transação já ligada. `dismiss` só muda o estado. Capturar não exige Cashly Pro; aceitar passa pelo mesmo `canWrite()` do `AddExpenseIntent` (no intent, no `NotificationResponder` e na rota do editor).
- **`CaptureTransactionIntent`** (valor, estabelecimento, cartão e data opcionais) roda em segundo plano sem abrir o app: grava, registra as categorias de notificação, entrega a notificação só quando a captura é nova e atualiza o contador do ícone. Frase "Capture a payment in Cashly" no `CashlyShortcuts`, traduzida no `AppShortcuts.xcstrings`.
- **Notificação por captura com ações dinâmicas.** Como as ações de uma `UNNotificationCategory` são fixas no registro, `CaptureActionGroup` gera uma categoria por categoria do perfil (`cashly.capture.<id>`, com a sugerida marcada com ✓ e as duas mais usadas do mês) mais uma sem sugestão (`cashly.capture`); todas terminam com "Outra…" (abre o app em `cashly://captures/<id>`, que leva ao editor preenchido pela rota `Route.classifyCapture`) e "Ignorar". As ações que gravam exigem desbloqueio (`authenticationRequired`). O conjunto é registrado de novo pelo intent antes de notificar e pelo `MainScreen` a cada revisão dos dados (`NotificationsModel.reviewCaptures`, junto com o Spotlight), que também grava o contador de pendentes no ícone (`setBadgeCount`). Salvar pelo editor preenchido liga a captura e reforça a memória do mesmo jeito.
- **Fora desta etapa:** a lista "Para classificar" no app, o guia e os Ajustes de captura, a folha de compartilhamento e a ferramenta MCP (9.2b a 9.2d em `capture.md`).

## 13/10/2026: paywall

- **Cabeçalho do Cashly Pro no estilo dos guias.** A animação `pro` (coroa com brilhos, `CashlyAnimationView`) no lugar do badge estático, o título e a linha do teste grátis como `Chip` mostarda. O grupo cinza de três linhas virou quatro cartões tingidos (`tintedCard`) com `SymbolBadge` na cor retrô de cada benefício: registrar e editar (laranja), análise (teal), Jornada (mostarda) e backups, iCloud e Claude Code (denim). O rodapé do modo só leitura continua como legenda discreta.
- **Locale e cor de destaque passados à mão.** O StoreKit desenha o conteúdo de marketing fora da hierarquia que recebe `.environment(\.locale)` e `.appTint`, então com idioma do app diferente do sistema os textos saíam no idioma do sistema. A tela lê `@Environment(\.locale)` e `@Environment(\.appTint)` e aplica os dois na raiz do cabeçalho; com isso os textos voltaram a ser `Text` com chave e saíram os `String(appLocalized:)`.

## 13/10/2026: simulação da loja no menu de desenvolvedor

- **Seção "Loja" em Ajustes › Desenvolvedor (só em builds DEBUG):** um seletor "Cashly Pro" com Real (StoreKit) / Grátis / Teste / Pro, a linha com o direito em vigor, a página "Itens da loja" com um interruptor "possui / não possui" para cada `ShopItem` que não é plano (20 itens, inclusive os consumíveis) e o botão "Redefinir simulação". O rodapé mostra o estado em vigor ("Simulando: Pro") e avisa que a simulação só existe em builds de desenvolvimento.
- **A simulação mora no `StoreModel`, não na tela.** `owned` e `entitlement` viraram propriedades calculadas: devolvem `simulation?.owned`/`simulation?.entitlement` quando há simulação e, senão, `storeOwned`/`storeEntitlement`, que continuam alimentadas só pelo StoreKit (`refresh` nunca toca a simulação). Assim a porta do `ProAccess`, o paywall, as travas da loja, de ícones e cores e a Jornada reagem exatamente como numa compra real. A lógica fica em `StoreModel+Simulation.swift` dentro de `#if DEBUG`; fora de DEBUG `StoreSimulation.stored(in:)` devolve `nil` e nada muda.
- **Começar a simular parte do estado real:** o primeiro ajuste copia o plano e os itens do StoreKit (teste ativo vira "Teste", assinatura ativa vira "Pro", o resto "Grátis") e muda só o que foi tocado. "Teste" vence em 3 dias e "Pro" renova em 30, para a tela do Pro mostrar as datas como numa assinatura de verdade. Escolher "Real" apaga a simulação inteira.
- **Persistência em `UserDefaults`** nas chaves `cashly.developer.store.plan`, `.expires` e `.owned` (o `StoreModel` recebe o `UserDefaults` no `init`, `.standard` por padrão), por isso "Apagar preferências" também a remove e o teste usa uma suíte própria.

- **Paywall próprio, sem `SubscriptionStoreView`.** A segunda versão troca a tela nativa por uma `ScrollView` com a estrutura das telas de assinatura premiadas, adaptada ao design system: (1) herói com a animação `paywall` (coroa que sobe com overshoot, três brilhos orbitando e cartão, gráfico e nuvem entrando escalonados; gerada por `scripts/animations.py` como as outras), título, a frase de resultado "Your whole month, without limits" e o `Chip` do teste grátis; (2) tabela Grátis × Pro num cartão com a coluna Pro tingida de mostarda (padrão do Hevy), seis linhas com `checkmark.circle.fill` oliva ou um texto curto quando não é binário — a tabela segue o que o `ProAccess` bloqueia de verdade: registrar e editar ("Trial only"), orçamentos, análise e backups/importação/Claude Code ("Read-only", porque ler e exportar continuam abertos), Jornada ("Paused") e widgets, Siri e exportação liberados nos dois; sincronização com iCloud ficou de fora da tabela porque não é bloqueada; (3) linha do tempo do teste com três `SymbolBadge` ligados por uma linha vertical — hoje, dia 5 e dia 7 (padrão do BoldVoice), mostrada só quando a oferta introdutória está disponível; (4) cartões de plano próprios, anual primeiro e pré-selecionado com `Chip` "Best value", economia calculada contra 12 mensalidades e o valor equivalente por mês (padrão do Zinnia); (5) botão principal orientado ao benefício, "Start 7-day free trial" ou "Subscribe", com a linha "Then R$ 99,90/year. Cancel anytime." embaixo e progresso durante a compra; (6) rodapé de links pequenos: restaurar, resgatar código (iOS e visionOS), termos e privacidade quando houver URL no `Info.plist`. Botão principal e rodapé ficam numa `safeAreaBar` inferior; o X de fechar fica na toolbar.
- **`StoreProduct` descreve o plano.** Além do preço exibido, o produto carrega `price`, `priceStyle` (o `priceFormatStyle` do StoreKit, para o valor mensal equivalente na moeda da loja), o `period` (mês ou ano) e os `trialDays` da oferta introdutória gratuita. `StoreClient.isEligibleForIntroOffer` entra no protocolo e o `StoreModel` guarda `introEligible`, `selectedPlan`, `isBuying` e `isPending`; `subscribe()` e `restoreSubscription()` concentram o fluxo e a view só desenha. `PaywallPlan` (em `StoreModel+Plans.swift`) calcula a economia e o valor por mês.
- **Lembrete antes da cobrança.** Quando chega uma transação de teste grátis de um plano, o `StoreModel` agenda pelo `NotificationScheduling` do `FeatureCore` (injetado, `SystemNotifications` por padrão) uma notificação local 2 dias antes do fim do teste ("Your Cashly Pro trial ends in 2 days"), pedindo a permissão na hora se ainda não foi decidida. O prefixo `trial` substitui o lembrete anterior, então repetir a transação não duplica nada.
- **Locale e tint voltam a ser herdados.** Como o conteúdo agora está todo na hierarquia da folha, a propagação manual de `.locale` e `.appTint` da nota anterior deixou de ser necessária: a folha herda os dois da raiz da janela (`cashlySettings`).

## 13/10/2026: sobre

- **"Sobre o Cashly" virou uma história, no nível do paywall.** `AboutScreen` (FeatureSettings) substitui as seções `AboutSection` e `HelpSection` por uma `ScrollView` com: (1) herói com a animação `about` em loop, o nome, a frase "Your whole month, in your pocket" e o `Chip` da versão; (2) quatro cartões com `SymbolBadge` preenchido, no padrão das telas de créditos premiadas (Flighty, Gentler Streak, Bears Gratitude contam quem fez e de onde): o mês de relance (oliva), registrar num toque (cor de destaque), os dados continuam seus (denim, com o texto que antes era rodapé: sem servidores, iCloud opcional, sugestões no aparelho) e feito por uma pessoa só no Brasil (mostarda; fato verificado pelo histórico do repositório e pelos docs, sem inventar equipe); (3) "Share Cashly with a friend" como `primaryButton()`: `ShareLink` com a URL da App Store, mensagem e `SharePreview` com o ícone atual do app, e, sem `CashlyAppStoreID` no `Info.plist`, compartilha só o texto; (4) grupo de linhas `IconRow` com seta: avaliar (abre a URL de avaliação e, sem ela, chama `requestReview`), Novidades (`WhatsNewScreen`), contato, central de ajuda, privacidade e termos, cada uma só quando a chave existe no `Info.plist` (`AppInfo.links`, uma lista de `AboutLink`); (5) rodapé discreto com versão e build e "Made in Brazil". `.fontDesign(.rounded)` na tela inteira, como no paywall.
- **Animação `about`, a mais rica do conjunto:** reconstrói o ícone clássico com formas e glifos: base creme arredondada que respira, cartão na cor de destaque, cifrão creme em negrito, bolso creme com a cava central (caminho próprio `pocket_path`, cantos concêntricos) e o brilho mostarda no canto, meio escondido pelo cartão como no ícone. A cada volta uma moeda `dollarsign.circle.fill` cai pela cava com aceleração de gravidade (`FALL`), o bolso amassa e volta, e os símbolos de apoio (gráfico oliva, troféu mostarda, cartão denim e um brilho pequeno) flutuam e dão um pulo em cascata na aterrissagem. Sem entrada: tudo já está em cena no quadro 0 e volta ao mesmo lugar no 150, então o loop não tem emenda.
## 13/10/2026: metas

- **Metas virou a tela dos orçamentos.** A aba segue a estrutura das telas de orçamento premiadas (Copilot, YNAB, Monarch) adaptada ao design system: (1) cabeçalho do mês com o `Chip` do período, o valor disponível em `amountHero` (rust quando estourou) e a legenda "available of X planned"; (2) cartão do ritmo: percentual usado na cor da situação, "Day n of m", barra de uso tingida (`.positive/.warning/.negative`) com um marcador vertical na posição do dia de hoje (a versão em barra do indicador de ritmo do Copilot), a frase do ritmo (`BudgetOverview.Pace`: "Over the plan", "Spending faster than the month", "On pace with the month", "Spending slower than the month" — compara o percentual usado com o percentual do mês passado, com folga de 10 pontos) e o detalhe "x% of the plan used, y% of the month gone."; (3) três números lado a lado: planejado, gasto e restante (ou "Over"); (4) a linha "You can spend X per day" (ou "Nothing left to spend" quando acabou) e "Outside budgets"; (5) os orçamentos agrupados por situação, cada grupo com o símbolo, o título e um `Chip` com a contagem; cada linha com o badge da categoria, restante na cor da situação, barra que preenche ao abrir (respeita Reduzir movimento), "gasto de planejado" e o percentual; (6) as categorias sem orçamento em cápsulas para criar na hora; (7) a lista de categorias continua no fim (tocar edita, deslizar apaga). O + da barra virou um menu com "New Budget" e "New Category".
- **Estado vazio com Lottie.** Sem orçamento no mês, a lista começa com a seção vazia: animação `goals` (bandeira quadriculada que entra com overshoot, três barras que crescem, check oliva e brilho; gerada por `scripts/animations.py`), título, explicação e o `primaryButton()` "Create Budget". As cápsulas das categorias e a lista de categorias ficam logo abaixo, então nada deixa de ser alcançável. Sem categoria, continua o estado vazio `.category` de tela inteira.
- **Tela Orçamentos (`Route.budgets`) reaproveita as mesmas seções** (vazio, cabeçalho do mês, grupos e cápsulas) para o deep link `cashly://budgets` dos widgets e o inspetor no iPad e no Mac; `BudgetsOverviewSection`, o cartão compacto e os chips de contagem saíram. Ritmo, dia do mês e `dayOfMonth`/`elapsedRatio` vivem no `BudgetOverview`, com testes.
## 13/10/2026: loja

- **A loja mostra o que vende.** A lista (`ShopScreen`) deixou de ser uma `List` de linhas com símbolo e virou uma `ScrollView` com cartões em grade (`LazyVGrid` adaptativa, duas colunas no iPhone e três na largura legível), um grupo por título de seção: ícones, personalização e ajudas da Jornada. Cada cartão tem uma prévia real em cima (`ShopCardPreview`): os pacotes de ícones mostram os quatro ícones de verdade (`AppIconImage`, 2×2; "Todos os ícones" mostra o primeiro ícone de cada um dos nove pacotes, 3×3), as cores mostram as quatro amostras do `PremiumColor` e as ajudas tocam uma animação Lottie própria; embaixo, o nome, a frase de resultado em uma linha (`ShopItem.outcome`) e um `Chip` com o preço na cor do grupo ou "Owned" em oliva, seguindo o `ShopAccess`/`ShopCatalog.owns` (quem tem "Todos os ícones" vê todos os pacotes como possuídos). O Cashly Pro ficou num cartão único no topo com a animação `pro`, a frase do paywall e um `Chip` com o estado (dias grátis, "Ativo", "Teste grátis" ou "Ver planos"); tocar abre o paywall como antes. O rodapé continua com "Restaurar compras" e a nota da conta Apple. Referências: galeria de ícones do Apollo (coleções em grade, uma tela por coleção), lojas de cosméticos de jogos (prévia do item no contexto real, "o que você recebe", preço explícito, comprar vira "possui") e as diretrizes de IAP da Apple e do Google (preço visível antes de qualquer confirmação).
- **Comprar um item segue a mesma hierarquia do paywall.** `ShopItemScreen` é uma folha com a altura do conteúdo (detent medido como no `GuideSheet`) e a estrutura da tela do Pro: (1) X no canto, (2) herói com a prévia real em tamanho grande — os quatro ícones com nome, as quatro cores com nome, a grade 6×6 para "Todos os ícones" ou a animação da ajuda —, título, frase de resultado e um `Chip` cápsula com o grupo ("App Icons", "Journey Helps"…) ou "Owned" em oliva — o preço fica só no cartão e no botão; (3) cartão "o que você recebe" com três linhas e `SymbolBadge` preenchido (o que é, onde usar, por quanto tempo; nas ajudas, a quantidade creditada neste perfil e que não vence); (4) cartão de preço tingido na cor do grupo com "Compra única" ou "3 usos" à esquerda e o valor à direita; (5) um único `primaryButton()` — "Buy for R$ X", "Owned" (desabilitado, com check) ou "Restore" quando o StoreKit não carregou o produto — com a nota de aprovação familiar quando a compra fica pendente; (6) rodapé de links pequenos: restaurar, termos e privacidade (`StorePolicy` ficou público no `FeatureStore`).
- **Um caminho só no `StoreModel`.** `subscribe()` virou `buy(selectedPlan)`: `buy(_ item:)` liga `isBuying`, chama `purchase`, guarda os itens pendentes em `pending` (`isPending` passou a ser calculado sobre os planos, então o paywall não mudou) e devolve se comprou. `restoreSubscription()`, `restoreItem(_:)` e `restoreItems()` passam pelo mesmo `restoreQuietly()`. `owns(_:)` saiu da extensão da Jornada e entrou no model.
- **`AppIcon` e `AppIconImage` foram para `FeatureCore/Icons`** porque a loja (`FeatureJourney`) e os Ajustes precisam dos mesmos ícones e uma feature nunca importa outra; `AppIcon.icons(of:)` devolve os ícones de um `ShopItem`. `ShopThumbnail` usa a mesma prévia em miniatura nas linhas da seção "Loja" da Jornada.
- **Animações novas:** `shopFreeze` (chama que vira floco com escudo), `shopRestore` (seta que gira e reacende a chama) e `shopReroll` (bandeira some, dado cai e outra bandeira entra), geradas por `scripts/animations.py`; `shopHelps` continua como animação do grupo.
- **Link `cashly://shop`** (e `cashly://shop/<id do item>`, como `cashly://shop/cashly.icons.sports`) abre a loja na aba Jornada e, com o id, a folha do item; entra em `DeepLinks` ao lado de `transactions`, `captures` e `budgets`, para notificações e atalhos futuros e para a verificação no simulador. Em builds DEBUG, o argumento de execução `-cashly.developer.openURL cashly://shop` (`xcrun simctl launch … -cashly.developer.openURL "cashly://shop/cashly.icons.sports"`) abre o mesmo link logo na abertura, sem a confirmação "Abrir no Cashly?" do `simctl openurl` e sem toques; a simulação da loja fica no `com.byescaleira.cashly.plist` do contêiner do app (não no domínio global do dispositivo que o `simctl spawn defaults` escreve).
## 13/10/2026: guias

- **Central de guias no lugar da lista.** Ajustes › Guias virou `GuidesHubScreen` (`FeatureSettings`), uma `ScrollView` no padrão do paywall: (1) cartão de progresso com "3 of 14 guides done", os minutos que faltam, barra linear (sem anel) e a lembrança de que concluir todos libera a conquista "Studious"; (2) cartão "Next for you" com a animação Lottie do próximo guia não lido, título, frase de resultado e o botão `primaryButton` "Start · 2 min" (com tudo lido, a animação `done` e um convite a reler); (3) sete categorias (Start Here, Recording, Budgets and Goals, Analysis, Journey, Automation, Data and Privacy), cada uma com a contagem "feitos/total" e um cartão por guia: miniatura Lottie parada no último quadro (`CashlyAnimationView(isStill:)`, para não rodar 14 animações ao mesmo tempo), título, resultado em uma linha, duração e um check oliva quando concluído. A ordem dos cartões é a ordem de `Guide.allCases`, que também define a sugestão do "próximo". Referências: o app Dicas da Apple (coleções por tema), as listas "Get Started" do Things e do Craft (cartão com miniatura e resultado) e a regra do TipKit de títulos curtos orientados à ação; evitei porcentagem no cabeçalho porque relatos de desenho dizem que ela faz a lista parecer obrigatória — fica "x of y" e a barra.
- **`GuidesModel` lê o que já foi concluído** dos eventos `guideCompleted` do `GameRepository` (os mesmos que alimentam o XP e a conquista), com `next`, `fraction`, `remainingMinutes` e a contagem por categoria; a tela recarrega com `.task(id: session.generation)`, então concluir um guia atualiza o hub assim que a folha fecha. Teste em `GuidesModelTests`.
- **`Guide` ganhou `category`, `animation` e `minutes`** e passou de 6 para 14 casos: `tour`, `recording`, `sharing`, `bills`, `budgets`, `score`, `insights`, `journey`, `widgets`, `siri`, `quickCapture`, `backups`, `privacy`, `importSpreadsheet`. Os ids antigos não mudaram (são os valores gravados nos eventos e contados pela conquista); o total de `Guide.allCases` continua sendo o `guideCount` do motor, então "Studious" agora pede os 14. `GuideCategory` fica em `FeatureCore/Guide`.
- **Os tutoriais são páginas estáticas** (`TutorialPage`: animação, título e texto) separadas por categoria em `Tutorial+Recording`, `Tutorial+Planning`, `Tutorial+Automation` e `Tutorial+Data`, com frases específicas do app (os horários da notificação, as frases da Siri, o gatilho "Transação" do Atalhos, os nomes dos widgets, as regras de XP). A folha de compartilhamento fica de fora até existir (9.2c). `GuideScreen` continua decidindo entre o fluxo de importação, o guia da pontuação e o tutorial.
- **Onze animações novas** em `scripts/animations.py`, no mesmo vocabulário de SF Symbols: `backup`, `bills`, `discreet`, `editor`, `insights`, `missions`, `privacy`, `siri`, `streak`, `tags` e `widgets` (esta com retângulos no lugar de glifos, porque os símbolos `widget.*` não têm contorno confiável). As funções entraram em ordem alfabética entre as cenas, a tabela `ANIMATIONS` e o enum `CashlyAnimation` passaram a ter uma entrada por linha para facilitar merges paralelos.

## 14/10/2026: App Intents não registravam no aparelho

- **Sintoma:** nenhum App Intent do Cashly funcionava no iPhone (Central de Controle, Tela Bloqueada e Botão de Ação não abriam o app; o Botão de Ação dizia "something went wrong"; as ações sumiram do app Atalhos; o widget configurável ficava em placeholder).
- **Causa:** em Debug o Xcode compila o app como um executável "stub" mais `Cashly.debug.dylib` (`ENABLE_DEBUG_DYLIB`). O `linkd`, que registra os intents no sistema, procura no executável principal o símbolo do `AppIntentsPackage` declarado nos metadados (`CashlyIntentsPackage`, do pacote `AppShell`); como ele está no dylib, o log mostra `metadata '_$s8AppShell20CashlyIntentsPackageV' did not match any imported or exported symbol` e o sistema descarta os metadados do app inteiro. Em Release não acontece porque não há debug dylib.
- **Correção:** `ENABLE_DEBUG_DYLIB = NO` nos alvos do app e da extensão (as previews do Xcode continuam funcionando, só ficam um pouco mais lentas para recompilar). Verificar sempre com `nm -gU Cashly.app/Cashly | grep CashlyIntentsPackage` e no log do `linkd`.
- **Controle "Novo gasto"** passou a usar `OpenURLIntent(cashly://transactions/new)` direto, sem intent próprio: um intent com `openAppWhenRun` roda no processo do app, então precisaria existir também no alvo do app.
- A desconfiança anterior sobre o Spotlight (`IndexedEntity`) estava errada e foi desfeita.

## 14/10/2026: jornada

- **Crítica da tela anterior:** o topo repetia o XP que falta duas vezes (legenda e linha) e a escada de 10 títulos virava tracinhos ilegíveis; a chama da sequência ficava cheia mesmo com 0 dias, recorde e congelamentos se espremiam numa legenda e "Hoje está feito" ocupava uma linha que parecia botão; a recompensa das missões só aparecia depois de concluir e não havia quando chegam as próximas; sem desafio, a seção era só um botão; o desafio ativo não dizia quantos dias faltam nem se o gasto está no ritmo (num teto, a barra que enche parecia coisa boa); as conquistas eram nove grades sem nenhuma prévia do que está perto.
- **O que mudou:** cabeçalho com o XP total e, no grupo, "x de y XP" na cor de destaque, o que falta e a barra entre os chips do nível atual e do próximo; a escada mostra só os 5 níveis do título atual, com o título atual e "faltam n níveis". Sequência com a situação do dia sob a contagem (chama em contorno quando o dia ainda não foi feito), recorde e congelamentos lado a lado e a próxima marca de constância com barra. Missões com "+25 XP" sempre visível e "Missões novas em n dias". Sem desafio, os cinco tipos viram linhas com XP que abrem o seletor no tipo tocado; o seletor também mostra símbolo, duração e XP de cada tipo. Desafio ativo com dias restantes e, nos de gasto, marcador do dia do mês, valor gasto do teto e ritmo nas cores de Metas. Conquistas com as três mais próximas em linhas com barra e as começadas tingidas na grade com uma barrinha. Entradas em cascata (`cascade`), barras que preenchem ao abrir (`FillingBar`) e `symbolEffect` no medalhão, na chama e no desafio; tudo desligado com Reduzir movimento. Ordem das seções mantida (nível, sequência, missões, desafio, conquistas, loja): o que muda todo dia fica em cima.
- **Lógica no model:** `JourneyModel+Progress` calcula `rankSteps`, `levelsToNextRank`, `streakMilestone`, `daysUntilNewMissions`, `challengeOutlook` (progresso, dias restantes, fração do mês e ritmo `steady/fast/over` com folga de 10 pontos, como em Metas), `challengeSuggestions`, `nextAchievements` e `AchievementState.isStarted`; textos em `JourneyModel+Text`. Testes em `JourneyProgressTests`.
- **Verificação sem toques:** em builds DEBUG, `-cashly.developer.seed YES` carrega os dados de exemplo na abertura e `cashly://journey` abre a aba (também via `-cashly.developer.openURL`). Os dados de exemplo ganharam eventos da Jornada (`SampleData.gameEvents`: sequência de 11 dias com um dia coberto, recorde de 18, guias e um desafio de teto em Restaurantes) para a aba não abrir vazia nos previews e no simulador.
