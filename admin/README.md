# Cashly Admin

Painel em `https://cashly.byescaleira.com/admin` para flags remotas (CloudKit público) e para a ponte do Cashly na Web. Spec: `docs/admin.md`.

- Código: `src/` (Node 22, só `@simplewebauthn/server` como dependência, versão fixa com `package-lock.json`). Testes: `npm test` (precisa do `../bridge/server.mjs` ao lado, usado como ponte real nos testes).
- Telas: Visão geral (estado da ponte e gráfico da última hora), Flags (Desenvolvimento e Produção), Ponte (pausa e limites), Registro.
- Visual: usa o `/style.css` do site e só acrescenta `public/admin.css`.

## Como roda na VPS

- Pasta `/opt/cashly-admin` com `Dockerfile`, `compose.yaml`, `package.json`, `package-lock.json`, `src/`, `public/`.
- Container `cashly-admin` em `127.0.0.1:3120`, `read_only`, usuário `node` (uid 1000), sem capabilities. Só `secrets/` e `data/` são graváveis (pastas do host, dono 1000, `chmod 700`).
- `.env` (chmod 600): `BRIDGE_ADMIN_TOKEN` (o mesmo de `/opt/cashly-bridge/.env`) e `CLOUDKIT_KEY_ID`.
- `secrets/cloudkit.pem`: chave privada P-256 do CloudKit (chmod 600, nunca sai da VPS). `secrets/auth.json`: hash scrypt da senha e a passkey.
- `data/audit.log`: registro das ações do admin, uma linha JSON por ação.
- Conversa com a ponte pela rede Docker `cashly-control` em `http://cashly-bridge:3111` (porta interna da ponte, nunca publicada no host nem no Caddy). A ponte precisa subir antes, porque é ela que cria a rede.
- Caddy, no bloco `cashly.byescaleira.com`, antes do `file_server`:

```
handle /admin* {
	reverse_proxy 127.0.0.1:3120
}
```

## Runbook

Atualizar (depois de copiar os arquivos):

```bash
cd /opt/cashly-admin && docker compose up -d --build
docker compose logs --tail=50 cashly-admin
```

Primeiro acesso:

1. `cd /opt/cashly-admin && docker compose logs cashly-admin | grep "setup code"` mostra o código de uso único (vale 30 minutos e só aparece uma vez por início do serviço). Se expirar: `docker compose restart cashly-admin` e ler de novo.
2. Abrir `https://cashly.byescaleira.com/admin/setup`, digitar o código, criar a senha (mínimo 14 caracteres) e registrar a passkey.
3. Depois disso `/admin/setup` responde 404 e o login pede senha **e** passkey.

Trocar a senha ou perder a passkey: `rm /opt/cashly-admin/secrets/auth.json && docker compose restart cashly-admin` e repetir o primeiro acesso.

Chave do CloudKit:

1. Gerada na VPS: `openssl ecparam -name prime256v1 -genkey -noout -out secrets/cloudkit.pem`, `chmod 600`, dono 1000.
2. Chave pública para o CloudKit Console: `openssl ec -in secrets/cloudkit.pem -pubout`.
3. No CloudKit Console, container `iCloud.cashly` › API Access › Server-to-Server Keys › nova chave com essa pública. Copiar o Key ID para `CLOUDKIT_KEY_ID` no `.env` e rodar `docker compose up -d`.
4. O tipo `FeatureFlag` nasce em Desenvolvimento na primeira gravação. No Console, marcar `name` e `recordName` como consultáveis. Produção só depois do **Deploy Schema Changes** (irreversível).

Segurança:

- Cinco erros por IP em 15 minutos bloqueiam o IP por 15 minutos (código de configuração, senha ou passkey).
- Sessão em memória: cookie `cashly_admin` `HttpOnly; Secure; SameSite=Strict; Path=/admin`, 12 horas, renovada a cada uso. Reiniciar o serviço encerra as sessões.
- Toda requisição que escreve precisa de `Origin: https://cashly.byescaleira.com`. CSP sem script inline.

Em caso de carga: baixar o rollout da flag `web` em Produção; se não bastar, pausar a ponte na tela Ponte.
