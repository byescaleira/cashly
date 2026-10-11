---
name: cashly-import
description: Importa transações para o Cashly a partir de extratos bancários e de cartão (Open Finance, OFX, CSV, XLSX, PDF ou texto colado). Use quando a pessoa pedir para lançar, cadastrar, popular ou importar gastos, receitas, extratos ou faturas no Cashly.
---

# Importar extratos para o Cashly

O Cashly recebe transações pela ferramenta `import_transactions` do servidor MCP `cashly`. Nada é gravado direto: o app abre uma tela de conferência e a pessoa confirma. Seu trabalho é entregar dados limpos, sem duplicatas e bem categorizados.

## Antes de começar

1. Chame `get_catalog` e guarde a moeda, a data de hoje e os nomes exatos das categorias e tags.
2. Se o servidor não responder, peça para a pessoa abrir o Cashly no Mac e ligar **Ajustes › Claude Code**.

## Ler o extrato

- Aceite OFX, CSV, XLSX, PDF de fatura ou texto colado. Leia o arquivo inteiro antes de transformar.
- Para cada linha, extraia data, descrição, valor e sentido (entrada ou saída).
- Valores em `import_transactions` são **sempre positivos**; o sentido vai em `kind` (`expense` ou `income`).
- Datas no formato `AAAA-MM-DD`. Em fatura de cartão, use a data da compra.

## Limpar e normalizar

- **Descrição legível:** troque "PAG*IFOOD 0923 SAO PAULO" por "iFood". Tire códigos, cidades e números de autorização. Mantenha o estabelecimento.
- **Parcelas:** "LOJA X PARC 03/10" vira uma transação "Loja X" com `installments: 10` e a data da **primeira** parcela, só uma vez. Se o extrato só mostra a parcela atual, pergunte à pessoa se as anteriores já estão no app antes de criar.
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
2. Envie em lotes de até 500 com `source` descrevendo a origem ("Nubank conta — outubro 2026").
3. Leia a resposta: se a pessoa recusou ou a conferência ainda está aberta, não reenvie; pergunte o que ajustar.

Nunca invente transações nem valores. Se uma linha estiver ambígua, pergunte.
