---
name: cashly-import
description: Importa transações para o Cashly a partir de extratos bancários e de cartão (Open Finance, OFX, CSV, XLSX, PDF ou texto colado). Use quando a pessoa pedir para lançar, cadastrar, popular ou importar gastos, receitas, extratos ou faturas no Cashly.
---

# Importar extratos para o Cashly

O Cashly recebe transações pela ferramenta `import_transactions` do servidor MCP `cashly`. Nada é gravado direto: o app abre uma tela de conferência e a pessoa confirma. Seu trabalho é entregar dados limpos, sem duplicatas e bem categorizados.

## Antes de começar

1. Chame `get_catalog` e guarde a moeda, a data de hoje e os nomes exatos das categorias e tags.
2. Se o servidor não responder, peça para a pessoa abrir o Cashly (Mac, iPhone ou iPad) e ligar **Ajustes › Claude Code**. No iPhone e no iPad o app precisa ficar aberto; na primeira conexão o app pede aprovação.

## Ler o extrato

- Aceite OFX, CSV, XLSX, PDF de fatura ou texto colado. Leia o arquivo inteiro antes de transformar.
- Para cada linha, extraia data, descrição, valor e sentido (entrada ou saída).
- Valores em `import_transactions` são **sempre positivos**; o sentido vai em `kind` (`expense` ou `income`).
- Datas no formato `AAAA-MM-DD`. Em fatura de cartão, use a data da compra.

## Exportação de agregador (uma aba por conta e por cartão)

Arquivos como `movimentacoes_<nome>_<AAAAMMDD>_<AAAAMMDD>.xls` trazem uma aba por conta ("Conta Nubank") e por cartão ("Cartão Sicredi"). Colunas: `Data` (DD.MM.AAAA), `Descrição`, `Categoria`, `Valor` (negativo é saída), `Tags`, `Informações adicionais`; nas abas de cartão há também `Fatura` (mês da fatura). Use os scripts desta skill, que não têm dependências:

```bash
python3 -I scripts/read_xls.py arquivo.xls > abas.json
python3 -I scripts/prepare.py arquivo.xls > candidatos.json
```

`prepare.py` devolve `ready` (linhas prontas, ainda com a descrição crua em `raw` e a categoria do banco em `bank_category`) e `skipped` (contagem e total por motivo). Opções: `--holder="Nome Sobrenome"` (o padrão vem do nome do arquivo) e `--itemize-investments` (lança cada provento em vez de agrupar). O que ele já faz:

- **Linhas de fatura:** "Fatura Outubro 2026" (total da fatura, sem categoria) e "Pagamento de fatura" / "CardBankslip" ficam de fora, porque as compras do cartão já entram.
- **Parcelas:** cada mês traz uma linha `k/N` (no Sicredi também o prefixo `PARC=1NN`). As linhas de uma mesma compra viram **uma** transação com o valor total, `installments: N` e a data da 1ª parcela, calculada voltando `k−1` meses quando a 1ª não está no arquivo (`note` avisa). Compras iguais com parcelas paralelas são separadas pela sequência.
- **Transferências entre contas da pessoa:** linhas com o nome do titular e pares de mesmo valor (saída numa conta, entrada em outra, até 3 dias) ficam de fora.
- **Investimentos:** aplicações e resgates (RDB, CDB, integralização de capital) ficam de fora. Proventos (dividendos, JCP, rendimentos de FII, aluguel de ações) e custos (IR, corretagem, custódia) viram **um lançamento por mês** na categoria Investimentos, porque centenas de centavos poluem o histórico.
- **Pix no crédito:** a entrada "Valor adicionado para PIX no Crédito" fica de fora; o Pix pago a quem recebeu continua como gasto.

Regras aprendidas com extratos reais:

- **Nunca apague linhas idênticas do mesmo extrato.** Duas compras iguais no mesmo dia acontecem (dois cafés). Para conferir, some as linhas de cada `Fatura` e compare com a linha "Fatura <Mês>": a soma tem que bater.
- **Entrada interna categorizada como Salário** (`skipped.transfer_labeled_as_salary`; por exemplo "Tef" numa conta recebendo de "ENVIO TRANSFERÊNCIA" de outra conta do mesmo titular): pergunte se é renda ou transferência antes de lançar.
- **Parcelas que começaram antes do período** criam também as parcelas anteriores no app. Avise e confirme se elas ainda não existem.
- **Categorias:** a coluna `Categoria` é a classificação que a pessoa já usa. Pergunte uma vez se quer manter essas categorias (o app cria as que faltarem) ou mapear para as de `get_catalog`.

### Limpar descrições em lote

Com muitas descrições únicas (mais de 100), delegue a limpeza a um subagente com o modelo **Haiku**: entregue um JSON com `raw`, `bank_category`, `kind` e `count` de cada descrição única e peça de volta `{raw: {name, category_issue}}`, seguindo as regras de "Limpar e normalizar". O subagente não muda categorias, só sinaliza as erradas ("Hotel" em Casa). Confira uma amostra e as sinalizações antes de usar, e mostre à pessoa as categorias que você corrigir.

## Limpar e normalizar

- **Descrição legível:** troque "PAG*IFOOD 0923 SAO PAULO" por "iFood". Tire códigos, cidades e números de autorização. Mantenha o estabelecimento.
- **Parcelas:** "LOJA X PARC 03/10" vira uma transação "Loja X" com `installments: 10`, a data da **primeira** parcela e `amount` igual ao **total da compra** (valor da parcela × 10), só uma vez. O app divide e lança uma parcela por mês. Se o extrato só mostra a parcela atual, pergunte à pessoa se as anteriores já estão no app antes de criar.
- **Não conte duas vezes:**
  - Pagamento de fatura do cartão na conta corrente **não** é gasto quando as compras do cartão também estão sendo importadas.
  - Transferências entre contas da própria pessoa, aplicações e resgates de investimento não são gasto nem receita. Deixe de fora e cite no resumo.
  - Estornos: lance como `income` na mesma categoria da compra.
- **Pendentes:** contas futuras ou boletos agendados vão com `status: "to_pay"`; valores a receber, `to_receive`.

## Categorizar

- Prefira sempre uma categoria que já existe em `get_catalog`.
- Só proponha categoria nova quando muitas transações não couberem em nenhuma; use nomes curtos e comuns (Mercado, Restaurantes, Transporte, Casa, Contas, Saúde, Lazer, Educação, Compras, Assinaturas, Pets, Outros).
- Use tags para contexto que atravessa categorias (uma viagem, um evento).

## Evitar duplicatas

Para cada mês do extrato, chame `list_transactions` com `month` e compare data, valor e descrição. Pule o que já existir e informe quantas foram puladas.

## Confirmar e enviar

1. Mostre um resumo antes de enviar: período, quantidade, total de saídas e entradas, categorias novas, o que ficou de fora e por quê.
2. Envie em lotes de até 500 com `source` descrevendo a origem ("Nubank conta — outubro 2026"). Cada item: `date`, `description` (limpa), `amount` (positivo), `kind` (`expense` ou `income`), `category`, `status` (`paid`, `to_pay` ou `to_receive`) e, quando houver, `installments` e `tags`.
3. Leia a resposta: se a pessoa recusou ou a conferência ainda está aberta, não reenvie; pergunte o que ajustar.

Nunca invente transações nem valores. Se uma linha estiver ambígua, pergunte.
