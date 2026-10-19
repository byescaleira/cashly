# Compras no sandbox (iPhone com TestFlight)

Segunda camada de validação das compras: o que os testes do StoreKit no Xcode Cloud (ver [validation.md](validation.md#compras-storekit)) não alcançam, porque depende do servidor de sandbox da Apple, da conta e do aparelho. Passe o roteiro a cada build candidata que mexa em `FeatureStore`, no catálogo ou nos produtos do App Store Connect.

## Antes de começar

1. Build do TestFlight instalada no iPhone. Builds do TestFlight sempre usam o ambiente de sandbox.
2. Conta de sandbox criada em App Store Connect › Usuários e Acesso › Sandbox, território Brasil.
3. No iPhone: Ajustes › [nome] › Mídia e Compras › Sair (sai só da conta de compras de produção). Depois Ajustes › Desenvolvedor › Conta Apple de Sandbox › entrar com a conta de sandbox. Sem a conta de sandbox o TestFlight renova uma vez por dia, até 6 vezes, e não dá para simular falha de cobrança.
4. Em Ajustes › Desenvolvedor › Conta Apple de Sandbox › Gerenciar ficam a taxa de renovação, as compras interrompidas e a limpeza do histórico. O mesmo pode ser feito pela API com `scripts/sandbox-tester.py` (abaixo).
5. Para começar do zero: `scripts/sandbox-tester.py clear <email>`, apagar o app, reinstalar pelo TestFlight.

Taxas de renovação disponíveis (o mês dura o tempo escolhido; o ano dura proporcionalmente mais): 1 hora, 30, 15, 5 e 3 minutos. Para o roteiro, use 5 minutos (`renewal <email> 5m`). No sandbox uma assinatura renova no máximo 12 vezes e depois para sozinha.

## Roteiro

Anote em cada cenário o estado no paywall, no card do Cashly Pro em Ajustes e na Jornada.

| # | Cenário | Como | Esperado |
| --- | --- | --- | --- |
| 1 | Assinar com teste grátis | Paywall › Anual › Assinar | Folha da Apple mostra 1 semana grátis; depois Ajustes mostra "Free Trial" com a data de término e o lembrete de 2 dias antes é agendado |
| 2 | Teste grátis só uma vez | Com o histórico do cenário 1, abrir o paywall | Os dois planos sem o selo de teste grátis (mesmo grupo) |
| 3 | Renovar acelerado | Taxa 5 min; esperar o fim do teste e duas renovações | "Active" com a nova data a cada renovação, sem ação do usuário; tempo de Pro conta meses na Jornada |
| 4 | Desligar a renovação | Ajustes › Cashly Pro › Gerenciar › Cancelar | Pro continua até a data; depois "Expired" e o paywall volta |
| 5 | Upgrade Mensal → Anual | Assinar o Mensal, esperar virar pago, assinar o Anual pelo paywall | Troca imediata para o Anual com crédito proporcional; entitlement continua ativo, sem cobrança dupla |
| 6 | Downgrade Anual → Mensal | Assinar o Anual, depois o Mensal (pelo paywall ou Gerenciar) | Anual segue até o fim do período; o Mensal começa só na renovação; Gerenciar mostra a troca agendada |
| 7 | Falha de cobrança e nova tentativa | Com a assinatura paga, Ajustes › Desenvolvedor › Conta de Sandbox › Gerenciar › Ajustes da conta › desligar "Permitir compras e renovações" e esperar a renovação | Sem carência, a assinatura entra em nova tentativa de cobrança e o Pro cai. Com o período de carência ligado só para o sandbox (App Store Connect › app › Assinaturas › Período de carência › Only Sandbox Environment), o Pro continua durante a carência. Religar a opção: a cobrança passa e o Pro volta |
| 8 | Compra interrompida | `interrupt <email> on`; assinar ou comprar um item | Folha pede ação extra (termos); depois de concluir, a compra chega por `Transaction.updates` e desbloqueia sem tocar de novo. Voltar com `interrupt <email> off` |
| 9 | Reembolso | Não há pedido de reembolso no app; o caso é coberto pelos testes do StoreKit e pelo Transaction Manager do Xcode | Registrar como não testado no sandbox |
| 10 | Restaurar em outro aparelho | iPad com a mesma conta de sandbox, app recém-instalado, Ajustes › Restaurar compras | Pro e itens não consumíveis voltam; consumíveis não voltam (já foram creditados) |
| 11 | Compras da loja | Comprar um pacote de ícones, o pacote completo e um consumível (proteção de sequência) | Pacote libera os ícones; o completo libera todos; o consumível credita a Jornada a cada compra e pode ser comprado de novo |
| 12 | Ask to Buy | Conta de sandbox filha num grupo familiar (opcional) | Compra fica "pendente" e libera quando aprovada |

Ao terminar: `scripts/sandbox-tester.py renewal <email> 1h`, `interrupt <email> off` e `clear <email>` para deixar a conta limpa para a próxima rodada.

## `scripts/sandbox-tester.py`

Usa a API do App Store Connect com uma chave de API (função Admin ou App Manager). A chave nunca vai para o repositório: só variáveis de ambiente.

```sh
export ASC_KEY_ID=XXXXXXXXXX
export ASC_ISSUER_ID=00000000-0000-0000-0000-000000000000
export ASC_KEY_PATH=~/.appstoreconnect/AuthKey_XXXXXXXXXX.p8

scripts/sandbox-tester.py list
scripts/sandbox-tester.py clear tester@example.com
scripts/sandbox-tester.py renewal tester@example.com 5m
scripts/sandbox-tester.py interrupt tester@example.com on
scripts/sandbox-tester.py --dry-run clear tester@example.com
```

O testador pode ser o ID ou o email da conta. `--dry-run` só imprime as requisições, sem chave e sem rede. O token JWT (ES256, 15 minutos) é assinado com o `openssl` do sistema; não há dependências.

| Comando | Requisição |
| --- | --- |
| `list` | `GET /v2/sandboxTesters` (até 200 por página, segue `links.next`) |
| `clear` | `POST /v2/sandboxTestersClearPurchaseHistoryRequest` com `relationships.sandboxTesters` |
| `renewal` | `PATCH /v2/sandboxTesters/{id}` com `subscriptionRenewalRate` (`MONTHLY_RENEWAL_EVERY_ONE_HOUR`, `_THIRTY_MINUTES`, `_FIFTEEN_MINUTES`, `_FIVE_MINUTES`, `_THREE_MINUTES`) |
| `interrupt` | `PATCH /v2/sandboxTesters/{id}` com `interruptPurchases` |
