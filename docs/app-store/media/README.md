# Mídia da App Store do Cashly 1.0

Capturas de marketing, imagens de cabeçalho e App Preview. Textos das imagens em inglês, mesma mensagem da landing page (`site/`) e de `docs/app-store/metadata.json`. Todas as telas são capturas reais do app no simulador (iOS 27), com os dados de exemplo do modo de captura; nenhuma tela foi redesenhada.

## Ordem de envio

### iPhone 6.9" (1320×2868, PNG RGB)

| Ordem | Arquivo | Título | Tela |
|---|---|---|---|
| 1 | `iphone/01-pace.png` | Know where your money goes | Goals do mês com a pace bar (79% usado no dia 17 de 31) e os orçamentos perto do limite |
| 2 | `iphone/02-record.png` | Record in 3 taps | Editor de gasto: valor, descrição com tags automáticas (Coffee, Starbucks) e categoria |
| 3 | `iphone/03-forecast.png` | See where the month lands | Home com a projeção do mês (Pro) e cartões reais de "Out of the Ordinary" e "Small Purchases" |
| 4 | `iphone/04-journey.png` | Make good habits a game | Journey: nível 16, XP, sequência de 11 dias e o cartão do desafio Spending Cap |
| 5 | `iphone/05-anywhere.png` | Record from anywhere | Ajustes › Widgets com as prévias reais dos widgets e o controle New Expense |
| 6 | `iphone/06-private.png` | No account. No bank login. | Ajustes › Dados e Backup (exportar JSON/CSV) e o cartão do modo discreto |
| 7 | `iphone/07-split.png` | Split costs fairly | Gasto dividido em partes iguais com Alice (a receber) e Bruno (pago) |
| 8 | `iphone/08-pro.png` | Go further with Cashly Pro | Paywall do Cashly Pro com a comparação Free × Pro |

### iPad 13" (2064×2752, PNG RGB)

1. `ipad/01-pace.png` — Goals em duas colunas
2. `ipad/02-forecast.png` — Home com projeção e comparação com outros meses
3. `ipad/03-history.png` — Histórico do mês em duas colunas
4. `ipad/04-journey.png` — Journey

### Mac (2880×1800, PNG RGB)

1. `mac/01-overview.png` — Home em três colunas com barra lateral
2. `mac/02-pace.png` — Goals
3. `mac/03-details.png` — Histórico com o gasto aberto no inspetor ao lado
4. `mac/04-journey.png` — Journey

### Apple Vision Pro (3840×2160, PNG RGB)

1. `vision/01-overview.png` — Home
2. `vision/02-pace.png` — Goals
3. `vision/03-journey.png` — Journey

### Cabeçalho da página do produto (campo "Header")

- `header/header-5244x2950.png`
- `header/header-3840x1646.png`

Ícone do app, título "Know where your money goes", subtítulo e o iPhone bordô sobre o MacBook, como na landing. Todo o conteúdo fica numa faixa central de cerca de 2.500×900 px em 3840×1646 (e 3.400×1.230 px em 5244×2950), com margem larga nos quatro lados para cortes diferentes.

### App Preview

| Arquivo | Formato | O que mostra |
|---|---|---|
| `preview/iphone-preview.mp4` | H.264 High, 886×1920, 30 fps constantes, AAC estéreo silencioso, 25,3 s, 19,8 MB | Home → Goals com a pace bar → novo gasto em 3 toques (valor, categoria, descrição, salvar) → Home com projeção e análises → Journey |
| `preview/poster.png` | 886×1920 | Quadro do Goals com a pace bar (4 s) |
| `preview/ipad-preview.mp4` | H.264 High, 1600×1200 (paisagem), 30 fps, AAC estéreo silencioso, 15,3 s, 9 MB | Home → Goals → Histórico com inspetor → Journey |
| `preview/ipad-poster.png` | 1600×1200 | Quadro do Goals |

Os vídeos usam só imagens gravadas do app (`simctl io recordVideo`), com cortes, aceleração leve e legendas curtas em pílulas laranja.

## Como refazer

1. Build de Debug para o simulador: `CASHLY_BUILD_ROOT=~/Library/Developer/CashlyBuild-media scripts/build.sh Debug ios`.
2. `scripts/simulator.sh acquire <udid>` e depois `docs/app-store/media/source/launch.sh <udid> fresh`. O script instala o app e abre com `-cashly.developer.showcase YES` (dados de exemplo em USD com datas relativas a hoje, dicas do TipKit ocultas), plano Pro simulado (`CASHLY_PLAN=free` para o paywall), perfil dono, status bar 9:41 e idioma inglês.
3. Navegar e capturar com `xcrun simctl io <udid> screenshot`. As capturas usadas ficam em `source/raw/iphone` e `source/raw/ipad`.
4. `python3 docs/app-store/media/source/compose.py [iphone ipad mac vision header]` gera as imagens finais com o Chrome headless (layout em `compose.py`, estilo em `style.css`, fonte SF Pro Rounded de `/Library/Fonts`).
5. `python3 docs/app-store/media/source/preview.py iphone <gravação.mp4>` (ou `ipad`) monta o App Preview com ffmpeg. Os cortes estão nas listas `segments`; mudam a cada gravação nova.

## O que não ficou perfeito

- **Mac não é captura nativa do macOS.** O app exige macOS 27 e este Mac está no 26.5, então as telas do Mac são capturas do iPad em paisagem (mesmo layout SwiftUI com barra lateral e inspetor) dentro de uma janela com barra de título desenhada em CSS, sobre o MacBook da landing. A barra de título e a barra de menus são desenho, não captura. Antes de enviar, o ideal é trocar por capturas nativas feitas num Mac com macOS 27 ou pelo Xcode Cloud; a Apple pode recusar capturas de Mac que mostram a interface do iPad.
- **visionOS não é captura do simulador.** Não há runtime de visionOS instalado. As imagens mostram a captura do iPad em paisagem dentro de uma janela de vidro sobre um ambiente neutro em degradê. No visionOS real a barra de abas vira um ornamento lateral, então convém refazer no simulador de visionOS ou no aparelho.
- **Prévias de widget, não widgets na Tela de Início.** A tela 5 usa as prévias reais de Ajustes › Widgets; não há captura da Tela de Início com widgets nem da Siri ou da captura de Apple Pay.
- **Tela 7 (dividir):** a lista rolou sob a barra de navegação, então o título "Category" aparece desfocado ao lado das 9:41. É o efeito real da borda de rolagem, mas uma recaptura com a lista parada mais abaixo fica mais limpa.
- **Data e hora reais.** As telas mostram outubro de 2026 (dia 17); o horário do editor (10:13 PM) e o "Saturday" vêm do relógio do Mac na hora da captura.
- **App Preview do iPhone:** a gravação do simulador sai em taxa variável; o script normaliza para 30 fps constantes. O trecho do teclado mostra o teclado em inglês do simulador. Não conferi o envio no App Store Connect.
- **App Preview do iPad** saiu em paisagem 1600×1200 (formato aceito para iPad 13"), não em retrato 1200×1600.
- **Ícone no cabeçalho** é uma reconstrução em CSS das camadas SVG do `CashlyIcon.icon` (sem o efeito de vidro do Icon Composer).
