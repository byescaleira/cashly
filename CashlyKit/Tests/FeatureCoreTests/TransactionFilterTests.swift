import CashlyDomain
import FeatureCore
import Foundation
import Testing

struct TransactionFilterTests {
    @Test func movesMonthAndYearIndependently() throws {
        var filter = TransactionFilter(
            startDate: try #require(YearMonth(rawValue: 202_603)).startDate)
        filter.monthNumber = 11
        #expect(YearMonth(filter.startDate) == YearMonth(year: 2026, month: 11))
        filter.year = 2024
        #expect(YearMonth(filter.startDate) == YearMonth(year: 2024, month: 11))
        filter.monthNumber = 13
        #expect(YearMonth(filter.startDate) == YearMonth(year: 2024, month: 11))
    }

    @Test func resetKeepsKindsAndClearsTheRest() {
        var filter = TransactionFilter(
            transactionStatuses: [.settled], kinds: [.income], isFilteringByDate: false)
        #expect(filter.isCustomized)
        filter.reset()
        #expect(!filter.isCustomized)
        #expect(filter.kinds == [.income])
        #expect(filter.isFilteringByDate)
    }

    @Test func periodTitleDescribesTheFilter() {
        var filter = TransactionFilter()
        #expect(filter.periodTitle == Date.now.formatted(.dateTime.month(.wide).year()))
        filter.isFilteringByDate = false
        #expect(filter.periodTitle == "All data")
    }
}
