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
