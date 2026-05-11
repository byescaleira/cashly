// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CashlyKit",
    defaultLocalization: "pt-BR",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .kit,
        .data,
        .presentation,
        .ui
    ],
    dependencies: [
        .prism,
        .snapshotTesting
    ],
    targets: [
        .domain,
        .data,
        .presentation,
        .mock,
        .ui,
        .resource,
        .designSystem,
        .tests
    ]
)

enum CashlyTarget: String, CaseIterable {
    case domain = "CashlyDomain"
    case data = "CashlyData"
    case presentation = "CashlyPresentation"
    case ui = "CashlyUI"
    case resource = "CashlyResource"
    case mock = "CashlyMock"
    case designSystem = "CashlyDesignSystem"
    case tests = "CashlyTests"
    
    var target: Target {
        switch self {
        case .resource:
            return .target(
                name: rawValue,
                dependencies: dependencies,
                resources: [
                    .copy("Mocks/MockUsers.json"),
                    .copy("Mocks/MockCategories.json"),
                    .copy("Mocks/MockBudgets.json"),
                    .copy("Mocks/MockTransactions.json"),
                    .copy("Mocks/MockTags.json"),
                    .copy("Mocks/MockParticipants.json"),
                    .process("Localizable.xcstrings")
                ]
            )
        default:
            return .target(
                name: rawValue,
                dependencies: dependencies
            )
        }
    }
    
    var product: Product {
        .library(
            name: rawValue,
            targets: targets.map(\.rawValue)
        )
    }
    
    var testTarget: Target {
        .testTarget(
            name: rawValue,
            dependencies: dependencies
        )
    }
    
    var dependency: Target.Dependency {
        .init(stringLiteral: rawValue)
    }
    
    var dependencies: [Target.Dependency] {
        switch self {
        case .domain: return [.prismFoundation, .prismIntelligence]
        case .data: return [.domain, .prismFoundation, .prismIntelligence]
        case .presentation: return [.domain, .data, .resource, .designSystem, .prismArchitecture, .prismFoundation, .prismIntelligence]
        case .ui: return [.domain, .data, .presentation, .mock, .designSystem, .prismUI, .prismArchitecture, .resource]
        case .resource: return [.prismFoundation]
        case .mock: return [.domain, .data, .presentation, .designSystem, .prismArchitecture, .resource]
        case .designSystem: return [.resource, .prismUI, .prismArchitecture]
        case .tests: return [.domain, .data, .presentation, .ui, .mock, .prismArchitecture, .snapshotTesting]
        }
    }

    var targets: [CashlyTarget] {
        switch self {
        case .domain: return []
        case .data: return [.domain]
        case .presentation: return [.domain, .data, .designSystem]
        case .ui: return [.domain, .data, .presentation, .mock, .designSystem]
        case .resource: return []
        case .mock: return [.domain, .data, .presentation, .designSystem]
        case .designSystem: return []
        case .tests: return [.domain, .data, .presentation, .ui]
        }
    }
}

enum CashlyDependency: String, CaseIterable {
    case prism = "prism"
    case snapshotTesting = "swift-snapshot-testing"

    var url: String {
        switch self {
        case .prism: return "../../prism"
        case .snapshotTesting: return "https://github.com/pointfreeco/swift-snapshot-testing"
        }
    }

    var range: Range<Version>? {
        switch self {
        case .prism: return nil
        case .snapshotTesting: return "1.17.0" ..< "2.0.0"
        }
    }

    var dependency: Package.Dependency {
        switch self {
        case .prism:
            return .package(path: url)
        case .snapshotTesting:
            return .package(url: url, range!)
        }
    }
}

extension Product {
    static var kit: Product {
        .library(
            name: "CashlyKit",
            targets: .targets
        )
    }
    
    static var data: Product { CashlyTarget.data.product }
    static var presentation: Product { CashlyTarget.presentation.product }
    static var ui: Product { CashlyTarget.ui.product }
}

extension Target {
    static var domain: Target { CashlyTarget.domain.target }
    static var data: Target { CashlyTarget.data.target }
    static var presentation: Target { CashlyTarget.presentation.target }
    static var mock: Target { CashlyTarget.mock.target }
    static var ui: Target { CashlyTarget.ui.target }
    static var resource: Target { CashlyTarget.resource.target }
    static var designSystem: Target { CashlyTarget.designSystem.target }
    static var tests: Target { CashlyTarget.tests.testTarget }
}

extension Target.Dependency {
    static var domain: Self { CashlyTarget.domain.dependency }
    static var data: Self { CashlyTarget.data.dependency }
    static var presentation: Self { CashlyTarget.presentation.dependency }
    static var mock: Self { CashlyTarget.mock.dependency }
    static var ui: Self { CashlyTarget.ui.dependency }
    static var resource: Self { CashlyTarget.resource.dependency }
    static var designSystem: Self { CashlyTarget.designSystem.dependency }
    static var prismFoundation: Self { .product(name: "PrismFoundation", package: "prism") }
    static var prismArchitecture: Self { .product(name: "PrismArchitecture", package: "prism") }
    static var prismUI: Self { .product(name: "PrismUI", package: "prism") }
    static var prismIntelligence: Self { .product(name: "PrismIntelligence", package: "prism") }
    static var snapshotTesting: Self { .product(name: "SnapshotTesting", package: "swift-snapshot-testing") }
}

extension Package.Dependency {
    static var prism: Package.Dependency { CashlyDependency.prism.dependency }
    static var snapshotTesting: Package.Dependency { CashlyDependency.snapshotTesting.dependency }
}

extension Array where Element == String {
    static var targets: [String] {
        cashlyTargets.compactMap(\.rawValue)
    }
    
    static var cashlyTargets: [CashlyTarget] {
        [.domain, .data, .presentation, .ui, .mock, .resource, .designSystem]
    }
}
