import CashlyDomain
import FeatureCategories
import Foundation
import Testing

struct BudgetOverviewTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")

    private func item(_ name: String, planned: Double, spent: Double) -> BudgetProgress {
        let category = CashlyDomain.Category(
            id: name, user: owner, name: name, color: "C2602A", icon: "cart.fill")
        let budget = Budget(
            id: name, money: Money(minorUnits: Int64(planned * 100)), category: category,
            month: YearMonth(year: 2026, month: 10) ?? YearMonth(.now), summary: "")
        return BudgetProgress(budget: budget, planned: planned, spent: spent)
    }

    @Test func groupsBySituationWorstFirst() {
        let overview = BudgetOverview(
            items: [
                item("a", planned: 100, spent: 120), item("b", planned: 100, spent: 85),
                item("c", planned: 100, spent: 30), item("d", planned: 100, spent: 0),
                item("e", planned: 100, spent: 150),
            ],
            totalSpent: 500, month: nil)
        #expect(overview.groups.map(\.group) == [.over, .attention, .onTrack, .untouched])
        #expect(overview.groups.first?.items.map(\.id) == ["e", "a"])
        #expect(overview.unbudgeted == 115)
        #expect(overview.remaining == 115)
    }

    @Test func currentMonthHasDailyAllowance() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 11, hour: 12)))
        let october = try #require(YearMonth(year: 2026, month: 10))
        let overview = BudgetOverview(
            items: [item("a", planned: 3100, spent: 1100)], totalSpent: 1100, month: october,
            today: today)
        #expect(overview.daysLeft == 21)
        #expect(abs((overview.dailyAllowance ?? 0) - 2000 / 21) < 0.01)
        let past = BudgetOverview(
            items: overview.items, totalSpent: 1100, month: october.adding(months: -1), today: today
        )
        #expect(past.daysLeft == nil)
        #expect(past.dailyAllowance == nil)
    }
}
