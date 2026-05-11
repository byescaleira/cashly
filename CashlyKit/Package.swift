// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CashlyKit",
    defaultLocalization: "pt-BR",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "CashlyKit",
            targets: [
                "CashlyDomain",
                "CashlyData",
                "CashlyResource",
                "CashlyDesignSystem",
                "CashlyPresentation",
                "CashlyMock",
                "CashlyUI"
            ]
        ),
        .library(
            name: "CashlyDomain",
            targets: ["CashlyDomain"]
        ),
        .library(
            name: "CashlyData",
            targets: ["CashlyData"]
        ),
        .library(
            name: "CashlyResource",
            targets: ["CashlyResource"]
        ),
        .library(
            name: "CashlyDesignSystem",
            targets: ["CashlyDesignSystem"]
        ),
        .library(
            name: "CashlyPresentation",
            targets: ["CashlyPresentation"]
        ),
        .library(
            name: "CashlyMock",
            targets: ["CashlyMock"]
        ),
        .library(
            name: "CashlyUI",
            targets: ["CashlyUI"]
        )
    ],
    dependencies: [
        .package(path: "../../prism"),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing",
            "1.17.0" ..< "2.0.0"
        )
    ],
    targets: [
        .target(
            name: "CashlyDomain",
            dependencies: [
                .product(name: "PrismFoundation", package: "prism"),
                .product(name: "PrismIntelligence", package: "prism")
            ]
        ),
        .target(
            name: "CashlyData",
            dependencies: [
                "CashlyDomain",
                .product(name: "PrismFoundation", package: "prism"),
                .product(name: "PrismIntelligence", package: "prism")
            ]
        ),
        .target(
            name: "CashlyResource",
            dependencies: [
                .product(name: "PrismFoundation", package: "prism")
            ],
            resources: [
                .copy("Mocks/MockUsers.json"),
                .copy("Mocks/MockCategories.json"),
                .copy("Mocks/MockBudgets.json"),
                .copy("Mocks/MockTransactions.json"),
                .copy("Mocks/MockTags.json"),
                .copy("Mocks/MockParticipants.json"),
                .process("Localizable.xcstrings")
            ]
        ),
        .target(
            name: "CashlyDesignSystem"
        ),
        .target(
            name: "CashlyPresentation",
            dependencies: [
                "CashlyDomain",
                "CashlyData",
                "CashlyResource",
                "CashlyDesignSystem",
                .product(name: "PrismArchitecture", package: "prism"),
                .product(name: "PrismFoundation", package: "prism")
            ]
        ),
        .target(
            name: "CashlyMock",
            dependencies: [
                "CashlyDomain",
                "CashlyData",
                "CashlyPresentation",
                "CashlyDesignSystem",
                "CashlyResource",
                .product(name: "PrismArchitecture", package: "prism")
            ]
        ),
        // CashlyMock is `#if DEBUG`-guarded at every import site in
        // CashlyUI, but SwiftPM lacks a debug-only target dep
        // condition. The edge stays unconditional; the linker
        // dead-codes mock symbols out of Release because no
        // reference survives the preprocessor pass.
        .target(
            name: "CashlyUI",
            dependencies: [
                "CashlyDomain",
                "CashlyData",
                "CashlyPresentation",
                "CashlyMock",
                "CashlyDesignSystem",
                "CashlyResource"
            ]
        ),
        .testTarget(
            name: "CashlyTests",
            dependencies: [
                "CashlyDomain",
                "CashlyData",
                "CashlyPresentation",
                "CashlyUI",
                "CashlyMock",
                .product(name: "PrismArchitecture", package: "prism"),
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing")
            ]
        )
    ]
)
