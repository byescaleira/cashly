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
        .ryze
    ],
    targets: [
        .domain,
        .data,
        .presentation,
        .mock,
        .ui,
        .resource,
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
        case .domain: return [.ryze]
        case .data: return [.domain, .ryze]
        case .presentation: return [.domain, .data, .ryze]
        case .ui: return [.domain, .presentation, .mock, .ryze, .resource]
        case .resource: return [.ryze]
        case .mock: return [.domain, .data, .presentation, .ryze, .resource]
        case .tests: return [.domain, .data, .presentation, .ui, .mock, .ryze]
        }
    }
    
    var targets: [CashlyTarget] {
        switch self {
        case .domain: return []
        case .data: return [.domain]
        case .presentation: return [.domain, .data]
        case .ui: return [.domain, .presentation, .mock]
        case .resource: return []
        case .mock: return [.domain, .data, .presentation]
        case .tests: return [.domain, .data, .presentation, .ui]
        }
    }
}

enum CashlyDependency: String, CaseIterable {
    case ryze = "ryze"
    
    var url: String {
        switch self {
        case .ryze: return "https://github.com/rafaelesantos/ryze"
        }
    }
    
    var revision: String {
        switch self {
        case .ryze: return "2b619d8e98f00174719dcab07d5fad08b23ff2dd"
        }
    }

    var dependency: Package.Dependency {
        switch self {
        case .ryze: return .package(url: url, revision: revision)
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
    static var tests: Target { CashlyTarget.tests.testTarget }
}

extension Target.Dependency {
    static var domain: Self { CashlyTarget.domain.dependency }
    static var data: Self { CashlyTarget.data.dependency }
    static var presentation: Self { CashlyTarget.presentation.dependency }
    static var mock: Self { CashlyTarget.mock.dependency }
    static var ui: Self { CashlyTarget.ui.dependency }
    static var resource: Self { CashlyTarget.resource.dependency }
    static var ryze: Self { .product(name: "Ryze", package: "ryze") }
}

extension Package.Dependency {
    static var ryze: Package.Dependency { CashlyDependency.ryze.dependency }
}

extension Array where Element == String {
    static var targets: [String] {
        cashlyTargets.compactMap(\.rawValue)
    }
    
    static var cashlyTargets: [CashlyTarget] {
        [.domain, .data, .presentation, .ui, .mock, .resource]
    }
}
