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
