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

## 3. MCP para o Claude Code (implementado)

**Onde roda:** dentro do próprio app, em qualquer aparelho (Mac, iPhone, iPad, Vision Pro), ligado em Ajustes › Claude Code. Por padrão atende só o próprio aparelho (127.0.0.1); com "Aceitar conexões da rede local", computadores da mesma rede alcançam o aparelho pelo IP mostrado no comando de instalação (e por Bonjour, `_cashly-mcp._tcp`). No iPhone e no iPad, o app precisa estar aberto.

**Segurança em três camadas:**
1. **Token** no cabeçalho `Authorization`, gerado pelo app e trocável a qualquer momento (trocar desconecta todos).
2. **Aprovação da conexão no app:** quando um cliente novo chama `initialize`, o app mostra "Conectar o Claude Code?" com o nome do cliente e o endereço. Sem aprovação não há sessão (`Mcp-Session-Id`), e qualquer outra chamada é recusada. Conexões aprovadas ficam listadas nos Ajustes e podem ser removidas.
3. **Aprovação de toda escrita:** `import_transactions` abre a conferência no padrão dos guias (totais, categorias e tags novas, problemas) com Importar ou Recusar. O Claude recebe importado, recusado ou aguardando.

**Ferramentas:** `get_catalog`, `get_summary`, `list_transactions`, `list_budgets`, `run_analysis`, `import_transactions`.

**Plugin:** `plugins/cashly`, com as skills `cashly-import` e `cashly-insights` (ver README).

**Login com Apple:** não adotado por enquanto. Sem servidor próprio, o token de identidade da Apple não teria quem o validasse; a aprovação no aparelho é que garante quem conecta. Quando a parte social chegar, a identidade vem do iCloud da pessoa (`CKContainer.userRecordID`), sem tela de login.

## Ordem sugerida

1. **MCP de leitura no Mac** depois da fundação do motor de análise (fase A de [analytics.md](analytics.md)): o retrato e as análises já existem nessa fase.
2. **Cobrança por arquivo ou link.**
3. **Progresso compartilhado com amigos**, junto com a gamificação.
4. **Grupos de despesas no iCloud.**
