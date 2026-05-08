# Baseline — Snapshot do projeto Cashly em 2026-05-08

> ⚠️ **Imutável.** Este arquivo nunca é editado. É a fotografia do projeto no
> momento em que o Apple Dev Setup config foi adotado. Mudanças desde aqui
> ficam em `migration-log.md` (a ser criado).

## Commit de referência

```
HEAD:   510d6be7139843df99352089235fc99f461a6ac5
Date:   2025-10-01 15:21:48 -0400
Msg:    Add Intelligence
Branch: main
Remote: origin/main
```

(Onboarding rodado em 2026-05-08 com working tree contendo modificações não commitadas.)

## Métricas

| Métrica | Valor |
|---|---|
| Arquivos Swift totais | **122** |
| Linhas de Swift (cat \| wc -l) | **11.201** |
| Arquivos > 500 linhas | **0** |
| Arquivos 300-500 linhas | **3** (AddTransactionScreen 497, CashlySymbolCategory 486, HomeScreen 466) |
| Arquivos 200-299 linhas | **9** |
| Force unwraps em produção (`!`, excluindo `!=`/`!.`/comments) | **~85** ocorrências |
| `try!` | **0** |
| `try?` | (não medido) |
| `print()` em produção | **0** |
| `// TODO` / `// FIXME` / `// HACK` | **0** |
| `fatalError` em produção (encontrados) | **2** (CashlyDataFactory.swift:39, CashlyKey.swift:29) |
| Singletons (`static let shared`) | **2** (`CashlyPresentationFactory.shared`, `MockCashlyFactory.shared`) |
| `actor` declarations | **27** |
| `@MainActor` annotations | **9** |
| `import SwiftUI` | **37** |
| `import UIKit` | **0** |
| `import SwiftData` / `@Model` | **23** arquivos |
| `import Combine` / `AnyPublisher` / `@Published` | **1** |
| `import RxSwift` / `RxCocoa` | **0** |
| `completion: @escaping` | **0** |
| `import XCTest` | **0** |
| `import Testing` (Swift Testing) | **3** |
| `@Observable` | **0** |
| `@StateObject` / `@ObservedObject` | **12** |
| Cobertura de testes | desconhecida (sem report; estimativa: domain 0%, data ~10% (1 actor), presentation 0%, UI 0%) |

## Distribuição por target

| Target | Arquivos Swift |
|---|---|
| CashlyDomain | 26 |
| CashlyData | 8 |
| CashlyPresentation | 32 |
| CashlyUI | 32 |
| CashlyMock | 16 |
| CashlyResource | 2 |
| CashlyTests | 4 |
| App (`Cashly/Cashly/`) | 1 |

## Toolchain

- Swift package: `swift-tools-version: 6.2`
- App target: `SWIFT_VERSION = 5.0`
- Swift Approachable Concurrency: ON
- Default actor isolation (app): `MainActor`
- iOS/macOS/visionOS deployment: 26.0
- Xcode workspace: `Cashly.xcworkspace`

## Dependências externas

- **Ryze** (apenas dependência) — `https://github.com/rafaelesantos/ryze`, branch `main`, revisão `ba1a2cdf5a8dc4ea1e27f0bf1c9074b7ffd2edcf`
  - Sub-módulos importados: RyzeFoundation (24), RyzeArchitecture (13), RyzeUI (10), RyzeIntelligence (3)

## Capabilities

- iCloud `iCloud.cashly` (CloudDocuments + CloudKit private DB)
- aps-environment: development
- Background modes: remote-notification, processing, fetch
- TARGETED_DEVICE_FAMILY: iPhone, iPad, visionOS

## Qualidade / processo

- SwiftLint: ❌
- swift-format / SwiftFormat: ❌
- EditorConfig: ❌
- CI (.github/workflows, GitLab CI, Bitrise, fastlane): ❌
- Pre-commit hooks: ❌
- README.md: praticamente vazio (8 bytes: `# cashly`)

## Outputs raw da discovery

### Topologia (find -maxdepth 4)

```
Cashly/Cashly/Assets.xcassets/{AccentColor.colorset, AppIcon.appiconset}
Cashly/Cashly/CashlyIcon.icon/Assets
CashlyKit/Sources/CashlyDomain/{Entities, Factories, Models, Use Cases, Utils}
CashlyKit/Sources/CashlyData/Actors
CashlyKit/Sources/CashlyPresentation/{Actions, Extensions, Middlewares, Reducers, Route, States, Utils}
CashlyKit/Sources/CashlyUI/{Components, Extensions, Items, Modifier, Screens, Views}
CashlyKit/Sources/CashlyMock/{Actors, Extensions, Models, Views}
CashlyKit/Sources/CashlyResource/{Assets, Mocks}
CashlyKit/Tests/CashlyTests/{Actors, Common}
```

### Counts por sub-pasta

```
32  CashlyKit/Sources/CashlyUI
32  CashlyKit/Sources/CashlyPresentation
26  CashlyKit/Sources/CashlyDomain
16  CashlyKit/Sources/CashlyMock
 8  CashlyKit/Sources/CashlyData
 4  CashlyKit/Tests/CashlyTests
 2  CashlyKit/Sources/CashlyResource
 1  Cashly/Cashly/CashlyApp.swift
```

### Top arquivos por linhas (>200)

```
497  CashlyUI/Screens/AddTransactionScreen.swift
486  CashlyPresentation/Utils/CashlySymbolCategory.swift
466  CashlyUI/Screens/HomeScreen.swift
282  CashlyUI/Screens/TransactionScreen.swift
265  CashlyPresentation/States/MainState.swift
251  CashlyUI/Items/FilterItemView.swift
236  CashlyUI/Screens/AddBudgetScreen.swift
226  CashlyUI/Screens/AddCategoryScreen.swift
215  CashlyUI/Screens/AddTagScreen.swift
215  CashlyPresentation/Middlewares/MainMiddleware.swift
211  CashlyData/Actors/AdapterActor.swift
209  CashlyData/Actors/TransactionActor.swift
```

### Build settings (extraídos de `Cashly.xcodeproj/project.pbxproj`)

```
CURRENT_PROJECT_VERSION = 1
IPHONEOS_DEPLOYMENT_TARGET = 26.0
MACOSX_DEPLOYMENT_TARGET = 26.0
MARKETING_VERSION = 1.0
PRODUCT_BUNDLE_IDENTIFIER = br.com.rafaelescaleira.Cashly
SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator"
SWIFT_VERSION = 5.0
TARGETED_DEVICE_FAMILY = "1,2,7"
XROS_DEPLOYMENT_TARGET = 26.0
SWIFT_APPROACHABLE_CONCURRENCY = YES
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES
```

### Package.resolved

```json
{
  "originHash": "b6289648f74b9a5d6fed9bb8299b43c01618031a375108c504d7006395a6f1e1",
  "pins": [
    {
      "identity": "ryze",
      "kind": "remoteSourceControl",
      "location": "https://github.com/rafaelesantos/ryze",
      "state": {
        "branch": "main",
        "revision": "ba1a2cdf5a8dc4ea1e27f0bf1c9074b7ffd2edcf"
      }
    }
  ],
  "version": 3
}
```

### git history básico

- Total commits: 16
- Authors: Escaleira, Rafael Escaleira, Rafael Santos
- Branches remotas: 1 (origin/main)
- Recent commits (top 5): `Add Intelligence`, `Add AI screen`, `Add app icon`, `Created filter`, `Fix some layout bugs`
