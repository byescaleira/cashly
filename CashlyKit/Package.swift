// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CashlyKit",
    defaultLocalization: "pt-BR",
    platforms: [.iOS("27.0"), .macOS("27.0"), .visionOS("27.0")],
    products: [
        .library(
            name: "CashlyKit",
            targets: ["CashlyDomain", "CashlyData", "CashlyPresentation", "CashlyUI"]),
        .library(name: "CashlyData", targets: ["CashlyData"]),
        .library(name: "CashlyPresentation", targets: ["CashlyPresentation"]),
        .library(name: "CashlyUI", targets: ["CashlyUI"]),
        .executable(name: "CashlyAudit", targets: ["CashlyAudit"]),
        .library(name: "CashlyPreview", targets: ["CashlyPreview"]),
    ],
    targets: [
        .executableTarget(
            name: "CashlyAudit",
            dependencies: ["CashlyDomain", "CashlyData", "CashlyPresentation", "CashlyMock"]),
        .target(name: "CashlyDomain"),
        .target(name: "CashlyData", dependencies: ["CashlyDomain"]),
        .target(name: "FeatureCore", dependencies: ["CashlyDomain", "CashlyDesignSystem"]),
        .target(
            name: "CashlyPresentation",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(name: "CashlyDesignSystem"),
        .target(name: "CashlyResource", resources: [.process("Assets")]),
        .target(
            name: "CashlyMock",
            dependencies: ["CashlyDomain", "CashlyData", "CashlyPresentation"]),
        .target(name: "CashlyPreview", dependencies: ["CashlyUI", "CashlyMock"]),
        .target(
            name: "CashlyUI",
            dependencies: [
                "CashlyDomain", "CashlyPresentation", "CashlyResource", "CashlyDesignSystem",
                "FeatureCore",
            ]),
        .testTarget(name: "CashlyDomainTests", dependencies: ["CashlyDomain"]),
    ]
)
