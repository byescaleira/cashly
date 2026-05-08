# Tech Stack — Estado Real

> Gerado por `project-onboarder` em 2026-05-08 a partir de discovery do projeto Cashly.
> Reflete o que ESTÁ EM USO, não o que gostaríamos que estivesse.

## Linguagem

- **Swift package**: `swift-tools-version: 6.2` (`CashlyKit/Package.swift:1`)
- **Swift compiler do app Xcode**: `SWIFT_VERSION = 5.0` (`Cashly/Cashly.xcodeproj/project.pbxproj`)
  - ⚠️ ambíguo: o pacote pede toolchain 6.2, mas o target do app está fixado em 5.0. Discrepância a confirmar.
- **Concurrency settings (app target)**:
  - `SWIFT_APPROACHABLE_CONCURRENCY = YES`
  - `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
  - `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`
- Strict concurrency no nível do `Package.swift`: não habilitado explicitamente; herda defaults do swift-tools 6.2.

## Plataformas (deployment targets)

App (`Cashly/Cashly.xcodeproj`):
- iOS: **26.0** (`IPHONEOS_DEPLOYMENT_TARGET = 26.0`)
- macOS: **26.0** (`MACOSX_DEPLOYMENT_TARGET = 26.0`)
- visionOS: **26.0** (`XROS_DEPLOYMENT_TARGET = 26.0`)
- `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator"`
- `TARGETED_DEVICE_FAMILY = "1,2,7"` (iPhone, iPad, visionOS)

Pacote (`CashlyKit/Package.swift:9-12`):
- iOS .v26
- macOS .v26
- (sem visionOS declarado; ⚠️ inconsistência leve com o app)

## Build system

- **Workspace**: `Cashly.xcworkspace` (envolve `Cashly.xcodeproj` + `CashlyKit` SPM)
- **App**: `Cashly/Cashly.xcodeproj`
- **Pacote local**: `CashlyKit/` (SPM, multi-target)
- **Dependency manager**: SPM puro. Nenhum Podfile, Cartfile, Tuist, XcodeGen.
- **Schemes compartilhadas (app)**: `Production.xcscheme` (única)

## Bundle e capabilities

- Bundle id: `br.com.rafaelescaleira.Cashly`
- Marketing version: `1.0`
- iCloud container: `iCloud.cashly` (CloudDocuments + CloudKit)
- ubiquity-kvstore-identifier configurado
- Push notifications (APS): `aps-environment = development`
- Background modes: `remote-notification`, `processing`, `fetch`
- ⚠️ `Info.plist` tem `NSUbiquitousContainerName = "NomeDoSeuApp"` — placeholder não preenchido

## Dependências externas

| Lib | Origem | Uso | Onde |
|---|---|---|---|
| **Ryze** | github.com/rafaelesantos/ryze (branch main, revisão `ba1a2cdf`) | Framework arquitetural completo: Foundation utils, UI components, state-management (Store/Reducer/Middleware), Intelligence (CreateML wrapper) | 47 arquivos importam pelo menos um sub-módulo Ryze |

Sub-módulos do Ryze efetivamente importados:
- `RyzeFoundation`: 24 imports
- `RyzeArchitecture`: 13 imports
- `RyzeUI`: 10 imports
- `RyzeIntelligence`: 3 imports

Nenhuma outra dependência externa. Sem swift-collections, swift-algorithms, swift-snapshot-testing.

## UI

- **SwiftUI**: 37 arquivos com `import SwiftUI`
- **UIKit / AppKit**: 0 ocorrências
- **Predominante**: SwiftUI puro, exclusivo

## Concorrência

- `async/await`: 49 arquivos
- `actor`: 27 ocorrências (todos os repositórios `*Actor` em CashlyData e middlewares/reducers em CashlyPresentation)
- `@MainActor`: 9 anotações explícitas (mais o default via build setting)
- `Combine`: 1 ocorrência apenas
- `RxSwift`/Completion handlers `@escaping`: **0**
- **Predominante**: Swift Concurrency nativo (async/await + actors). Padrão consistente.

## Persistência

- **SwiftData**: 23 arquivos com `import SwiftData` ou `@Model`
- **CoreData / Realm / GRDB**: 0
- Stack: `ModelContainer` configurado com schema explícito (Budget, Category, Transaction, User, Tag, Participant) com **CloudKit sync privado** via `cloudKitDatabase: .private("iCloud.cashly")` (`CashlyData/CashlyDataFactory.swift:24-27`)
- Padrão de acesso: `@ModelActor` por entidade (BudgetActor, CategoryActor, etc.)

## Testes

- **Framework**: Swift Testing (`import Testing`, `@Suite`, `#expect`) — 3 arquivos
- **XCTest**: 0
- **Test plan**: `CashlyKit/Tests/CashlyTests/Cashly.xctestplan`
- **Cobertura conhecida**: desconhecida (sem report). Apenas 1 arquivo de teste real (`BudgetActorTests.swift`) + 3 de infra (`CommonScenario`, `CommonTags`, `CommonTestSuite`)

## Toolchain / Qualidade

- **SwiftLint**: ❌ não há `.swiftlint.yml`
- **SwiftFormat / swift-format**: ❌ não há `.swiftformat`
- **EditorConfig**: ❌ não há
- **CI**: ❌ sem `.github/workflows/`, sem GitLab CI, sem `fastlane/`
- **Pre-commit hooks**: ❌ nenhum em `.git/hooks`
- **Localização**: pacote tem `defaultLocalization: "pt-BR"`. Não há String Catalog detectado.
