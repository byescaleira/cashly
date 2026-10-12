# Design system

O `CashlyDesignSystem` é o único lugar com valores visuais: espaçamentos, raios, opacidades, tamanhos, tipografia, cores e componentes sem regra de negócio. As features usam só os tokens. Número solto de espaçamento, raio, opacidade ou tamanho de fonte fora do design system é erro de lint (`design_token_*` em `.swiftlint.yml`).

O pacote não depende de nenhum outro módulo do app. Componentes que precisam de dados ou de formatação do app (moeda, categoria) ficam no `FeatureCore` e montam os do design system. Por exemplo, `FigureHeader(title:amount:)` e `FigureBlock(caption:amount:)` são atalhos do `FeatureCore` que formatam o valor em moeda, e `ExampleMonthSummary` fica no `FeatureCore` porque mostra valores em moeda.

## Tokens

### Espaçamento (`CGFloat`)

| Token | Valor | Uso típico |
| --- | --- | --- |
| `.spaceHairline` | 2 | Texto e legenda colados |
| `.space2XS` | 4 | Linhas de texto num mesmo bloco, padding vertical de chip |
| `.spaceXS` | 6 | Ícone e texto pequenos |
| `.spaceS` | 8 | Itens de um mesmo grupo |
| `.spaceM` | 12 | Ícone e conteúdo de uma linha, blocos de um cartão |
| `.spaceL` | 16 | Padding de cartão, blocos de uma página |
| `.spaceInset` | 20 | Margem das listas e recuo das linhas agrupadas |
| `.spaceXL` | 24 | Entre seções e páginas dos guias |
| `.space2XL` | 32 | Respiro de destaque |

### Raio (`CGFloat`)

| Token | Valor | Uso |
| --- | --- | --- |
| `.radiusS` | 8 | Chips e tags |
| `.radiusM` | 16 | Blocos e cartões internos |
| `.radiusL` | 22 | Cartões de exemplo e de destaque |
| `.radiusGroup` | 26 | Grupos das listas adaptáveis |

### Opacidade (`Double`)

| Token | Valor | Uso |
| --- | --- | --- |
| `.opacityFill` | 0,12 | Fundos neutros e blocos tingidos |
| `.opacityTint` | 0,2 | Fundo de chip e de badge na cor do conteúdo |
| `.opacitySoft` | 0,35 | Partes secundárias de barras e gráficos |
| `.opacityStrong` | 0,8 | Elementos quase opacos sobre cor |
| `.opacityHidden` | 0,02 | Campos invisíveis que ainda recebem foco |

### Tamanho (`CGFloat`)

| Token | Valor | Uso |
| --- | --- | --- |
| `.badgeS` | 28 | Badge de símbolo em blocos pequenos |
| `.badgeM` | 36 | Badge em linhas compactas e exemplos |
| `.badgeL` | 44 | Badge em linhas de lista (alvo de toque mínimo) |
| `.barHeight` | 10 | Barras de progresso e segmentadas |
| `.rowHeight` | 44 | Altura mínima das linhas |

### Tipografia (`Font`)

Os estilos de texto do sistema (`.headline`, `.subheadline`, `.footnote`…) continuam sendo usados direto, com Dynamic Type. Os tokens cobrem as combinações repetidas:

| Token | Definição | Uso |
| --- | --- | --- |
| `.amountHero` | `largeTitle` black | Valor principal de uma seção |
| `.amountTitle` | `title` bold | Valor de destaque dentro de cartão |
| `.amountRow` | `title3` bold | Valor em blocos e linhas fortes |
| `.amountInput` | 40 pt black | Campo de valor dos editores |
| `.chipLabel` | `caption` bold | Texto de chip |
| `.rowTitle` | `body` semibold | Nome numa linha de lista |
| `.buttonLabel` | `body` semibold | Rótulo de botão e de menu |
| `.titleLarge` | `title` bold | Título de página dos guias |
| `.titleMedium` | `title2` bold | Título de estado vazio e de bloco |

`sectionTitle()` define o título das seções.

### Ícones (`IconSize`)

Símbolos com tamanho fixo usam `.font(.icon(_:weight:))`, nunca `.system(size:)`:

| Caso | Valor | Uso |
| --- | --- | --- |
| `.xs` | 10 | Indicador dentro de outro símbolo |
| `.s` | 18 | Ícone de linha |
| `.m` | 20 | Ícone de escolha (categorias, avatar) |
| `.l` | 30 | Ícone de destaque numa linha |
| `.xl` | 50 | Ícone do editor |
| `.hero` | 130 | Ícone de fundo do editor de tag |

### Cores

- **Paleta retrô:** `.retroMustard`, `.retroOrange`, `.retroRust`, `.retroOlive`, `.retroTeal`, `.retroDenim`, `.retroPlum`, `.retroBrown`, cada uma com versão clara e escura.
- **Semânticas:** `.positive`, `.negative`, `.warning`, `.info`, `.disabled`, `.subtleFill`, `.rowFill`.
- **Superfícies:** `.groupedBackground`, `.groupedRow`, `.sheetBackground`, `.sheetCard`.
- **Destaque do app:** `@Environment(\.appTint)` e `.appTint(_:)`.

## Componentes

| Componente | O que é |
| --- | --- |
| `Chip(_:color:shape:font:)` | Texto na cor com fundo `.opacityTint`; `.tag` (raio 8) ou `.capsule` |
| `SymbolBadge(_:color:size:style:)` | Símbolo num círculo, `.tinted` ou `.filled` |
| `tintedCard(_:radius:)` | Fundo `.opacityFill` na cor, para blocos |
| `FigureHeader(title:value:numeric:color:detail:)` | Cabeçalho de seção com o número grande fora do grupo |
| `FigureBlock(caption:value:numeric:color:detail:)` | Número grande com legenda dentro de um cartão |
| `FigureValue(_:numeric:color:)` | Só o número, com troca animada |
| `GuideExample` | Cartão dos exemplos preenchidos (guias e estados vazios) |
| `ExampleRow`, `ExampleBar`, `ExampleHeadline`, `ExampleDone`, `ExampleFile` | Peças dos exemplos |
| `surface(tint:in:interactive:)` | Vidro regular (Liquid Glass) |
| `clearSurface(in:)` | Vidro transparente, para elementos sobre conteúdo |
| `contentSurface(tint:in:)` | Fundo neutro sem vidro |
| `prominentButton()` | Botão principal em vidro |
| `amountLine()` | Valor em uma linha, encolhendo até a metade |
| `AdaptiveList`, `AdaptiveStack`, `AdaptiveRow` | Layout que vira colunas no iPad e no iPhone deitado |
| `FlowLayout` | Itens que quebram linha (chips, cápsulas) |
| `DisclosureLink`, `SurfaceContainer`, `FixedToolbarSpacer` | Navegação e barra |

## Regras

- Valores visuais novos entram primeiro como token; a feature usa o token.
- Componente usado em mais de uma feature e sem regra de negócio vai para o design system.
- Barra de ferramentas sempre com símbolos sem `.fill`.
- Guias e estados vazios mostram exemplos preenchidos da feature, sem ilustração.
