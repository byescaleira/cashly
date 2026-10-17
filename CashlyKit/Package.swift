// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CashlyKit",
    defaultLocalization: "en",
    platforms: [.iOS("27.0"), .macOS("27.0"), .visionOS("27.0")],
    products: [
        .library(
            name: "CashlyWidgetKit",
            targets: ["CashlyDomain", "CashlyDesignSystem", "CashlyWidgetUI"]),
        .library(
            name: "CashlyKit",
            targets: [
                "CashlyDomain", "CashlyData", "FeatureSettings", "FeatureMCP", "AppShell",
                "CashlyMock",
            ]),
        .library(name: "CashlyPreview", targets: ["CashlyPreview"]),
        .executable(name: "CashlyAudit", targets: ["CashlyAudit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.5.0")
    ],
    targets: [
        .target(name: "CashlyDomain"),
        .target(name: "CashlyData", dependencies: ["CashlyDomain"]),
        .target(name: "CashlyExchange", dependencies: ["CashlyDomain"]),
        .target(name: "CashlyAnalytics", dependencies: ["CashlyDomain"]),
        .target(name: "CashlyAnalyticsML", dependencies: ["CashlyDomain", "CashlyAnalytics"]),
        .target(name: "CashlyMCP", dependencies: ["CashlyDomain", "CashlyAnalytics"]),
        .target(name: "CashlyGame", dependencies: ["CashlyDomain", "CashlyAnalytics"]),
        .target(name: "CashlyDesignSystem"),
        .target(name: "CashlyWidgetUI", dependencies: ["CashlyDomain", "CashlyDesignSystem"]),
        .target(name: "CashlyResource", resources: [.process("Assets")]),
        .target(
            name: "FeatureCore",
            dependencies: [
                "CashlyDomain", "CashlyAnalytics", "CashlyAnalyticsML", "CashlyDesignSystem",
                "CashlyResource", .product(name: "Lottie", package: "lottie-spm"),
            ]),
        .target(
            name: "FeatureDashboard",
            dependencies: ["CashlyDomain", "CashlyAnalytics", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureMCP",
            dependencies: [
                "CashlyDomain", "CashlyAnalytics", "CashlyDesignSystem", "CashlyMCP", "FeatureCore",
            ]),
        .target(name: "FeatureStore", dependencies: ["CashlyDomain", "FeatureCore"]),
        .target(
            name: "FeatureJourney",
            dependencies: [
                "CashlyDomain", "CashlyGame", "CashlyDesignSystem", "FeatureCore", "FeatureStore",
            ]),
        .target(
            name: "FeatureGuides",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "CashlyResource", "FeatureCore"]),
        .target(
            name: "FeatureOnboarding",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureTags",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureBudgets",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureCategories",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureConverter",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureTransactions",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "FeatureSettings",
            dependencies: [
                "CashlyDomain", "CashlyDesignSystem", "CashlyGame", "CashlyResource",
                "CashlyWidgetUI",
                "FeatureCore", "FeatureStore",
            ]),
        .target(
            name: "FeatureUsers",
            dependencies: ["CashlyDomain", "CashlyDesignSystem", "FeatureCore"]),
        .target(
            name: "AppShell",
            dependencies: [
                "CashlyDomain", "CashlyData", "CashlyDesignSystem", "CashlyExchange", "FeatureCore",
                "FeatureBudgets",
                "FeatureCategories", "FeatureConverter", "FeatureDashboard", "FeatureGuides",
                "FeatureJourney",
                "FeatureMCP",
                "FeatureOnboarding",
                "FeatureSettings", "FeatureStore",
                "FeatureTags", "FeatureTransactions", "FeatureUsers",
            ]),
        .target(
            name: "CashlyMock", dependencies: ["CashlyDomain", "CashlyData"]),
        .target(
            name: "CashlyPreview",
            dependencies: [
                "AppShell", "CashlyMock", "FeatureBudgets", "FeatureCategories", "FeatureConverter",
                "FeatureCore",
                "FeatureDashboard", "FeatureJourney", "FeatureSettings",
                "FeatureTags",
                "FeatureTransactions", "FeatureUsers",
            ]),
        .executableTarget(
            name: "CashlyAudit", dependencies: ["CashlyDomain", "CashlyData", "CashlyMock"]),
        .testTarget(name: "CashlyDomainTests", dependencies: ["CashlyDomain"]),
        .testTarget(
            name: "CashlyGameTests",
            dependencies: ["CashlyDomain", "CashlyAnalytics", "CashlyGame"]),
        .testTarget(name: "CashlyDataTests", dependencies: ["CashlyDomain", "CashlyData"]),
        .testTarget(
            name: "CashlyExchangeTests", dependencies: ["CashlyDomain", "CashlyExchange"]),
        .testTarget(
            name: "CashlyMCPTests", dependencies: ["CashlyDomain", "CashlyData", "CashlyMCP"]),
        .testTarget(
            name: "CashlyAnalyticsTests",
            dependencies: ["CashlyDomain", "CashlyData", "CashlyAnalytics"]),
        .testTarget(
            name: "CashlyAnalyticsMLTests",
            dependencies: ["CashlyDomain", "CashlyAnalytics", "CashlyAnalyticsML"]),
        .testTarget(
            name: "FeatureBudgetsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureBudgets"]),
        .testTarget(
            name: "FeatureDashboardTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureDashboard"]),
        .testTarget(
            name: "FeatureStoreTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureStore"]),
        .testTarget(
            name: "FeatureJourneyTests",
            dependencies: [
                "CashlyDomain", "CashlyData", "CashlyGame", "FeatureCore", "FeatureJourney",
            ]),
        .testTarget(
            name: "FeatureGuidesTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureGuides"]),
        .testTarget(
            name: "FeatureOnboardingTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureOnboarding"]),
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
            name: "FeatureConverterTests",
            dependencies: ["CashlyDomain", "FeatureCore", "FeatureConverter"]),
        .testTarget(
            name: "FeatureTransactionsTests",
            dependencies: ["CashlyDomain", "CashlyData", "FeatureCore", "FeatureTransactions"]),
        .testTarget(
            name: "FeatureSettingsTests",
            dependencies: [
                "CashlyAnalytics", "CashlyDomain", "CashlyData", "CashlyGame", "CashlyWidgetUI",
                "FeatureCore", "FeatureSettings",
            ]),
        .testTarget(
            name: "FeatureCoreTests",
            dependencies: [
                "CashlyAnalytics", "CashlyDomain", "CashlyData", "CashlyDesignSystem",
                "CashlyResource", "FeatureCore",
            ]),
    ]
)
