# Cashly Web (18/10/2026)

Uma versão web simplificada e somente leitura do Cashly em `cashly.byescaleira.com/app`, para ver o mês num computador. Recurso do **Cashly Pro**.

## Por que um snapshot e não o iCloud direto

O primeiro desenho (W0) lia o banco privado do CloudKit pelo CloudKit Web Services, com um token web gerado no app. Na prática, a conta do usuário respondeu `403 ACCESS_DENIED`, "private db access disabled for this account", mesmo com o acesso web ligado: com a **Proteção Avançada de Dados**, os dados do Cashly no iCloud são cifrados de ponta a ponta e as chaves ficam só nos aparelhos, fora do alcance de qualquer app. O público do Cashly é justamente quem liga essa proteção.

O iPhone já tem os dados legíveis. Então o app monta um **resumo do mês**, cifra para o navegador cujo **QR code** o iPhone leu e envia por uma **ponte** na VPS. A ponte guarda um pacote que não consegue abrir; só aquele navegador tem a chave para decifrar. Funciona com ou sem a Proteção Avançada e não depende do CloudKit na web.

## Como a pessoa usa (como o WhatsApp Web)

1. No computador, `cashly.byescaleira.com/app` mostra um **QR code** e "Abra a câmera do iPhone e aponte para o código" (ou "No Cashly, Ajustes › Cashly na Web › Ler QR code").
2. O iPhone lê o QR: pela **Câmera do sistema** (o QR é um link universal `https://cashly.byescaleira.com/link?s=…&k=…` que abre o Cashly) ou pelo botão **Ler QR code** dentro de Ajustes › Cashly na Web, que abre uma folha de guia com título e texto em cima, a câmera ao vivo (só QR) no lugar da animação e "Cancelar"; um QR que não é do Cashly troca o texto pelo aviso, e sem permissão da câmera a mesma folha oferece "Abrir Ajustes". O app pergunta "Mostrar seu mês neste computador?" (Pro; sem Pro, abre o paywall).
3. Em até 2 segundos, a página troca o QR pelo mês. Nada é digitado.
4. Enquanto a sessão vale (24 horas), o app reenvia o resumo quando os dados mudam e a página busca a versão nova a cada 30 segundos.
5. **Encerrar:** em Ajustes › Cashly na Web, o app lista as sessões abertas (computador, desde quando) com "Desconectar", que apaga o pacote na ponte. Na página, "Sair" apaga a chave do navegador e volta ao QR.

## Criptografia (versão 2)

- **Na página:** um par de chaves **ECDH P-256** gerado pelo Web Crypto, com a chave privada **não exportável**, guardada só em IndexedDB daquele navegador; e um **ID de sessão** de 16 bytes aleatórios. O QR leva o link `https://cashly.byescaleira.com/link?s=<sessão em base64url>&k=<chave pública bruta, 65 bytes, em base64url>`. A chave pública não é segredo; a privada nunca sai do navegador.
- **No app:** um par ECDH P-256 efêmero por sessão (CryptoKit). Segredo compartilhado = coordenada x (32 bytes). Chave = `HKDF-SHA256(segredo, sal = bytes da sessão, info = "cashly-web:v2", 32 bytes)`.
- **Cifra:** AES-256-GCM, nonce de 12 bytes aleatório a cada envio, dados adicionais (AAD) = UTF-8 do ID da sessão em base64url, texto cifrado = ct || tag.
- **Pacote:** `{"v":2,"appKey":b64(chave pública do app, 65 bytes),"nonce":b64,"ciphertext":b64}` (base64 padrão).
- **Dono:** o app gera um `ownerToken` de 32 bytes aleatórios (base64url) por sessão. Só ele cria, atualiza e apaga o pacote; a ponte guarda apenas o SHA-256 dele.
- **Vetor de teste:** `docs/web-test-vector-v2.json` (chaves fixas da página e do app, sessão, segredo, chave derivada, pacote e resumo).
- **Por que é mais forte que o código digitado:** a chave do navegador passa pelo canal óptico do QR, e o segredo tem 128 bits de segurança em vez de 40. A ponte só vê o ID da sessão e o pacote cifrado.

## Ponte (W1)

Serviço mínimo em Node, num container na VPS, atrás do Caddy em `https://cashly.byescaleira.com/bridge/`. Tudo em memória: reiniciar apaga as sessões, e o app reenvia no próximo ciclo.

| Método | Caminho | Quem | Faz |
| --- | --- | --- | --- |
| `PUT` | `/bridge/v1/snapshots/{sessão}` | app, com `Authorization: Bearer <ownerToken>` | Cria (guarda o hash do dono, expira em 24 h) ou atualiza se o dono confere. Não estende os 24 h. Corpo até 1 MB. |
| `GET` | `/bridge/v1/snapshots/{sessão}` | página | Devolve o pacote com `ETag` e `updatedAt`; `304` com `If-None-Match`; `404` igual para inexistente e expirado. |
| `DELETE` | `/bridge/v1/snapshots/{sessão}` | app, com o dono | Apaga. |
| `GET` | `/bridge/health` | monitoração | `{"ok":true}` |

- O ID da sessão é o base64url de 16 bytes (22 caracteres).
- **Limites por IP:** `GET` 120 por minuto (a página espera o QR ser lido com uma busca a cada 2 s); `PUT` e `DELETE` 60 por minuto. Acima disso, `429`.
- **CORS:** `GET` só para a origem `https://cashly.byescaleira.com`. O app não precisa de CORS.
- **Logs:** sem corpo e só os 6 primeiros caracteres da sessão.
- **Link universal:** o site publica `/.well-known/apple-app-site-association` com `com.byescaleira.cashly` e o caminho `/link`; o app ganha `applinks:cashly.byescaleira.com`. Sem o app instalado, `/link` mostra "Abra com o Cashly" e o link da App Store.

## Resumo do mês (o que o app envia, antes de cifrar)

```json
{
  "v": 1,
  "generatedAt": "2026-10-18T09:41:00Z",
  "locale": "pt-BR",
  "currency": "BRL",
  "profile": { "name": "Rafael", "initials": "RE", "color": "orange" },
  "month": {
    "start": "2026-10-01", "end": "2026-10-31", "today": "2026-10-18",
    "planned": 3200.0, "spent": 1915.0, "income": 4200.0, "available": 1285.0,
    "usedRatio": 0.6, "elapsedRatio": 0.55, "pace": "onTrack", "perDay": 91.0
  },
  "budgets": [
    { "name": "Mercado", "symbol": "cart", "color": "olive", "planned": 600.0, "spent": 412.0 }
  ],
  "transactions": [
    { "date": "2026-10-17", "description": "Feira", "kind": "expense", "status": "paid",
      "amount": 48.2, "category": { "name": "Mercado", "symbol": "cart", "color": "olive" },
      "tags": ["Casa"] }
  ],
  "upcoming": [ { "description": "Internet", "dueDate": "2026-10-20", "amount": 59.0 } ]
}
```

- Valores em unidades da moeda do perfil (já convertidos como o app mostra), com os números calculados pelo próprio app (os mesmos do Início e de Metas). A web não recalcula nada.
- `pace` é `onTrack`, `ahead` (gastando mais rápido que o mês) ou `over` (passou do planejado). `color` usa os nomes da paleta (`olive`, `rust`, `mustard`, `teal`, `denim`, `plum`, `brown`, `orange`). `symbol` é o nome do SF Symbol; a web desenha um ícone próprio quando conhece o nome e a inicial da categoria quando não conhece.
- Somente o perfil atual e o mês atual; até 300 transações (as mais recentes).
- `kind` é `expense` ou `income`; `status` é `paid`, `toPay`, `toReceive` ou `canceled`. `upcoming` são as despesas a pagar do mês, em ordem de vencimento. As chaves do JSON saem em ordem alfabética (o conteúdo é o mesmo).

## Seções extras do resumo (W5, 18/10/2026)

Depois do primeiro teste real, o resumo ganhou as seções do Início, de Insights e da Jornada. Todas são **opcionais**: o app manda o que tiver e a página esconde o que faltar. O `v` de dentro do resumo continua `1` (só campos novos).

```json
{
  "daily": [ { "date": "2026-10-01", "spent": 120.5 } ],
  "forecast": { "spent": 3550.0, "available": -350.0, "outcome": "over", "planned": 3200.0 },
  "categories": [ { "name": "Mercado", "symbol": "cart", "color": "olive", "spent": 412.0, "share": 0.21 } ],
  "tags": [ { "name": "Casa", "spent": 230.0, "count": 6 } ],
  "history": [ { "month": "2026-05", "planned": 3200.0, "spent": 2980.0, "income": 4200.0 } ],
  "savings": { "saved": 1285.0, "rate": 0.31, "averageRate": 0.24 },
  "score": { "value": 812, "max": 1000, "label": "Over budget", "detail": "You went over the planned budget…" },
  "journey": {
    "level": 4, "levelTitle": "Saver", "progress": 0.4, "streak": 12,
    "challenge": { "title": "No delivery this week", "progress": 0.5, "endsOn": "2026-10-25" }
  }
}
```

- `daily`: gasto de cada dia do mês, do dia 1 até hoje (despesas pagas e a pagar, sem as canceladas), pelo mesmo razão do motor de análise (`LedgerSnapshot.spent(in:throughDay:)`). A soma dá o "já gasto" da previsão; pode ser menor que `month.spent`, que inclui despesas com data depois de hoje. A página desenha barras por dia e a linha do ritmo planejado (`month.planned / dias do mês`, acumulado).
- `forecast`: a mesma previsão do Início/Insights (`MonthPace`, onde o mês fecha). `spent` é o valor previsto para o fim do mês, `planned` é o planejado que a previsão usa (todos os orçamentos do mês) e `available = planned - spent`. `outcome` é `over` quando a previsão passa do planejado, `under` quando fica abaixo e `onPlan` quando fecha exatamente nele (em centavos), como o chip "acima/abaixo do plano" do app. **Só vem quando o mês tem planejamento** (sem plano, o app não tem com o que comparar).
- `categories`: até 8 categorias por gasto do mês (os mesmos `categoryExpenses` do Início), em ordem decrescente; o que sobra, inclusive categorias que não existem mais, vira um 9º item `Other` (nome já traduzido pelo app, `symbol` `ellipsis`, `color` `brown`). `share` é a fração do gasto total do mês. Fica de fora sem gasto.
- `tags`: até 8 tags por gasto do mês (`tagExpenses` do Início); `count` é quantas despesas do mês têm a tag. Fica de fora sem tag com gasto.
- `history`: até 6 meses, do mais antigo ao atual, cada um com o planejado, o gasto e o recebido do mesmo resumo que o Início mostra para aquele mês. Começa no primeiro mês com algum dado (o atual sempre vem), para quem começou há pouco não ver colunas vazias.
- `savings`: o que sobrou no mês (`income - spent`, o `netTotal` do Início, podendo ser negativo), a taxa sobre a receita e a média das taxas dos meses de `history` que tiveram receita. **Só vem quando o mês atual tem receita** (sem receita não há taxa).
- `score`: a pontuação do mês do Início, **na mesma escala do app: de 200 a 1000 (`max` = 1000)**, não 0–100, com `label` (o nível: Healthy, Over budget, At risk, Critical) e `detail` (a frase do nível) já traduzidos no idioma do app.
- `journey`: nível, título do nível (traduzido), progresso até o próximo nível (0–1), sequência atual em dias e o desafio ativo, se houver: `title` é o nome do desafio, `progress` é a barra do app (0–1; nos desafios de limite, a fração do limite já usada) e `endsOn` é o último dia do desafio. Fica de fora se a Jornada estiver desligada (flag remota `journey` ou o ajuste "Mostrar Jornada").
- Proporções (`share`, `rate`, `averageRate`, `progress`) arredondadas em 2 casas, como as do mês. As seções que dependem do histórico inteiro (`daily`, `forecast`, `journey`) ficam de fora enquanto o iCloud ainda está trazendo dados.
- Textos que vêm prontos do app (`label`, `detail`, `levelTitle`, `challenge.title`, `Other`) seguem o `locale` do resumo; o resto da página segue o `?locale=`.

## Jornada na página e campos opcionais (19/10/2026)

Com o resumo de hoje, a aba Jornada da web mostra: o nível com a barra até o próximo e a porcentagem, a barra de 5 segmentos do título atual e o nível do próximo título (títulos a cada 5 níveis, então dá para calcular), a sequência com a próxima marca (7, 30, 100 ou 365 dias) e os dias que faltam, o desafio ativo com a barra, o fim e os dias que faltam (contados de `month.today`), o "Mês no azul" (pontuação do `score` contra 895, com os 200 XP do fechamento) e a tabela "Como ganhar XP" (valores da seção XP e níveis de `docs/gamification.md`).

A página lê os campos abaixo, todos opcionais, e esconde o que não vier (um app mais antigo manda só `level`, `levelTitle`, `progress`, `streak` e `challenge` com `title`, `progress` e `endsOn`). Desde 19/10/2026 o app (`CashlyWeb`, `WebSnapshot+Journey.swift`) manda todos, tirados do mesmo `GameProgress` da aba Jornada e com os textos no idioma do app:

```json
"journey": {
  "xp": 2534, "nextTitle": "Planner",
  "best": 41, "freezes": 2, "trackedToday": false,
  "days": [ { "date": "2026-10-13", "state": "tracked" } ],
  "challenge": { "title": "…", "progress": 0.57, "endsOn": "2026-10-22", "xp": 100, "detail": "4 of 7 days without spending" },
  "missions": { "renewsOn": "2026-10-20", "items": [ { "title": "Record 5 transactions", "done": 5, "target": 5, "xp": 25 } ] },
  "achievements": {
    "unlocked": 17, "total": 41,
    "next": [ { "title": "30-day streak", "detail": "…", "progress": 0.77, "done": 23, "target": 30, "xp": 150 } ],
    "recent": [ { "title": "7-day streak", "tier": "bronze", "unlockedOn": "2026-10-03", "xp": 50 } ]
  }
}
```

- `xp`: XP total do perfil. A página calcula o começo e o fim do nível por `50 × n × (n + 1)` e mostra "x de y XP" e "faltam z XP".
- `nextTitle`: título do próximo bloco de 5 níveis, já traduzido.
- `best`, `freezes`, `trackedToday`: recorde, congelamentos disponíveis e se o dia de hoje já está feito.
- `days`: os últimos 7 dias, do mais antigo a hoje, com `state` `tracked`, `frozen`, `missed` ou `pending` (a mesma faixa da aba Jornada).
- `challenge.xp` e `challenge.detail`: XP do desafio e a legenda da medida (`ChallengeMeasure`), já traduzida.
- `missions`: as três missões da semana (`title` traduzido, `done`/`target`, `xp`) e o dia em que renovam.
- `achievements`: desbloqueadas e total, as três mais próximas (as mesmas da aba Jornada, sem as secretas nem as do Pro) e as três últimas desbloqueadas, com `tier` `bronze`, `silver` ou `gold`.

Como o app monta: `nextTitle` falta só no último bloco de títulos; em `days`, hoje sem registro é `pending` e um dia coberto por congelamento é `frozen`; `challenge.detail` é a mesma legenda de `ChallengeState.caption`; `renewsOn` é a segunda-feira seguinte; em `next`, `done` e `target` só vêm quando a meta passa de 1 e `xp` falta nas conquistas do Pro (valem 0 XP). As datas de desbloqueio são as que a aba Jornada grava no aparelho (`AchievementUnlocks`); conquistas desbloqueadas antes de existir a gravação entram depois das datadas, sem `unlockedOn`. Os textos de missões, conquistas e da legenda do desafio passaram do `FeatureJourney` para o `CashlyGame`, para app e web usarem a mesma fonte.

## Ponte pausada

Quando o admin pausa a ponte, `PUT`, `GET` e `DELETE` respondem `503 {"error":"paused"}`. A página mostra "O Cashly na Web está em pausa por alguns minutos" e tenta de novo a cada minuto; o app mostra o chip "Pausado" e reenvia quando voltar. A flag remota `web` desligada esconde a função no app sem tocar na VPS (o app lê as flags do CloudKit público).

No app, `503` com `{"error":"paused"}` em `PUT` ou `DELETE` vira `WebBridgeError.paused`, um estado próprio, separado de falha: a sessão fica guardada com o chip "Pausado" (mostarda, o mesmo termo e a mesma cor da sessão sem Pro) e o rodapé "O Cashly na Web está em pausa por alguns minutos. Seu mês é enviado de novo quando você abrir o Cashly ou mudar seus dados.". O reenvio acontece pelos gatilhos de sempre (voltar ao primeiro plano, mudança nos dados, perfil, moeda ou idioma), sem timer. Ao conectar ou desconectar com a ponte pausada, o alerta diz "O Cashly na Web está em pausa por alguns minutos. Tente de novo mais tarde.". Outro `503` continua sendo indisponibilidade comum.

## Página (W3)

`/app` com o mesmo módulo de `?locale=` da landing. Antes do pareamento: o QR grande com os passos e "Aguardando o iPhone…". Depois: um **painel web** (não uma coluna de iPad), com o design system do app:

- **Barra lateral** com o perfil (iniciais na cor do perfil e o mês), navegação (Visão geral, Transações, Orçamentos e Jornada, esta só quando o resumo traz `journey`), "Atualizado há X min" e "Sair". Abaixo de 860 px vira uma barra superior com abas roláveis.
- **Visão geral:** linha de indicadores (disponível, gasto com a barra de ritmo e a marca do dia, receitas, planejado), gastos por dia, resumo rápido (previsão, economia, pontuação), últimos meses, próximas contas, transações recentes e maiores categorias.
- **Transações:** tabela com busca (descrição, categoria e tag), filtro Todas/Despesas/Receitas e por categoria, ordenação por data ou valor, situação em chip e total do filtro; no celular cada linha vira um cartão.
- **Orçamentos:** orçamentos com barra, valor e porcentagem; categorias com a barra de participação empilhada; tags.

O QR é gerado no navegador (`qrcode-generator` em `site/vendor`). Recarregar mantém a sessão enquanto a chave estiver no IndexedDB e a ponte tiver o pacote.

## Privacidade

A política ganha um item: com o Cashly na Web ligado, um resumo do mês sai do aparelho **cifrado de ponta a ponta** para o navegador cujo QR o iPhone leu, fica até 24 horas na ponte e só abre naquele navegador; nós não conseguimos ler. O rótulo da App Store continua "Dados não coletados", porque nem o desenvolvedor nem terceiros têm acesso ao conteúdo.

## Fases

- **W1, ponte** na VPS, com testes de criar, atualizar com e sem dono, ler, expirar, apagar e limites.
- **W2, app:** leitura do QR (link universal e leitor dentro do app), ECDH + HKDF + AES-GCM (CryptoKit), montagem do resumo, envio e reenvio, lista de sessões com "Desconectar"; portão do Pro; textos nos 10 idiomas; testes do resumo e do vetor v2.
- **W3, página** `/app` decifrando o mesmo vetor de teste.
- **W4, verificação:** iPhone físico mais navegador, QR lido pela Câmera e pelo app, sessão expirada, "Desconectar", dois navegadores e troca de perfil.

## Vetor de teste compartilhado

`docs/web-test-vector-v2.json`: app e página reproduzem o mesmo segredo, a mesma chave e o mesmo pacote a partir das chaves fixas. O `docs/web-test-vector.json` (v1, código digitado) fica só como histórico do primeiro desenho.
