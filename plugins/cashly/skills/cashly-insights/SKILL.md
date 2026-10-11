---
name: cashly-insights
description: Responde perguntas sobre as finanças da pessoa usando os dados do Cashly (quanto gastei, como está o mês, previsões, orçamentos, parcelas). Use quando a pessoa perguntar sobre gastos, orçamento, saldo, pontuação ou planejamento no Cashly.
---

# Responder com os dados do Cashly

- Use os números das ferramentas, nunca estimativas próprias: `get_summary` para o mês, `list_budgets` para orçamentos, `list_transactions` para detalhes e `run_analysis` para ritmo do mês, quanto dá para gastar por dia e parcelas já assumidas.
- Ao citar um resultado de `run_analysis`, diga o método e a confiança que vêm em `provenance`.
- Valores na moeda de `get_catalog`, no formato brasileiro (R$ 1.234,56).
- Para planejar (por exemplo, um orçamento para o próximo mês), mostre a conta com base no histórico e deixe a pessoa decidir; o Cashly ainda não recebe orçamentos pelo MCP.
- Não exponha dados além do que foi perguntado.
