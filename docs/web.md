# Cashly Web (17/10/2026)

Uma versão web simplificada do Cashly em `cashly.byescaleira.com/app`, para ver o mês num computador. Ela lê os dados direto do iCloud da pessoa, pelo CloudKit Web Services. O Cashly continua sem servidor de dados: a VPS só passa adiante, por alguns minutos, um token cifrado que ela não consegue ler.

## Como a pessoa entra

1. No app, **Ajustes › Cashly na Web** abre um guia (`GuideSheet`): título, animação e o código de 8 caracteres em destaque (ex.: `K7QF-2M9X`), com a contagem de 5 minutos.
2. No computador, `cashly.byescaleira.com/app` pede o código. A pessoa digita e entra.
3. O site mostra o mês. Fechar a aba encerra a sessão; "Manter conectado neste navegador" guarda o token no navegador até ele expirar.

## O que acontece por baixo

1. O app gera o código (8 caracteres base32 sem letras ambíguas, cerca de 40 bits) e um sal aleatório.
2. O app pede um token web ao CloudKit com `CKFetchWebAuthTokenOperation(apiToken:)` no banco privado.
3. O app deriva uma chave do código (PBKDF2-SHA256, 300 mil iterações, com o sal) e cifra o token com AES-GCM.
4. O app envia à ponte `{id, salt, nonce, ciphertext}`, onde `id = SHA-256("cashly-web" + código)`. A ponte guarda por 5 minutos e entrega uma vez só.
5. O site recebe o código, calcula o `id`, busca o pacote, deriva a mesma chave e decifra o token no navegador (Web Crypto).
6. O site chama `https://api.apple-cloudkit.com/database/1/iCloud.cashly/production/private/...` com `ckAPIToken` e `ckWebAuthToken`. Cada resposta traz um token novo (cabeçalho `X-Apple-CloudKit-Web-Auth-Token`); o anterior deixa de valer.

## Segurança

- **A ponte nunca vê o token:** guarda só o pacote cifrado, apaga depois da primeira leitura ou de 5 minutos, limita tentativas por IP (10 por minuto) e responde igual para código errado e expirado.
- **Força bruta offline** exigiria quebrar o PBKDF2 em cerca de 2^40 tentativas dentro de 5 minutos, e só por quem já tivesse o pacote (a própria ponte).
- **Token de API do CloudKit** (`CashlyCloudKitWebAPIToken` no `Info.plist`) limitado à origem `https://cashly.byescaleira.com`. Não é segredo: ele só identifica o app.
- **No navegador:** o token fica em `sessionStorage` (ou `localStorage`, se a pessoa pedir para manter conectado), nunca em cookie e nunca enviado à ponte depois do pareamento.
- **Encerrar:** "Sair" apaga o token no navegador. O app ganha "Encerrar sessões web" quando a Apple oferecer revogação; até lá o token expira sozinho.

## Escopo da versão 1 (somente leitura)

- **Mês:** disponível, barra de ritmo com a marca do dia, planejado, gasto e restante.
- **Orçamentos:** uma linha por categoria com a barra.
- **Histórico:** as transações do mês por dia, com categoria, tags e valor.
- **Visual:** o design system do app, igual à landing (paleta retrô clara e escura, fonte arredondada, chips e barras). Só em inglês na primeira versão.
- **Fora da v1:** criar ou editar transação. Escrever registros compatíveis com o `NSPersistentCloudKitContainer` (`CD_*`, referências, `CD_entityName`) é arriscado e fica para depois de a leitura estar estável.

## Dados

Os registros são os do SwiftData no CloudKit, na zona `com.apple.coredata.cloudkit.zone`: `CD_TransactionEntity`, `CD_BudgetEntity`, `CD_CategoryEntity`, `CD_TagEntity` e `CD_UserEntity`, com os campos `CD_<propriedade>` (`CD_amountMinorUnits`, `CD_date`, `CD_currencyCode`, `CD_categoryID`, `CD_ownerID`...). A mesma regra de cálculo do app (competência, parcelas, divisão) precisa valer na web; a v1 reaproveita as regras mais simples (gasto do mês pela data e pela parte do perfil) e mostra "≈" quando divergir do app.

## Fases

- **W0, teste real:** token de API no CloudKit Console; build de Debug que gera um token web; `curl` lendo `CD_TransactionEntity` em produção; confirmar o token rotativo, a validade e o CORS a partir de `cashly.byescaleira.com`. Sem isso, nada do resto começa.
- **W1, ponte:** serviço mínimo na VPS (`bridge.byescaleira.com` ou `cashly.byescaleira.com/bridge`), em memória, com expiração, entrega única e limite por IP.
- **W2, app:** tela Ajustes › Cashly na Web (guia, código, contagem, novo código), cifra e envio; textos nos 10 idiomas; Pro ou grátis conforme a decisão abaixo.
- **W3, site:** pareamento, sessão com token rotativo, mês, orçamentos e histórico.
- **W4, verificação:** iPhone físico mais navegador, token expirado, código errado, dois navegadores ao mesmo tempo e perfil diferente.

## Decisões pendentes

1. Cashly na Web é **Pro** ou grátis? Recomendação: Pro, como as análises.
2. A versão 1 é **só leitura**? Recomendação: sim.
