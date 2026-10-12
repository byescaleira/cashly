import CashlyDomain
import Foundation
import Testing

struct WidgetSnapshotTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")

    @Test func snapshotSummarizesTheOverview() throws {
        let month = try #require(YearMonth(year: 2026, month: 10))
        let category = CashlyDomain.Category(
            id: "food", user: owner, name: "Mercado", color: "5F7A2E", icon: "cart")
        let budget = Budget(
            id: "b1", money: Money(minorUnits: 50_000), category: category, month: month,
            summary: "", isConflicted: false)
        var overview = CashlyOverview()
        overview.budgets = [budget]
        overview.budgetsTotal = Money(minorUnits: 50_000)
        overview.budgetExpenses = ["b1": Money(minorUnits: 12_000)]
        overview.expensesTotal = Money(minorUnits: 15_000)
        overview.incomeTotal = Money(minorUnits: 300_000)
        let snapshot = WidgetSnapshot(
            user: owner, month: month, overview: overview, currencyCode: "BRL")
        #expect(snapshot.yearMonth == month)
        #expect(snapshot.availableMinorUnits == 35_000)
        #expect(snapshot.budgets.first?.categoryName == "Mercado")
        #expect(snapshot.budgets.first?.remainingMinorUnits == 38_000)
    }

    @Test func storeRoundTripsAndClears() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "cashly-snapshot-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let store = WidgetSnapshotStore(directory: directory)
        #expect(try store.read() == nil)
        let month = try #require(YearMonth(year: 2026, month: 1))
        let snapshot = WidgetSnapshot(
            userID: owner.id, userName: owner.name, month: month, currencyCode: "BRL",
            plannedMinorUnits: 100, spentMinorUnits: 40, incomeMinorUnits: 0, budgets: [],
            generatedAt: Date(timeIntervalSince1970: 1_800_000_000))
        try store.write(snapshot)
        #expect(try store.read() == snapshot)
        try store.clear()
        #expect(try store.read() == nil)
    }
}
