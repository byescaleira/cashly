# Cashly Web bridge

Serviço mínimo que guarda, por até 24 horas, o resumo do mês **cifrado** que o app envia para o Cashly na Web (`docs/web.md`). Ele não consegue ler o conteúdo: só guarda o pacote, confere o dono (hash do `ownerToken`) e entrega ao navegador.

- Código: `server.mjs` (Node 22, sem dependências). Testes: `node --test server.test.mjs`.
- Produção: VPS em `/opt/cashly-bridge`, `docker compose up -d --build`, ouvindo só em `127.0.0.1:3110`, publicado pelo Caddy em `https://cashly.byescaleira.com/bridge/` (bloco do site, `handle /bridge/*`). O `Cache-Control` do site é condicional (`?Cache-Control`) para não sobrescrever o `no-store` da ponte.
- Atualizar: copiar `server.mjs`, `Dockerfile` e `compose.yaml` para `/opt/cashly-bridge` e rodar `docker compose up -d --build`. Tudo fica em memória: reiniciar apaga as sessões, e o app reenvia no próximo ciclo.
