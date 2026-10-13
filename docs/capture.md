# Captura de gastos (fase 9.2, revisada em 13/10/2026)

Objetivo: tornar o registro de um gasto quase automático. O pagamento acontece, o Cashly fica sabendo, propõe categoria e descrição, e a pessoa só confirma — na notificação, na Tela Bloqueada ou de uma vez dentro do app. Referência do usuário: o app Kelo, que oferece um atalho para completar o gasto a cada compra no Apple Pay.

## O que o iOS permite

| Fonte | Como chega ao Cashly | Cobertura |
| --- | --- | --- |
| Apple Pay (qualquer cartão na Carteira: Nubank, Inter, C6, BTG, BB, Caixa, Sicredi…) | Automação "Transação" do app Atalhos, com "Executar imediatamente", chamando um intent do Cashly com valor, estabelecimento, cartão e data | Toda compra feita pelo Apple Pay (iPhone, Watch, online com Apple Pay). Apple Card também informa compras no cartão físico |
| Compras no cartão físico, Pix, boleto, débito em conta | **Nenhum app pode ler as notificações de outros apps** no iOS, e o Atalhos não tem gatilho "notificação recebida". O caminho é a pessoa compartilhar com o Cashly (texto ou captura de tela do comprovante/notificação) pela folha de compartilhamento | Depende de um toque da pessoa, mas o Cashly lê valor e estabelecimento sozinho |
| Extrato do banco | Importação de planilha/CSV (já existe pelo Claude Code; entra no app na fase 10) | Lote, depois do fato |
| Open Finance | Agregador contratado + backend (fase futura, custo recorrente) | Tudo, automático |

Conclusão: a automação do Wallet cobre a maior parte das compras do dia a dia; a folha de compartilhamento cobre o resto sem servidor. As duas alimentam a mesma **caixa de entrada**.

## Desenho

### Caixa de entrada (`Capture`)

Cada pagamento vira uma **captura** antes de virar transação: valor, estabelecimento, cartão, data, origem (`wallet`, `share`, `manual`), sugestão (categoria, descrição, tags) e estado (`pending`, `accepted`, `dismissed`). Fica no banco do app (SwiftData, schema V5), por perfil, sincroniza pelo iCloud como o resto.

- Capturar **não exige Cashly Pro** (a automação não pode falhar em silêncio depois do teste); **converter em transação exige**, como qualquer escrita.
- Uma captura aceita vira uma transação quitada, sem participantes, e guarda o vínculo para não duplicar se o mesmo pagamento chegar duas vezes (mesmo valor, estabelecimento e minuto).

### Memória de estabelecimentos (`MerchantMemory`)

Para cada estabelecimento normalizado (minúsculas, sem acentos, sem "*", números e sufixos de maquininha), o Cashly lembra a última categoria, descrição e tags usadas. A sugestão de uma captura nova vem daí; sem histórico, cai na categoria mais usada do mês. Cada aceite reforça a memória, então a segunda compra no mesmo lugar já chega pronta.

### Intent `CaptureTransactionIntent`

Roda em segundo plano, sem abrir o app: recebe valor, estabelecimento, cartão e data do Atalhos, grava a captura, calcula a sugestão e agenda a notificação. É o intent que a automação do Wallet chama. Os intents atuais (registrar gasto, resumo do mês, saldo da categoria, marcar como paga) continuam para a Siri.

### Notificação por captura

"R$ 32,90 em iFood" · "Sugestão: Delivery. Toque para classificar."

- Ações: a categoria sugerida ("Delivery ✓"), mais duas categorias frequentes, "Outra…" (abre o app no editor preenchido) e "Ignorar". As ações são registradas de novo a cada mudança de dados, com as categorias do perfil.
- Com o aparelho bloqueado as notificações **empilham** na Central de Notificações e cada uma se resolve sozinha; as ações que gravam exigem desbloquear (`authenticationRequired`).
- O ícone do app mostra o número de capturas pendentes.

### Dentro do app: "Para classificar"

- Na tela inicial, um cartão "3 gastos para classificar" acima do resumo; em Transações, uma seção no topo.
- `CaptureReviewScreen`: lista com valor, estabelecimento, cartão e data; cada linha mostra a sugestão como chip. Deslizar para a direita aceita a sugestão, para a esquerda ignora; tocar abre o editor preenchido. Botão "Aceitar todas as sugestões" quando todas têm sugestão, e um modo "uma por vez" (carrossel com os três botões: aceitar, editar, ignorar) para passar rápido pelo lote.
- Capturas ignoradas somem da lista, mas ficam 30 dias para desfazer.

### Folha de compartilhamento (`CashlyShare`)

Extensão que recebe texto e imagens de qualquer app (comprovante do banco, captura de tela da notificação, Pix). Lê valor, estabelecimento e data no aparelho (texto: expressões; imagem: Vision OCR), cria a captura e mostra a mesma notificação. Sem rede, sem servidor.

### Guia e Ajustes

- O guia "Registrar num toque" passa a ensinar a automação com imagens, com o botão que abre o app Atalhos e a lista de cartões que valem. Também explica o compartilhamento.
- Ajustes › Captura: notificar a cada captura (ligado), aceitar sozinho quando a sugestão vier da memória (desligado), e o que fazer com capturas antigas.

## Etapas

| Etapa | Entrega |
| --- | --- |
| 9.2a | Domínio `Capture` + `MerchantMemory`, schema V5, repositório e testes; `CaptureTransactionIntent`; notificação por captura com ações; ícone com contador — feita em 13/10/2026 |
| 9.2b | "Para classificar": cartão na tela inicial, seção em Transações, `CaptureReviewScreen` com deslizar, "aceitar todas" e modo uma por vez; editor preenchido a partir da captura |
| 9.2c | Guia "Registrar num toque" refeito, Ajustes › Captura, frases novas da Siri; `CashlyShare` (folha de compartilhamento) com leitura de texto e OCR |
| 9.2d | Ferramenta MCP para listar/aceitar capturas; widget "Para classificar"; exploração do Open Finance (fase futura) |

Fora do escopo por limite da plataforma: ler notificações de outros apps, gatilho automático para Pix/boleto/cartão físico sem Apple Pay.
