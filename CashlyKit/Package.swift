// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CashlyKit",
    defaultLocalization: "pt-BR",
    platforms: [.iOS("27.0"), .macOS("27.0"), .visionOS("27.0")],
    products: [
        .library(
            name: "CashlyKit",
            targets: ["CashlyDomain", "CashlyData", "FeatureSettings", "AppShell"]),
        .library(name: "CashlyPreview", targets: ["CashlyPreview"]),
        .executable(name: "CashlyAudit", targets: ["CashlyAudit"]),
    ],
    targets: [
        .target(name: "CashlyDomain"),
        .target(name: "CashlyData", dependencies: ["CashlyDomain"]),
        .target(name: "CashlyDesignSystem"),
        .target(name: "CashlyResource", resources: [.process("Assets")]),
        .target(
            name: "FeatureCore",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "CashlyResource"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureDashboard",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureIntelligence",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureTags",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureBudgets",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureCategories",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureTransactions",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "CashlyResource", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureSettings", dependencies: ["CashlyDomain"],
            resources: [.process("Resources")]),
        .target(
            name: "FeatureUsers",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "CashlyResource", "FeatureCore"],
            resources: [.process("Resources")]),
        .target(
            name: "AppShell",
            dependencies: [
                "CashlyDomain", "CashlyDesignSystem", "FeatureCore", "FeatureBudgets",
                "FeatureCategories", "FeatureDashboard", "FeatureIntelligence", "FeatureSettings",
                "FeatureTags", "FeatureTransactions", "FeatureUsers",
            ]),
        .target(
            name: "CashlyMock", dependencies: ["CashlyDomain", "CashlyData"]),
        .target(
            name: "CashlyPreview",
            dependencies: [
                "AppShell", "CashlyMock", "FeatureBudgets", "FeatureCategories", "FeatureCore",
                "FeatureDashboard", "FeatureIntelligence", "FeatureSettings", "FeatureTags",
                "FeatureTransactions", "FeatureUsers",
            ]),
        .executableTarget(
            name: "CashlyAudit", dependencies: ["CashlyDomain", "CashlyData", "CashlyMock"]),
        .testTarget(name: "CashlyDomainTests", dependencies: ["CashlyDomain"]),
        .testTarget(name: "CashlyDataTests", dependencies: ["CashlyDomain", "CashlyData"]),
        .testTarget(
            name: "FeatureBudgetsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureBudgets"]),
        .testTarget(
            name: "FeatureDashboardTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureDashboard"]),
        .testTarget(
            name: "FeatureIntelligenceTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureIntelligence"]),
        .testTarget(
            name: "FeatureCategoriesTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureCategories"]),
        .testTarget(
            name: "FeatureUsersTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureUsers"]),
        .testTarget(
            name: "FeatureTagsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureTags"]),
        .testTarget(
            name: "FeatureTransactionsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureTransactions"]),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureSettings"]),
        .testTarget(
            name: "FeatureCoreTests", dependencies: ["CashlyDomain", "CashlyData", "FeatureCore"]),
    ]
)
