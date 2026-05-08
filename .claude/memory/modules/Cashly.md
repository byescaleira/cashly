# Módulo: Cashly (App)

## Identidade

- **Tipo**: App target (Xcode project)
- **Path**: `Cashly/Cashly.xcodeproj` (sources em `Cashly/Cashly/`)
- **Não é SPM target**: é o shell `.xcodeproj` que linka `CashlyKit` + `Ryze` e provê o `@main`.
- **Arquivos Swift**: 1 (`CashlyApp.swift`)
- **Bundle id**: `br.com.rafaelescaleira.Cashly`
- **Plataformas**: iOS 26 / macOS 26 / visionOS 26

## Responsabilidade

**Composition root.** Contém:

- `CashlyApp.swift` (79 linhas):
  - Importa todos os sub-frameworks Ryze + Cashly + CashlyMock.
  - Instancia 6 `@StateObject` stores via `CashlyPresentationFactory.shared.makeXStore()`.
  - Define `WindowGroup { MainScreen() ... }`.
  - Em simulador: aplica `.cashlyPreview()` (todos os mocks).
  - Em device: injeta cada store como `@EnvironmentObject` + cada state como `@Environment` + a closure `\.action` apontando para `handler(action:)`.
  - `handler(action:)` é o dispatcher central: `Task(priority: .high) { @MainActor in switch ApplicationAction { ... } }` despacha para o store correto.
- `Assets.xcassets/`: AccentColor, AppIcon (recém-adicionado), CashlyIcon (asset image).
- `CashlyIcon.icon`: pasta com o asset do icon (sistema de Liquid Glass icon? Apple icon composer?).
- `Cashly.entitlements`: iCloud (`iCloud.cashly`, CloudDocuments + CloudKit), aps-environment dev.
- `Info.plist`: NSUbiquitousContainers (com placeholder `"NomeDoSeuApp"`), UIBackgroundModes (`remote-notification`, `processing`, `fetch`).

## Schemes

- **Production.xcscheme** — única scheme compartilhada.

## Build settings notáveis

- `SWIFT_VERSION = 5.0` (⚠️ inconsistente com `swift-tools-version: 6.2` do pacote)
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`
- `IPHONEOS_DEPLOYMENT_TARGET = 26.0`, `MACOSX_DEPLOYMENT_TARGET = 26.0`, `XROS_DEPLOYMENT_TARGET = 26.0`
- `TARGETED_DEVICE_FAMILY = "1,2,7"`

## Observações / dívidas

1. **`SWIFT_VERSION = 5.0` no app vs `swift-tools 6.2` no pacote** — discrepância potencialmente perigosa. Verificar com `xcodebuild -showBuildSettings` qual modo realmente é compilado o pacote quando consumido pelo app.
2. **`NSUbiquitousContainerName = "NomeDoSeuApp"`** no Info.plist é placeholder não preenchido — afeta UX no app Files e iCloud Drive.
3. **APS environment ainda em `development`** — bloqueia push em produção.
4. **App usa simulator-conditional preview**: `#if targetEnvironment(simulator) { .cashlyPreview() } else { ... real stores ... }`. Significa que rodar no simulador NÃO testa o stack real. ⚠️ Risco: bug que só aparece em device.
5. **Composition root mistura `@StateObject` + `@Environment` + closure**: 6 stores como `@StateObject`, 6 estados como `@Environment` + uma `\.action` global. Quantidade de plumbing alta.
