# Validação

Como verificar o Cashly, do automático ao que depende de aparelhos e dados reais.

## Automático

Rode antes de cada commit; o Xcode Cloud repete os mesmos passos (ver [architecture.md](architecture.md#integração-contínua)).

```sh
scripts/lint.sh
scripts/build.sh Debug
scripts/test.sh
scripts/audit.sh
```

Para o layout em telas grandes, `scripts/ui-test.sh` roda o scheme `CashlyUITests` (padrão: iPad Pro 13", iOS 27; outro destino com `CASHLY_TEST_DESTINATION`, um teste só com `-only-testing:CashlyUITests/<Classe>/<teste>`). No fim ele exporta capturas e medidas para a pasta impressa em `Captures:`. As capturas do iPad deitado saem giradas no arquivo, mas mostram a tela inteira.

`scripts/audit.sh` compila o `CashlyAudit` em Release e roda `check`, que falha com código 1 se qualquer verificação divergir:

| Grupo | O que confere |
| --- | --- |
| Migração | Banco V1 sintético aberto no schema atual: 2 usuários, 1 categoria, 1 orçamento, 1 tag, 1 transação e 1 participante; R$ 100,01 vira 10.001 centavos, rateio igual soma o original e as três parcelas do proprietário somam 5.001 centavos; a tag legada vira ID |
| Preview | O `SampleDatabase` carrega 5 usuários e 10 transações |
| Volume | 1.000 registros: primeira página de 50, próxima página sem repetir IDs, total do usuário em centavos, detalhe por ID, outro usuário não enxerga o registro, conflito de orçamento resolvido com um alias preservado |

## Compras (StoreKit)

O `SKTestSession` só funciona num bundle de testes hospedado no app: nos testes do pacote o processo é o `com.apple.dt.xctest.tool`, o StoreKit recusa a configuração (`SKServiceErrorDomain Code=2`, "Error saving configuration file") e nenhum produto carrega (verificado no Xcode 27.0 beta 6 com iOS 27.0). Por isso os testes de compras ficam no alvo `CashlyStoreTests` (pasta `Cashly/CashlyStoreTests`, iOS, hospedado no `Cashly.app`), com o scheme compartilhado `CashlyStoreTests` e o test plan `Cashly/StoreKit.xctestplan`, que aponta para o `Cashly/Cashly/Cashly.storekit` e roda em série.

```sh
scripts/store-test.sh
scripts/store-test.sh -only-testing:CashlyStoreTests/StoreKitTests/Subscription
```

Padrão: iPhone 17, iOS 27; outro destino com `CASHLY_TEST_DESTINATION`. Cada teste abre um `SKTestSession` novo (`resetToDefaultState`, `disableDialogs`, `clearTransactions`) e usa o `StoreKitClient` e o `StoreModel` reais, com banco em memória e um usuário para os créditos da Jornada.

| Grupo | O que confere |
| --- | --- |
| Catálogo | Todos os `ShopItem` carregam; preço exibido, período e 7 dias grátis do Mensal e do Anual; preços da loja; centavos do `Product.price` (problema conhecido, abaixo) |
| Assinatura | Teste grátis em cada plano e elegibilidade antes e depois (o grupo inteiro perde); renovação forçada vira pago; expirar (renovação desligada e tempo acelerado); desligar a renovação mantém o Pro; reembolso revoga; Ask to Buy pendente, aprovado e recusado; falha simulada na compra; nova tentativa de cobrança (`inBillingRetryPeriod`) e volta a pago ao resolver; carência (`inGracePeriod`) mantém o Pro; restaurar num segundo `StoreModel` |
| Loja | Não consumível compra e continua no segundo `StoreModel`; pacote completo libera os ícones; restaurar; reembolso tira o item; consumíveis creditam a Jornada a cada compra |

Upgrade e downgrade entre Mensal e Anual entram depois que os níveis do grupo forem definidos, numa suíte `PlanChange` no mesmo molde (`StoreKitFixture.subscribe(to:)`, `forceRenewalOfSubscription`, `renewalState()`):

- upgrade Mensal → Anual imediato: transação nova do Anual, a do Mensal revogada como upgrade, entitlement ativo sem passar por expirado;
- downgrade Anual → Mensal só na renovação: o Anual segue até a renovação forçada, depois vem o Mensal pago;
- voltar ao plano original antes da renovação cancela o downgrade;
- trocar de plano não devolve o teste grátis;
- o tempo de Pro (`proMonths`) continua contando na troca.

### Workflow no Xcode Cloud

Configurado em App Store Connect › Cashly › Xcode Cloud › Manage Workflows:

1. **Novo workflow** `StoreKit`, produto Cashly, workspace `Cashly.xcworkspace`.
2. **Environment**: Xcode mais recente (27.x) e macOS mais recente. Se os testes falharem todos com `SKInternalErrorDomain Code=3`, fixar uma versão do Xcode e do simulador em que o StoreKit Testing funcione (ver limitações abaixo).
3. **Start Conditions**:
   - Pull Request Changes para `development` e `main`, com **Files and Folders** restrito a `CashlyKit/Sources/FeatureStore/`, `CashlyKit/Sources/CashlyDomain/Store/`, `Cashly/Cashly/Cashly.storekit`, `Cashly/CashlyStoreTests/` e `Cashly/StoreKit.xctestplan`.
   - Branch Changes em `development` com o mesmo filtro.
   - Scheduled: semanal, na `development`, para pegar mudanças do Xcode e do simulador.
4. **Action Test**: plataforma iOS, scheme `CashlyStoreTests`, test plan `StoreKit`, destino iOS Simulator › iPhone 17 (Recommended Simulators ou o iOS 27 fixo), Required to pass.
5. Sem Archive nem Post-Actions; notificação por email só em falha.

O `ci_scripts/ci_pre_xcodebuild.sh` não roda lint nem audit no scheme `CashlyStoreTests` (o workflow principal já roda).

### Limitações

- O Xcode Cloud só simula o StoreKit local: não toca no sandbox nem no App Store Connect. Preços, períodos e ofertas vêm do `Cashly.storekit`; divergência entre o arquivo e o App Store Connect só aparece no sandbox ([subscription-sandbox.md](subscription-sandbox.md)).
- Comportamentos do StoreKit Testing no Xcode 27.0 beta 6 com iOS 27.0, marcados com `withKnownIssue` intermitente (o teste continua passando quando a Apple corrigir):
  - `Product.price` perde os centavos com a vitrine BRA/pt_BR (14,90 vira 14), embora o `displayPrice` venha certo. Só afeta o preço por mês e a economia do paywall no StoreKit local.
  - Em nova tentativa de cobrança sem carência, a renovação que falhou continua em `Transaction.currentEntitlements`, então o `StoreModel` mantém o Pro. Na produção a Apple tira a assinatura de `currentEntitlements` nesse estado.
- `expireSubscription(productIdentifier:)` muda a transação do `SKTestSession` mas não chega ao `Transaction.currentEntitlements`; o teste de expirar desliga a renovação e acelera o tempo (`timeRate = .oneRenewalEveryTwoSeconds`). Os testes também não dependem de `Transaction.updates`: depois de cada ação do `SKTestSession` chamam `refresh()` até o estado mudar, por até 10 s.
- `clearTransactions()` demora a devolver a elegibilidade ao teste grátis; o `StoreKitFixture` espera os dois planos ficarem elegíveis (até 5 s) antes de cada teste.
- Há relatos de StoreKit Testing quebrado em outras combinações (Xcode 26.5 com iOS 26.5: `SKInternalErrorDomain Code=3` em tudo). Se o Xcode Cloud mudar de versão e todos os testes falharem assim, fixar o Xcode e o simulador no workflow.
- Não dá para simular a folha da Apple (cancelar pelo usuário), mensagens de cobrança, Family Sharing nem a troca de aparelho de verdade.

## Diagnóstico manual

```sh
swift build -c release --package-path CashlyKit --product CashlyAudit
CashlyKit/.build/release/CashlyAudit create-legacy /tmp/cashly-legacy/legacy.store
CashlyKit/.build/release/CashlyAudit audit /tmp/cashly-legacy/legacy.store
CashlyKit/.build/release/CashlyAudit preview
CashlyKit/.build/release/CashlyAudit benchmark 10000
CashlyKit/.build/release/CashlyAudit profile <pasta do benchmark>/benchmark.store
```

- `audit` copia o SQLite e os arquivos WAL/SHM para uma pasta temporária antes de abrir com o schema atual; o banco original não é tocado. Feche o app antes de copiar um banco real. O relatório de um banco real pode conter IDs e totais e deve ficar local.
- `benchmark` cria a base numa pasta temporária própria e imprime o caminho em `BENCH_STORE`; `profile` aceita só esse `benchmark.store`.
- Os tempos são de uma execução local, sem isolamento de CPU; não são promessa de latência num iPhone. Referência anterior: 50 mil transações no mesmo mês levaram 12,1 s no resumo do período (ver [backlog.md](backlog.md)).

## Antes de distribuir

1. **CloudKit em dois aparelhos assinados.** Offline e reconexão, referências que chegam em momentos diferentes, conflito de orçamento editado nos dois, exclusões, troca de usuários e duas janelas no iPad.
2. **Backup.** Exportar num aparelho, apagar tudo, importar e conferir contagens e totais; importar num segundo aparelho com iCloud e ver os registros chegarem ao primeiro.
3. **Interface.** Criar, editar e excluir em cada editor; inspector no iPad; iPhone em paisagem; app no Mac; VoiceOver e Dynamic Type nos gráficos e seletores de ícone.

No simulador o app usa o banco local com CloudKit desligado; nos aparelhos, o container `iCloud.cashly` precisa das capabilities e da assinatura.
