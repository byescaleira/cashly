# Cashly Web (18/10/2026)

Uma versão web simplificada e somente leitura do Cashly em `cashly.byescaleira.com/app`, para ver o mês num computador. Recurso do **Cashly Pro**.

## Por que um snapshot e não o iCloud direto

O primeiro desenho (W0) lia o banco privado do CloudKit pelo CloudKit Web Services, com um token web gerado no app. Na prática, a conta do usuário respondeu `403 ACCESS_DENIED`, "private db access disabled for this account", mesmo com o acesso web ligado: com a **Proteção Avançada de Dados**, os dados do Cashly no iCloud são cifrados de ponta a ponta e as chaves ficam só nos aparelhos, fora do alcance de qualquer app. O público do Cashly é justamente quem liga essa proteção.

O iPhone já tem os dados legíveis. Então o app monta um **resumo do mês**, cifra com uma chave derivada do código que a pessoa vê na tela e envia por uma **ponte** na VPS. A ponte guarda um pacote que não consegue abrir; o navegador decifra com o código que a pessoa digita. Funciona com ou sem a Proteção Avançada e não depende do CloudKit na web.

## Como a pessoa usa

1. No app, **Ajustes › Cashly na Web** abre um guia (`GuideSheet`): título, animação, o código de 8 caracteres em destaque (`K7QF-2M9X`), o endereço `cashly.byescaleira.com/app` e "Válido por 24 horas".
2. No computador, a página pede o código. A pessoa digita e vê o mês.
3. Enquanto a sessão vale, o app reenvia o resumo quando os dados mudam (com o app aberto ou em segundo plano quando o sistema permitir). A página busca a versão nova a cada minuto.
4. **Encerrar:** "Parar de compartilhar" no app apaga o pacote na ponte; o código deixa de funcionar. A sessão também acaba sozinha em 24 horas. "Sair" na página apaga o resumo do navegador.

## Criptografia (versão 1)

- **Código:** 8 caracteres do alfabeto `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (32 símbolos, 40 bits), gerados com `SecRandomCopyBytes`, mostrados como `XXXX-XXXX`. A página aceita minúsculas, espaços e hífen.
- **Identificador na ponte:** `id = hex(SHA-256(UTF-8("cashly-web:v1:" + CÓDIGO)))`, com o código normalizado (maiúsculas, sem hífen).
- **Chave:** `PBKDF2-HMAC-SHA256(senha = CÓDIGO, sal = 16 bytes aleatórios, 310.000 iterações, 32 bytes)`.
- **Cifra:** AES-256-GCM, nonce de 12 bytes aleatório a cada envio, dados adicionais (AAD) = UTF-8 do `id`. O texto cifrado inclui a tag de 16 bytes no fim (formato do Web Crypto).
- **Pacote:** `{"v":1,"salt":b64,"nonce":b64,"ciphertext":b64}` (base64 padrão). O sal é fixo durante a sessão; o nonce muda a cada envio.
- **Dono:** o app gera um `ownerToken` de 32 bytes aleatórios (base64url) por sessão. Só ele cria, atualiza e apaga o pacote; a ponte guarda apenas o SHA-256 dele.

## Ponte (W1)

Serviço mínimo em Node, num container na VPS, atrás do Caddy em `https://cashly.byescaleira.com/bridge/`. Tudo em memória: reiniciar apaga as sessões, e o app reenvia no próximo ciclo.

| Método | Caminho | Quem | Faz |
| --- | --- | --- | --- |
| `PUT` | `/bridge/v1/snapshots/{id}` | app, com `Authorization: Bearer <ownerToken>` | Cria (guarda o hash do dono, expira em 24 h) ou atualiza se o dono confere. Não estende os 24 h. Corpo até 1 MB. |
| `GET` | `/bridge/v1/snapshots/{id}` | página | Devolve o pacote com `ETag` e `updatedAt`; `304` com `If-None-Match`; `404` igual para inexistente e expirado. |
| `DELETE` | `/bridge/v1/snapshots/{id}` | app, com o dono | Apaga. |
| `GET` | `/bridge/health` | monitoração | `{"ok":true}` |

- **Limites por IP:** `GET` 60 por minuto, mas só 10 respostas `404` por minuto (contra tentativa de código); `PUT` e `DELETE` 60 por minuto. Acima disso, `429`.
- **CORS:** `GET` só para a origem `https://cashly.byescaleira.com`. O app não precisa de CORS.
- **Logs:** sem corpo e sem `id` completo (só os 8 primeiros caracteres).

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

## Página (W3)

`/app` com o visual da landing e o mesmo módulo de `?locale=` (textos, números, moeda e datas no formato do país): campo do código, depois o mês (valor disponível, barra de ritmo com a marca do dia, planejado, gasto e restante), orçamentos com barras, próximas contas e o histórico por dia. Decifra com Web Crypto (`PBKDF2` + `AES-GCM`), guarda o código só em `sessionStorage`, busca a versão nova a cada minuto e mostra "Atualizado há X min".

## Privacidade

A política ganha um item: com o Cashly na Web ligado, um resumo do mês sai do aparelho **cifrado de ponta a ponta** com o código, fica até 24 horas na ponte e só abre no navegador de quem digita o código; nós não conseguimos ler. O rótulo da App Store continua "Dados não coletados", porque nem o desenvolvedor nem terceiros têm acesso ao conteúdo.

## Fases

- **W1, ponte** na VPS, com testes de criar, atualizar com e sem dono, ler, expirar, apagar e limites.
- **W2, app:** módulo com código, criptografia (CryptoKit e CommonCrypto), montagem do resumo, envio e reenvio; tela Ajustes › Cashly na Web com guia, código, "Parar de compartilhar" e portão do Pro; textos nos 10 idiomas; testes do resumo e de um vetor de criptografia compartilhado com a web.
- **W3, página** `/app` decifrando o mesmo vetor de teste.
- **W4, verificação:** iPhone físico mais navegador, código errado, sessão expirada, "Parar de compartilhar", dois navegadores e troca de perfil.

## Vetor de teste compartilhado

App e página usam o mesmo caso fixo (código `K7QF2M9X`, sal e nonce fixos, resumo de exemplo) gravado em `docs/web-test-vector.json`, para provar que os dois lados cifram e decifram igual.
