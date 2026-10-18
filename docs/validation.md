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
