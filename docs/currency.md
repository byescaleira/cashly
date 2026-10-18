# Moedas e cotação (15/10/2026)

Objetivo: deixar o Cashly lidar com mais de uma moeda sem perder a honestidade dos números. Toda conversão é **estimativa de apoio**: bancos aplicam taxas, spread e datas de fechamento próprias, então o valor da fatura pode ser diferente. Toda tela que mostra um valor convertido diz isso.

## Fonte das cotações

| Ordem | Fonte | Uso |
| --- | --- | --- |
| 1 | `fawazahmed0/exchange-api` no jsDelivr (`cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@{data}/v1/currencies/{base}.min.json`) | Principal. Grátis, sem chave, CDN (~0,3 s), cerca de 150 moedas, qualquer base, histórico desde 02/03/2024, inclusive fins de semana |
| 2 | Espelho da mesma API no Cloudflare Pages (`{data}.currency-api.pages.dev`) | Quando o jsDelivr falha |
| 3 | Frankfurter (`api.frankfurter.dev/v1/{data}?base=`) | Reserva. Taxas de referência do BCE desde 1999, cerca de 30 moedas, só dias úteis |

- Sem chave de API, então nada secreto vai no app.
- O target `CashlyExchange` faz a rede e o cache; as features só conhecem o protocolo `ExchangeRateProviding` do domínio.
- Uma consulta traz a tabela inteira de uma base numa data (`ExchangeTable`). A tabela de uma data passada nunca muda e fica em cache para sempre; a de hoje (`latest`) vale por uma hora.
- As moedas oferecidas para pagamento são as que a API lista e o sistema reconhece como moeda ISO (sem metais e criptomoedas). Sem rede, a lista cai nas 10 moedas do app.

## 1. Troca da moeda do app

Cada registro guarda a moeda em que foi gravado (`currencyCode`). Quando a pessoa troca a moeda do app, o Cashly busca na hora as cotações de todas as moedas do app para a nova e guarda uma `CurrencyCorrection` (moeda de destino, data, taxas) nos ajustes.

- Ao ler, registros gravados em outra moeda aparecem convertidos pela correção, marcados como estimativa (`CurrencyEstimate` no `Transaction` e no `Budget`). Totais, orçamentos e gráficos usam o valor convertido.
- **O valor convertido nunca é gravado.** No editor, valor, parcelas e participantes de um registro estimado ficam travados e a gravação devolve o valor e a moeda originais. Descrição, categoria, data, tags e status continuam editáveis.
- Voltar para a moeda antiga gera uma correção nova, com as cotações daquele momento; os registros naquela moeda voltam a aparecer sem conversão.
- Sem rede no momento da troca, a moeda muda sem correção (como antes: só o símbolo) e Ajustes › Moeda oferece buscar as cotações de novo.

## 2. Transação paga em outra moeda (Cashly Pro)

No editor, "Paga em" escolhe a moeda do pagamento. O campo de valor passa a ser o valor pago naquela moeda, e logo abaixo aparece o valor real na moeda do app.

- A cotação é a da **data da transação**, fixa: a pessoa não edita. Mudar a data ou a moeda busca a cotação de novo; mudar o valor só refaz a conta.
- Gravado em `TransactionEntity`: `paidCurrencyCode`, `paidMinorUnits`, `exchangeRate` (texto decimal exato: 1 unidade paga = taxa na moeda do registro) e `exchangeRateDate`. O valor real vai no `amountMinorUnits` de sempre, então parcelas, participantes, orçamentos e relatórios não mudam.
- Escolher uma moeda diferente da do app exige Cashly Pro; sem Pro abre o paywall.
- A linha da transação mostra o valor pago em segundo plano (por exemplo "¥ 1.500").

## 3. Conversor rápido

Botão na toolbar do Início, rota `.converter`, target `FeatureConverter`. Valor, moeda de origem, moeda de destino, troca rápida e resultado com a taxa e a hora da cotação. Usa a cotação mais recente (`latest`), com o aviso de estimativa no rodapé.

## Banco e backup

- Schema V6: os quatro campos opcionais em `TransactionEntity`. O V5 fica congelado em `CashlySchemaV5`. Migração leve, compatível com CloudKit.
- Backup: `TransactionRecord` ganha `currency` e os dados do pagamento em outra moeda; `BudgetRecord` ganha `currency`. Todos opcionais, então backups antigos continuam abrindo com a moeda do arquivo.

## Etapas

| Etapa | Entrega |
| --- | --- |
| a | Domínio (`ExchangeTable`, `ExchangeRateProviding`, `TransactionExchange`, `CurrencyEstimate`, `CurrencyCorrection`, conversão de `Money`), `CashlyExchange` com cache, schema V6 e backup |
| b | Correção ao trocar a moeda, leitura convertida e editores travados para registros estimados |
| c | Transação paga em outra moeda no editor, com Pro |
| d | Conversor rápido |
| e | Teste no iPhone físico |
