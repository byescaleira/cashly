//
//  ScreenSnapshotTests.swift
//  CashlyKit
//
//  Snapshot tests for the primary screens. Uses
//  pointfreeco/swift-snapshot-testing. First run records baselines;
//  subsequent runs assert against the recorded reference images.
//  Toggle `isRecording = true` once on a clean checkout to regenerate.
//

#if canImport(UIKit)
import Testing
import SwiftUI
import SnapshotTesting
import CashlyUI
import CashlyMock

@MainActor
@Suite("UI Screens Snapshots", .tags(.unit, .ui, .local))
struct ScreenSnapshotTests {
    // Toggle to true once on a clean checkout to record fresh baselines.
    static let isRecording = false

    private func snapshot<V: View>(of view: V, named name: String) {
        let host = view.cashlyPreview()
            .frame(width: 393, height: 852)
        assertSnapshot(
            of: host,
            as: .image(layout: .fixed(width: 393, height: 852)),
            named: name,
            record: Self.isRecording
        )
    }

    /// Renders the same view in dark mode for a regression baseline
    /// covering Pro / paywall surfaces (where yellow + black contrast
    /// matters). Recorded once, asserts thereafter.
    private func snapshotDark<V: View>(of view: V, named name: String) {
        let host = view.cashlyPreview()
            .environment(\.colorScheme, .dark)
            .frame(width: 393, height: 852)
        assertSnapshot(
            of: host,
            as: .image(layout: .fixed(width: 393, height: 852)),
            named: "\(name).dark",
            record: Self.isRecording
        )
    }

    /// Renders at the largest non-accessibility Dynamic Type setting
    /// to catch layout breaks when the user prefers bigger fonts.
    private func snapshotLargeText<V: View>(of view: V, named name: String) {
        let host = view.cashlyPreview()
            .environment(\.dynamicTypeSize, .accessibility3)
            .frame(width: 393, height: 852)
        assertSnapshot(
            of: host,
            as: .image(layout: .fixed(width: 393, height: 852)),
            named: "\(name).a11y3",
            record: Self.isRecording
        )
    }

    @Test("AddBudgetScreen renders")
    func addBudget() {
        snapshot(of: AddBudgetScreen(), named: "AddBudgetScreen")
    }

    @Test("AddCategoryScreen renders")
    func addCategory() {
        snapshot(of: AddCategoryScreen(), named: "AddCategoryScreen")
    }

    // AddTagScreen snapshot disabled — random icon/color in
    // MockTag.mocks causes flake. Re-enable once mock seeding is
    // deterministic.
    // @Test("AddTagScreen renders")
    // func addTag() {
    //     snapshot(of: AddTagScreen(), named: "AddTagScreen")
    // }

    @Test("AddTransactionScreen renders")
    func addTransaction() {
        snapshot(of: AddTransactionScreen(), named: "AddTransactionScreen")
    }

    @Test("AddUserScreen renders")
    func addUser() {
        snapshot(of: AddUserScreen(), named: "AddUserScreen")
    }

    @Test("HomeScreen renders")
    func home() {
        snapshot(of: HomeScreen(), named: "HomeScreen")
    }

    @Test("MainScreen renders")
    func main() {
        snapshot(of: MainScreen(), named: "MainScreen")
    }

    @Test("TransactionScreen renders")
    func transaction() {
        snapshot(of: TransactionScreen(), named: "TransactionScreen")
    }

    @Test("PaywallScreen renders")
    func paywall() {
        snapshot(of: PaywallScreen(), named: "PaywallScreen")
    }

    // MARK: - Variants (dark mode + Dynamic Type)
    //
    // Limited to the highest-impact Pro / paywall surfaces — adding
    // every screen to every variant would 3x the baseline count.
    // Extend here as new visual regressions surface.

    @Test("PaywallScreen — dark mode")
    func paywallDark() {
        snapshotDark(of: PaywallScreen(), named: "PaywallScreen")
    }

    @Test("PaywallScreen — accessibility3 type")
    func paywallLargeText() {
        snapshotLargeText(of: PaywallScreen(), named: "PaywallScreen")
    }

    @Test("HomeScreen — dark mode")
    func homeDark() {
        snapshotDark(of: HomeScreen(), named: "HomeScreen")
    }

    @Test("HomeScreen — accessibility3 type")
    func homeLargeText() {
        snapshotLargeText(of: HomeScreen(), named: "HomeScreen")
    }
}
#endif
