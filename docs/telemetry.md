# Métricas de uso e feature flags

Proposta para medir o uso do app e ligar ou desligar recursos sem nova versão, mantendo a promessa de privacidade: **nenhum valor, descrição ou nome financeiro sai do aparelho**. O "motor de análise" ([analytics.md](analytics.md)) é outra coisa: ele analisa as finanças da pessoa dentro do aparelho; aqui o assunto é como o produto é usado.

## Métricas de uso

### Camadas

| Camada | Para quê | Custo |
| --- | --- | --- |
| **MetricKit + Xcode Organizer** | Travamentos, tempo de abertura, consumo de memória e bateria | Grátis, já vem no sistema |
| **App Store Connect (App Analytics)** | Instalações, retenção, conversão de assinatura, origem | Grátis, só de quem aceitou compartilhar com desenvolvedores |
| **Eventos de produto (recomendado: TelemetryDeck)** | Funis (onboarding → primeira transação → assinatura), uso de recursos, importações | Plano gratuito cobre o início; SDK em Swift, dados anônimos por padrão, servidor na Europa |

O TelemetryDeck se encaixa melhor que Firebase ou Mixpanel: não usa identificador de publicidade, gera um identificador anônimo com hash e não exige banner de consentimento. O selo da App Store fica como "Dados de uso — não vinculados a você". Alternativa com controle total: PostHog hospedado por conta própria, mas exige servidor.

### Como fica no código

- **`UsageTracking`** (protocolo no `FeatureCore`) com `track(_ event: UsageEvent)`.
- **`UsageEvent`:** `enum` fechado com parâmetros só categóricos, como origem, quantidade em faixas e nome do passo. Por ser fechado, não há como mandar um valor ou uma descrição por engano.
- **Implementações:**
  - `TelemetryDeckTracker` num target `CashlyTelemetry`, o único que importa o SDK;
  - `NoopTracker` para testes, previews e para quem desligar.
- **Envio a partir dos modelos**, no `@Environment(\.usage)`, nunca das views.
- **Ajustes › Privacidade:** "Compartilhar uso anônimo" (ligado por padrão, explicado em uma frase), e ao desligar nada é enviado.

### Eventos iniciais

| Evento | Parâmetros |
| --- | --- |
| `onboarding_step` / `onboarding_done` | passo, categorias escolhidas (quantidade) |
| `transaction_created` | origem: manual, planilha, Claude, Siri; parcelado: sim/não |
| `import_finished` | origem; quantidade em faixa (1–10, 11–100, 100+); linhas com problema: sim/não |
| `guide_opened` | qual guia |
| `budget_created`, `category_created` | — |
| `analysis_viewed` | qual análise |
| `paywall_viewed`, `trial_started`, `subscribed` | plano |
| `mcp_enabled`, `mcp_tool_called` | ferramenta |

Funis prontos no painel: abertura → onboarding concluído → primeira transação → 7 dias ativo → teste grátis → assinatura.

## Feature flags

### Como fica no código

- **`FeatureFlag`** (`enum` no `FeatureCore`) com o valor padrão de cada flag no próprio código: `mcpServer`, `foundationModels`, `socialProgress`, `spreadsheetImport`, `paywallVariant`.
- **`FeatureFlags`** (`@Observable`) resolve cada flag nesta ordem:
  1. ajuste manual de desenvolvimento (menu escondido nos Ajustes, só em Debug e TestFlight);
  2. valor remoto;
  3. padrão do código.
- **Uso nas views:** `@Environment(FeatureFlags.self)` e `flags.isOn(.mcpServer)`. Os testes injetam um `FeatureFlags` com valores fixos.

### De onde vem o valor remoto, sem servidor

**Recomendado: banco público do CloudKit.**
- Um registro `Config` com as flags, lido sem login.
- Já faz parte do container do app, é grátis e é editado no CloudKit Console.
- O app lê ao abrir e guarda a última versão; sem rede, vale o último valor conhecido.

**Lançamento gradual e testes A/B:**
- Cada flag pode ter `rollout` (0–100%).
- O app sorteia pelo hash de um identificador anônimo do aparelho, então a mesma pessoa cai sempre no mesmo grupo.
- O grupo vai junto nos eventos (`paywallVariant: B`) para comparar no TelemetryDeck.

**Interruptor de emergência:** toda funcionalidade nova nasce atrás de uma flag. Se der problema, desliga no Console sem esperar revisão da App Store.

## Ordem sugerida

1. `FeatureFlags` com padrões locais e menu de desenvolvimento. Pequeno, e já protege o MCP e as próximas features.
2. `UsageTracking` + `NoopTracker` + catálogo de eventos (sem SDK ainda).
3. Valor remoto pelo CloudKit público.
4. TelemetryDeck, junto com a assinatura, quando os funis passarem a importar.
