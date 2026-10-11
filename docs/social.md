# Social e MCP

Proposta para compartilhar gastos entre pessoas, acompanhar a evolução de amigos sem expor valores e ligar o Cashly ao Claude Code por MCP. Mantém a regra do app: sem servidor próprio e sem dados financeiros fora do aparelho e do iCloud da pessoa.

## 1. Compartilhar gastos (app para app)

Dois níveis, do mais simples ao completo:

| Nível | Como funciona | Tecnologia | Esforço |
| --- | --- | --- | --- |
| **Cobrança por arquivo ou link** | "Enviar para Ana" gera um arquivo `.cashly` (ou link universal) com a descrição, a data, o valor total e a parte da Ana. A Ana toca, o Cashly dela abre uma folha no padrão dos guias ("Ana, você deve R$ 45,00 do Jantar") e cria a transação "A pagar". Quando ela paga, pode devolver a confirmação do mesmo jeito. | `Transferable` + `ShareLink`, tipo de arquivo exportado, `onOpenURL` | Pequeno |
| **Grupo de despesas compartilhado** | Um grupo (casa, viagem) que vive numa zona do iCloud compartilhada com quem foi convidado. Todos veem e lançam as despesas do grupo; cada um continua com as finanças pessoais privadas. Saldo de quem deve a quem, acerto e cobrança via Pix. | CloudKit sharing (`CKShare`) numa zona própria, sincronizada com `CKSyncEngine` | Grande |

O primeiro nível já cobre a maior parte do uso (dividir uma conta com alguém) e serve de base para o segundo. O segundo depende do item "Quem pagou" do backlog (pagador, dívida e acerto) e do modelo `Obligation`/`Settlement`.

## 2. Evolução dos amigos, sem valores

**Princípio:** o aparelho calcula e só publica números relativos. Valores em reais nunca saem.

O que um amigo vê:
- **Pontuação de saúde** (200 a 1.000) e a tendência do mês;
- **Sequência** de dias registrando;
- **Uso do orçamento** em faixa ("No caminho", "Perto do limite"), nunca o valor;
- **Conquistas e desafios** concluídos;
- **Metas** em porcentagem ("Reserva: 62%").

**Como, sem servidor:**
- Cada pessoa tem uma zona "Progresso" no próprio iCloud, com um único registro que o app atualiza quando os dados mudam.
- Adicionar um amigo é compartilhar essa zona por convite (`CKShare` só de leitura), por link ou QR. A pessoa vê exatamente o que vai compartilhar antes de aceitar e pode desfazer a qualquer momento.
- A tela "Amigos" lê as zonas compartilhadas com ela. Também dá para fazer desafios em grupo ("mês dentro do orçamento") comparando só o cumprido/não cumprido.

**Depende de:** histórico da pontuação e eventos de gamificação (ver [roadmap.md](roadmap.md)), para haver o que mostrar além do número do mês.

## 3. MCP para o Claude Code

Objetivo: perguntar ao Claude Code sobre as próprias finanças ("quanto gastei com delivery este ano?", "monte um orçamento para novembro") com os números calculados pelo Cashly.

**Proposta: um executável `cashly-mcp` dentro do app do Mac**, falando MCP por stdio com o SDK oficial em Swift (`modelcontextprotocol/swift-sdk`). Instalação em uma linha:

```sh
claude mcp add cashly -- /Applications/Cashly.app/Contents/MacOS/cashly-mcp
```

**De onde vêm os dados:** o app do Mac já recebe os dados do iPhone pelo iCloud. O app grava um retrato de leitura (o mesmo `LedgerSnapshot` do motor de análise) no App Group a cada mudança; o `cashly-mcp` lê esse retrato. Assim o executável não abre o banco SwiftData ao mesmo tempo que o app e não exige mover o banco de lugar.

**Ferramentas (fase 1, só leitura):**

| Ferramenta | Devolve |
| --- | --- |
| `summary` | Resumo de um período: entradas, saídas, saldo, pontuação |
| `transactions` | Transações filtradas por período, categoria, tag, texto e valor |
| `budgets` | Orçamentos com planejado, gasto e situação |
| `categories` e `tags` | Catálogo com totais |
| `analysis` | Qualquer análise registrada no motor (previsão, assinaturas, ritmo do mês), com a origem dos números |

**Fase 2, escrita:** `add_transaction`, `set_budget`. As escritas não mexem no banco direto: viram pedidos que o app aplica ao abrir (ou por App Intents), com a regra de que o Claude Code mostra o que vai criar antes.

**Privacidade:**
- O executável só lê o retrato local e não acessa a rede.
- Pode ser desligado nos Ajustes, o que apaga o retrato.
- O conteúdo enviado ao Claude é o que as ferramentas devolvem; a pessoa decide quando chamar.

**No iPhone:** o mesmo conjunto de ferramentas vira App Intents (Siri e Atalhos) e as ferramentas do assistente com Foundation Models, porque todas leem o mesmo motor.

## Ordem sugerida

1. **MCP de leitura no Mac** depois da fundação do motor de análise (fase A de [analytics.md](analytics.md)): o retrato e as análises já existem nessa fase.
2. **Cobrança por arquivo ou link.**
3. **Progresso compartilhado com amigos**, junto com a gamificação.
4. **Grupos de despesas no iCloud.**
