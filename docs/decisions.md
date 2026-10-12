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
- **UI só em pt-BR**, com String Catalog por target.
- **`CashlyAudit` como ferramenta de diagnóstico e validação automatizada** (comando `check`), separada dos testes.

## 08/10/2026: visual

- **Visual nativo mantido.** Duas propostas de identidade nova foram testadas e rejeitadas (inspirada no Claude e o design system byescaleira). O app segue com `List`/`Form`, vidro e cores do sistema.
- **Diretrizes da Apple acima de qualquer design system.** Um design system só veste componentes nativos (cor, fontes, conteúdo); navegação, títulos, formulários e folhas ficam como o sistema define.
- **`AdaptiveList`.** As telas de painel recebem as mesmas `Section` de uma `List` e se dividem em colunas quando a largura permite (iPad, iPhone em paisagem, dobrável). Transações continua `List` por causa de swipe e seleção.
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
- **Guias com exemplos, sem ícones nem ilustrações:** cada página mostra um exemplo preenchido e simplificado da própria feature, montado com os componentes do app (`GuideExample`, `ExampleRow`, `ExampleBar`, `ExampleChip`, `ExampleHeadline`, `ExampleFile`, `ExampleDone`): resumo do mês, histórico, barras de uso, busca, orçamento, pontuação, divisão, planilha, arquivo e conclusão. Onde há dados reais (pontuação atual, linhas da planilha, cliente do MCP), o exemplo usa esses dados. As ilustrações ficam só nos estados vazios.
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

