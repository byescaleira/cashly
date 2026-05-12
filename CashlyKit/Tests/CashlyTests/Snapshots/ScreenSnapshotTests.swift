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
}
#endif
