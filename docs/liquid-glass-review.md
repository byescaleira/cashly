# Revisão do Liquid Glass — 05/10/2026

Branch: `refactor/swiftui-ui-patterns`. As alterações de domínio, MVVM e padrões SwiftUI que já estavam no workspace foram preservadas. Esta rodada trata apenas de materiais e suas abstrações, sem adicionar telas ou controles financeiros.

## Resultado da revisão

O projeto tinha 16 pontos de aplicação manual de vidro na UI. Após a revisão, 14 indicadores usam preenchimento simples e dois menus do editor de transação continuam com vidro. Botões de ação, barras, tabs e apresentações mantêm os estilos nativos do SwiftUI.

| Achado | Correção |
| --- | --- |
| Glass.clear era o padrão do helper, inclusive em formulários e listas. | cashlySurface utiliza Glass.regular em iOS/macOS. |
| Score, período, variação e ícones informativos tinham vidro interativo sem ação. | Foram convertidos em cashlyContentSurface, preservando tint, formas e medidas. |
| O seletor de modo de divisão tinha vidro sem interatividade explícita. | O menu recebe interactive: true, assim como o menu de status. |
| O helper não considerava se o controle estava habilitado. | O modifier consulta isEnabled e aplica interatividade somente quando solicitada e habilitada. |
| Grupos de ícones informativos mantinham três containers de vidro. | Os containers foram removidos desses grupos. HStacks, espaçamentos e animações foram preservados. |
| A distância de composição de vidro não era configurável. | CashlySurfaceContainer aceita spacing; o valor representa a distância óptica de fusão, separada do espaçamento do layout. O padrão zero evita aproximação automática de formas separadas. |

Essas escolhas seguem a distinção de conteúdo e controles nas [Human Interface Guidelines de materiais](https://developer.apple.com/design/human-interface-guidelines/materials). O uso de containers para grupos de vidro e a ordem dos modifiers seguem [Applying Liquid Glass to custom views](https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views).

## Abstrações e plataformas

`cashlyContentSurface(tint:in:)` aplica um background colorido sem blur, refração ou comportamento de controle. Representa informação dentro do conteúdo. `cashlySurface(tint:in:interactive:)` aplica material nativo a um controle personalizado; fica depois de fontes, cor, frame e padding nos dois menus atuais.

O helper mantém uma implementação privada por ViewModifier, que consegue consultar o ambiente de habilitação no local da aplicação. As telas não decidem a API de cada plataforma. visionOS continua com glassBackgroundEffect nas formas suportadas e borderedProminent nos botões; iOS/macOS utilizam glassEffect e glassProminent. A resposta de controles a toque, ponteiro ou olhar continua sob os componentes nativos.

Os mínimos de app e pacote são iOS, macOS e visionOS 27. A disponibilidade das APIs é garantida pelos targets. Não foram adicionados checks para iOS 26 nem branches de fallback para versões que o projeto não suporta. A condição de compilação de visionOS permanece necessária, porque usa APIs diferentes.

Não foram acrescentadas animações de morphing ou glassEffectID: a revisão não introduziu uma troca animada de hierarquia que precise desse efeito. O container continua disponível para grupos de controles personalizados; os previews demonstram seu uso. Barras e toolbars do sistema não recebem uma segunda camada de vidro.

## Verificação e limites

- Debug do app aprovado em iOS Simulator, macOS e visionOS Simulator, com Xcode 27 beta 6.
- CashlyPreview aprovado separadamente. Foram criadas variantes claro, escuro e controles desativados, sem dados financeiros nem persistência.
- swift-format e SwiftLint estrito: 129 arquivos, zero violações.
- Preview host independente renderizado no iPhone 17 Pro com iOS 27. As variantes claro, escuro e controles desativados foram percorridas e inspecionadas por screenshots e snapshots sem acessar o armazenamento do Cashly. Na terceira variante, os controles locais não aparecem como alvos de toque.
- git diff --check aprovado.
- Nenhuma suíte ou fonte de testes foi executada ou alterada.

O projeto não força configurações de acessibilidade. A verificação de redução de transparência e aumento de contraste deve usar as preferências reais do sistema; accessibilityReduceTransparency é um valor de ambiente somente de leitura neste SDK. Os materiais nativos permanecem responsáveis por suas adaptações. Isso não substitui uma inspeção visual nos aparelhos nem uma medição de contraste.

Logs: `/tmp/cashly-liquid-glass-debug.log`, `/tmp/cashly-liquid-glass-previews.log`, `/tmp/cashly-liquid-glass-lint.log`.

Evidência visual: `/tmp/cashly-liquid-glass-visual/light.jpg`, `/tmp/cashly-liquid-glass-visual/dark.jpg` e `/tmp/cashly-liquid-glass-visual/disabled.jpg`. O launcher notificou timeout antes de o host publicar o estado running; a renderização foi confirmada depois pelo simulador. O browser não conectou ao espelhamento, portanto a validação foi direta no simulador e não comprova o funcionamento do stream no navegador. O host e o helper de espelhamento foram encerrados após a inspeção.

A inspeção visual não incluiu as preferências reais de acessibilidade do sistema, aparelhos físicos, macOS ou visionOS. A remoção de efeitos redundantes é verificável no código; o impacto em tempo de renderização ou uso de GPU não foi medido.
