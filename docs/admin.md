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
3. **Ponte:** pausar/retomar, limite de sessões guardadas, leituras e escritas por minuto por IP, tamanho máximo do pacote e validade (até 24 h). Mudanças valem na hora, sem reiniciar.
4. **Registro:** quem mudou o quê e quando (só ações do admin, sem dados de usuários).

## CloudKit

- Requisições assinadas com a chave server-to-server (ECDSA P-256 sobre data, hash SHA-256 do corpo e caminho), nos endpoints `records/query` e `records/modify` do banco `public` do container `iCloud.cashly`.
- O tipo `FeatureFlag` nasce em Desenvolvimento quando o admin grava o primeiro registro; o índice consultável de `name` e o `recordName` consultável (a consulta do app usa `TRUEPREDICATE`) são criados no CloudKit Console. A ida para Produção é o **Deploy Schema Changes**, que é irreversível e fica com o Rafael.
- A chave server-to-server é criada no CloudKit Console (API Access › Server-to-Server Keys) a partir da chave pública gerada na VPS; a privada nunca sai da VPS.

## Capacidade

- Pacote médio do resumo: 20–80 KB. Com o limite padrão de 5.000 sessões, a memória da ponte fica abaixo de ~400 MB no pior caso realista; o admin mostra a ocupação e permite baixar o limite.
- A página espera o QR com uma busca a cada 2 s (até 10 min) e depois a cada 30 s; o app só envia quando os dados mudam. Se a carga apertar, a ordem é: baixar o rollout da flag `web` no CloudKit, depois pausar a ponte.

## Estado em 18/10/2026

- Chaves server-to-server cadastradas em Development e Produção (mesma pública, nome "Cashly admin (VPS)").
- `FeatureFlag` criado em Development (campos `name`, `isOn`, `rollout`; `recordName` e `name` consultáveis) e publicado em Produção pelo Rafael (Deploy Schema Changes).
- Flag `web` gravada em Development (ligada, 100 %); Produção ainda sem registros, então o app usa os padrões.
