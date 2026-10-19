# Atualização obrigatória e recomendada (18/10/2026)

O Cashly lê do CloudKit público uma política de versões por plataforma e decide sozinho se está em dia, se recomenda atualizar ou se bloqueia. Quem edita a política é o admin (aba **Versões**, `docs/admin.md`); o app só lê.

## Regra

Registro `AppRelease` por plataforma (`ios` vale para iPhone e iPad, `macos`, `visionos`) com versão mínima, build mínima, versão recomendada e build recomendada. O app compara com a própria `CFBundleShortVersionString` e `CFBundleVersion`:

| Estado | Quando | O que acontece |
| --- | --- | --- |
| `required` | versão instalada < versão mínima **ou** build instalada < build mínima | tela de bloqueio no lugar do app inteiro |
| `recommended` | não está bloqueado, mas versão < recomendada **ou** build < recomendada | aviso dispensável, uma vez por versão recomendada (`1.2.0 (80)`) |
| `current` | o resto, inclusive sem registro para a plataforma | nada |

- Versões comparam por número, parte a parte (`1.10.0` > `1.9.2`, `1.0` = `1.0.0`). No app aceita de 1 a 3 partes; o admin exige `x.y.z`.
- Sem texto livre: título e mensagem são fixos e traduzidos no catálogo.
- O app nunca bloqueia se não consegue ler a própria versão e build, e trata recomendada abaixo da mínima como igual à mínima.
- Código: `CashlyDomain/Update` (`AppVersion`, `AppRelease`, `UpdateState`, `AppReleaseStore`), `CashlyData/Services/CloudKitAppReleaseSource.swift`, `FeatureCore/Update/AppUpdateModel.swift`, telas em `AppShell/Update`.

## Leitura e cache

- O app busca o registro pelo `recordName` igual à plataforma (`CKDatabase.record(for:)`), sem consulta; registro inexistente (`unknownItem`) significa "sem política". Registro com campos inválidos conta como falha de leitura.
- A última política lida fica em `app-release.json` no app group `group.com.byescaleira` (pasta `cashly`), para widgets e intents enxergarem. Sem app group, cai na Application Support.
- **Sem rede, vale o cache.** Falha de leitura nunca apaga a política guardada, então o modo avião não escapa do bloqueio.
- Lê ao abrir e ao voltar para o primeiro plano, com intervalo mínimo de 15 minutos entre leituras (1 minuto enquanto está bloqueado, para soltar logo depois de o admin baixar a mínima). Se a última política guardada já bloqueia, a abertura espera a leitura antes de decidir.
- No simulador não há leitura do CloudKit (igual às flags); vale só a simulação.

## O que para no bloqueio

- **A interface:** a tela de bloqueio substitui o app inteiro (e a janela de Ajustes no Mac), entra e sai com fade (`.opacity`, `easeOut` de 0,2 s, como o bloqueio do app) e usa a animação `.launch` em loop: conta como uma tela de bloqueio (`motion-and-lottie.md` §4.3), igual à de Face ID. O texto cita as versões e cabe em 3 linhas: "Version 1.0 is no longer supported. Update to 1.1.0 or later. You can still export your data." (com a build entre parênteses só quando as versões são iguais e a build fica abaixo); sem política no cache fica o texto genérico, inclusive na simulação. O aviso recomendado diz "Version 1.2.0 is available…". Com o bloqueio por Face ID ligado, o `PrivacyShield` cobre também esta tela, então exportar exige autenticar. Botões: **Update** (abre `https://apps.apple.com/app/id6821986667`, do `CashlyAppStoreID` do Info.plist) e **Export Data** (JSON ou CSV, o mesmo fluxo de Ajustes › Dados e Backup). Os dados nunca ficam presos.
- **Siri, Atalhos e App Intents:** `CashlyServices.workspace` lê o cache e lança `UpdateRequiredError` ("Update Cashly in the App Store to keep using it. Your data is safe."). Vale também para as ações das notificações (marcar como pago, adiar, classificar captura), que ficam sem efeito.
- **iCloud:** a biblioteca abre sem sincronização e os espelhos de CKSyncEngine dos perfis compartilhados não iniciam.
- **MCP e Cashly na Web:** não ligam.
- **Widgets:** só leem o último resumo. O único controle interativo (`NewExpenseIntent`) apenas abre o app, que mostra o bloqueio.
- O backup automático semanal continua (só grava uma cópia local ou no iCloud Drive).

## Bloqueio com o app aberto

`UpdateHoldModel` (`FeatureCore/Update`) liga e desliga as conexões conforme `isRequired`. O `CashlyBootstrap` entrega a lista ao abrir a biblioteca (`attach`) e chama `apply()` a cada mudança do estado; as transições rodam em fila e, se o estado vira de novo no meio, o model termina no estado atual.

| Conexão | Bloqueio chega | Bloqueio sai |
| --- | --- | --- |
| Servidor MCP | `suspend()` e o model é descartado | novo `MCPModel` se a flag estiver ligada; o servidor só sobe se estava ligado nos Ajustes e com Pro |
| Cashly na Web | `settings.web = nil` | novo `WebSharingModel` (iOS, com a flag) com as sessões guardadas |
| Perfis compartilhados | `SharingCoordinator.stop()`: cancela as operações e solta os dois CKSyncEngine, guardando o estado | `start()` recria os motores a partir do estado guardado e reconcilia |
| Sincronização do SwiftData | segue | segue como abriu |

- Abertura bloqueada não liga nada; se o bloqueio sai depois, tudo liga como numa abertura normal, inclusive os perfis compartilhados.
- `CashlyServices.startSharing` e `stopSharing` entram numa fila, então um bloqueio que chega durante a partida do social para logo depois dela.
- O SwiftData não desliga o CloudKit de um `ModelContainer` aberto. Trocar o container por um sem nuvem exigiria soltar todas as referências ao antigo (janela, models, intents, change feeds) antes de abrir outro sobre o mesmo arquivo, sem como confirmar que o espelhamento do Core Data terminou; dois coordenadores no mesmo store, um deles espelhando, arriscam o histórico e um reimport inteiro. Como no bloqueio nada grava na base principal (interface, intents e ações de notificação param), o espelhamento só recebe o que vem de outros aparelhos. Por isso a sincronização do SwiftData segue até fechar o app quando o bloqueio chega aberto, e só volta ao reabrir quando a abertura foi bloqueada.

## Desenvolvimento

- Build Debug nunca bloqueia: lê e mostra a política real, mas o estado efetivo é o simulado.
- Ajustes › Developer › **App Updates**: simular `Update recommended` ou `Update required`, ver versão instalada, estado e política remotos, última leitura e **Check Now**. A simulação fica no mesmo cache, então intents também a enxergam. Para capturar com versões, gravar no cache uma `release` junto com o `simulated`, por exemplo `{"release":{"minimumVersion":"1.1.0","minimumBuild":1,"recommendedVersion":"1.2.0","recommendedBuild":1},"simulated":"required"}`. Na tela de bloqueio simulada aparece **Stop Simulating**.

## Como testar

1. Testes: `AppReleaseTests` (comparação, regra, cache), `AppReleaseRecordTests` (leitura do registro), `AppUpdateModelTests` (fontes falsas: bloqueio, cache offline, intervalo, aviso uma vez por versão, simulação), `UpdateHoldModelTests` (fontes falsas: abertura livre e bloqueada, bloqueio e liberação com o app aberto, modo avião, simulação, estado que vira no meio da transição). Admin: `cd admin && npm test`.
2. Debug: simular cada estado no Developer, conferir a tela, o export e um atalho da Siri respondendo o erro. Com MCP e Web ligados, simular `Update required` e depois `Stop Simulating`: o servidor MCP e a ponte caem e voltam sem reabrir o app.
3. Bloqueio real: precisa de configuração Release. Instalada pelo Xcode (assinatura de desenvolvimento) ela lê o ambiente Desenvolvimento; TestFlight e App Store leem Produção. No admin, no ambiente certo, gravar mínima acima da build instalada; abrir o app, ver o bloqueio, ligar o modo avião e reabrir (continua bloqueado); remover a política e voltar para o primeiro plano depois de 1 minuto (solta). Repetir com só a recomendada acima para ver o aviso uma única vez.
