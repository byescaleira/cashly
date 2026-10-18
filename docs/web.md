# Cashly Web (18/10/2026)

Uma versão web simplificada e somente leitura do Cashly em `cashly.byescaleira.com/app`, para ver o mês num computador. Recurso do **Cashly Pro**.

## Por que um snapshot e não o iCloud direto

O primeiro desenho (W0) lia o banco privado do CloudKit pelo CloudKit Web Services, com um token web gerado no app. Na prática, a conta do usuário respondeu `403 ACCESS_DENIED`, "private db access disabled for this account", mesmo com o acesso web ligado: com a **Proteção Avançada de Dados**, os dados do Cashly no iCloud são cifrados de ponta a ponta e as chaves ficam só nos aparelhos, fora do alcance de qualquer app. O público do Cashly é justamente quem liga essa proteção.

O iPhone já tem os dados legíveis. Então o app monta um **resumo do mês**, cifra para o navegador cujo **QR code** o iPhone leu e envia por uma **ponte** na VPS. A ponte guarda um pacote que não consegue abrir; só aquele navegador tem a chave para decifrar. Funciona com ou sem a Proteção Avançada e não depende do CloudKit na web.

## Como a pessoa usa (como o WhatsApp Web)

1. No computador, `cashly.byescaleira.com/app` mostra um **QR code** e "Abra a câmera do iPhone e aponte para o código" (ou "No Cashly, Ajustes › Cashly na Web › Ler QR code").
2. O iPhone lê o QR: pela **Câmera do sistema** (o QR é um link universal `https://cashly.byescaleira.com/link?s=…&k=…` que abre o Cashly) ou pelo botão **Ler QR code** dentro de Ajustes › Cashly na Web. O app pergunta "Mostrar seu mês neste computador?" (Pro; sem Pro, abre o paywall).
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

## Página (W3)

`/app` com o visual da landing e o mesmo módulo de `?locale=`: primeiro o QR grande com as instruções e "Aguardando o iPhone…"; quando o pacote chega, o mês (valor disponível, barra de ritmo com a marca do dia, planejado, gasto e restante), orçamentos com barras, próximas contas e o histórico por dia, com "Atualizado há X min" e "Sair". O QR é gerado no navegador (biblioteca pequena embutida, sem serviço externo). Recarregar a página mantém a sessão enquanto a chave estiver no IndexedDB e a ponte tiver o pacote.

## Privacidade

A política ganha um item: com o Cashly na Web ligado, um resumo do mês sai do aparelho **cifrado de ponta a ponta** para o navegador cujo QR o iPhone leu, fica até 24 horas na ponte e só abre naquele navegador; nós não conseguimos ler. O rótulo da App Store continua "Dados não coletados", porque nem o desenvolvedor nem terceiros têm acesso ao conteúdo.

## Fases

- **W1, ponte** na VPS, com testes de criar, atualizar com e sem dono, ler, expirar, apagar e limites.
- **W2, app:** leitura do QR (link universal e leitor dentro do app), ECDH + HKDF + AES-GCM (CryptoKit), montagem do resumo, envio e reenvio, lista de sessões com "Desconectar"; portão do Pro; textos nos 10 idiomas; testes do resumo e do vetor v2.
- **W3, página** `/app` decifrando o mesmo vetor de teste.
- **W4, verificação:** iPhone físico mais navegador, QR lido pela Câmera e pelo app, sessão expirada, "Desconectar", dois navegadores e troca de perfil.

## Vetor de teste compartilhado

`docs/web-test-vector-v2.json`: app e página reproduzem o mesmo segredo, a mesma chave e o mesmo pacote a partir das chaves fixas. O `docs/web-test-vector.json` (v1, código digitado) fica só como histórico do primeiro desenho.
