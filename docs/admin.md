# Admin do Cashly (18/10/2026)

Painel web em `https://cashly.byescaleira.com/admin` para controlar o app sem publicar versão: flags remotas e a ponte do Cashly na Web. Pedido do Rafael por medo de milhões de usuários baterem na VPS.

## Por que assim

- **Flags ficam no CloudKit público,** não na VPS. O app já lê o tipo `FeatureFlag` (`name` String consultável, `isOn` Int64 0/1, `rollout` Int64 0–100) pelo `CloudKitFlagSource`; a carga dessas leituras é da Apple. O admin só **escreve** nesses registros.
- **A VPS só atende o Cashly na Web.** A ponte ganha pausa geral e limites ajustáveis sem reiniciar, mais estatísticas para ver a carga.

## Serviço

- Container `cashly-admin` (Node 22, sem framework pesado), em `127.0.0.1:3120`, atrás do Caddy em `handle /admin*`.
- Pasta `/opt/cashly-admin`, segredos em `/opt/cashly-admin/secrets` (chmod 600): chave server-to-server do CloudKit (PEM P-256; o key ID fica no `.env`), hash da senha e credenciais de passkey. As sessões ficam em memória (reiniciar encerra).
- Conversa com a ponte pela porta interna `3111`, aberta só na rede Docker `cashly-control` (alias `cashly-bridge`), nunca publicada no host nem no Caddy, protegida por um token compartilhado (`BRIDGE_ADMIN_TOKEN`). Runbook em `admin/README.md` e `bridge/README.md`.

## Acesso (senha + passkey)

- **Primeiro acesso:** o serviço sobe sem senha e imprime no log (`docker compose logs cashly-admin`) um **código de configuração** de uso único, válido por 30 minutos. Na página `/admin/setup`, o Rafael digita o código, cria a senha (mínimo 14 caracteres, guardada com scrypt) e registra uma passkey (WebAuthn, RP ID `cashly.byescaleira.com`). Depois disso a página de configuração deixa de existir.
- **Entrar:** senha **e** passkey, sempre. Cinco erros por IP em 15 minutos bloqueiam por 15 minutos.
- **Sessão:** cookie `HttpOnly; Secure; SameSite=Strict; Path=/admin`, 12 horas, renovada ao usar. Toda escrita confere `Origin`.
- Sem cadastro aberto; uma conta só. Para trocar a senha ou perder a passkey: apagar `secrets/auth.json` na VPS e repetir o primeiro acesso.

## Telas

1. **Visão geral:** estado da ponte (ativa/pausada), sessões guardadas agora, leituras e escritas por minuto, `429` e `503` por minuto, memória, tempo no ar; gráfico da última hora.
2. **Flags:** a lista do `FeatureFlag` do app (`mcpServer`, `mcpLocalNetwork`, `spreadsheetImport`, `guides`, `analytics`, `journey`, `pro`, `intelligence`, `summary`, `web`, `social`) com o padrão do app, o valor remoto em **Desenvolvimento** e em **Produção** (abas), interruptor e rollout de 0 a 100 %. Salvar grava no CloudKit público do ambiente escolhido. Mostra quando foi a última leitura e avisa que o app só pega o novo valor na próxima abertura.
3. **Versões:** a política de atualização do tipo `AppRelease` (`docs/force-update.md`), um bloco por plataforma (iPhone e iPad `ios`, Mac `macos`, Apple Vision Pro `visionos`) em **Desenvolvimento** e em **Produção** (abas): versão mínima, build mínima, versão recomendada e build recomendada. Valida versão no formato `x.y.z`, build inteira ≥ 0 e recomendada ≥ mínima (versão e build). **Remover política** apaga o registro e o app deixa de pedir atualização nessa plataforma. Produção pede confirmação.
4. **Ponte:** pausar/retomar, limite de sessões guardadas, leituras e escritas por minuto por IP, tamanho máximo do pacote e validade (até 24 h). Mudanças valem na hora, sem reiniciar.
5. **Registro:** quem mudou o quê e quando (só ações do admin, sem dados de usuários), inclusive versões gravadas e removidas com o valor anterior.

## CloudKit

- Requisições assinadas com a chave server-to-server (ECDSA P-256 sobre data, hash SHA-256 do corpo e caminho), nos endpoints `records/query` e `records/modify` do banco `public` do container `iCloud.cashly`.
- A chave server-to-server **não cria schema** (gravar num tipo inexistente dá `NOT_FOUND`). O tipo `FeatureFlag` (`name` String, `isOn` e `rollout` Int64), o índice consultável de `name` e o `recordName` consultável (a consulta do app usa `TRUEPREDICATE`) são criados no CloudKit Console em Development. A ida para Produção é o **Deploy Schema Changes**, que é irreversível e fica com o Rafael.
- A chave server-to-server é criada no CloudKit Console (API Access › Server-to-Server Keys) a partir da chave pública gerada na VPS; a privada nunca sai da VPS.

## Esquema `AppRelease` (criar à mão no CloudKit Console)

Container `iCloud.cashly`, banco **Public**. Criar primeiro em **Development** (Schema › Record Types › novo tipo `AppRelease`), conferir com uma gravação pelo admin e só então publicar em **Production** com **Deploy Schema Changes** (irreversível, fica com o Rafael). Enquanto não houver registro no ambiente (ou o tipo ainda não existir lá), a busca pelo ID volta "não encontrado" e o app trata como sem política: nunca bloqueia.

| Campo | Tipo | Índices | Conteúdo |
| --- | --- | --- | --- |
| `recordName` (do sistema) | — | **Queryable** | igual à plataforma: `ios`, `macos` ou `visionos` |
| `platform` | String | **Queryable** | igual ao `recordName` |
| `minimumVersion` | String | nenhum | `x.y.z`, por exemplo `1.0.0` |
| `minimumBuild` | Int(64) | nenhum | build inteira, por exemplo `66` |
| `recommendedVersion` | String | nenhum | `x.y.z`, ≥ `minimumVersion` |
| `recommendedBuild` | Int(64) | nenhum | build inteira, ≥ `minimumBuild` |

- Nenhum campo precisa ser **Sortable** nem **Searchable**. O app lê pelo ID do registro e o admin usa `records/lookup` pelos três nomes, então nenhuma das leituras depende de índice; os dois **Queryable** servem para listar e filtrar os registros no próprio Console (e `recordName` já está marcado por causa do `FeatureFlag`).
- **Permissões (Security Roles do tipo `AppRelease`):** `World` só **Read**; `Authenticated` só **Read** (tirar o Create que o Console marca por padrão); `Creator` sem nada além do padrão. Quem grava é só a chave server-to-server do admin (a mesma do `FeatureFlag`, um key ID por ambiente), que age como administrador do container e ignora esses papéis.
- Fazer o mesmo nos dois ambientes: em Development criando o tipo e as permissões; em Production pelo Deploy Schema Changes, conferindo depois que as permissões vieram iguais.
- Registros ficam com `recordName` = plataforma; o admin grava com `forceReplace` e remove com `forceDelete`.

## Capacidade

- Pacote médio do resumo: 20–80 KB. Com o limite padrão de 5.000 sessões, a memória da ponte fica abaixo de ~400 MB no pior caso realista; o admin mostra a ocupação e permite baixar o limite.
- A página espera o QR com uma busca a cada 2 s (até 10 min) e depois a cada 30 s; o app só envia quando os dados mudam. Se a carga apertar, a ordem é: baixar o rollout da flag `web` no CloudKit, depois pausar a ponte.

## Estado em 18/10/2026

- Chaves server-to-server cadastradas em Development e Produção (mesma pública, nome "Cashly admin (VPS)").
- `FeatureFlag` criado em Development (campos `name`, `isOn`, `rollout`; `recordName` e `name` consultáveis) e publicado em Produção pelo Rafael (Deploy Schema Changes).
- Flag `web` gravada em Development (ligada, 100 %); Produção ainda sem registros, então o app usa os padrões.
