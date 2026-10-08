import CashlyDomain
import Foundation
import Testing

struct YearMonthTests {
    @Test(arguments: [(2026, 0), (2026, 13), (0, 5), (-1, 1)])
    func rejectsInvalidValues(year: Int, month: Int) {
        #expect(YearMonth(year: year, month: month) == nil)
    }

    @Test func roundTripsRawValue() throws {
        let value = try #require(YearMonth(rawValue: 202_612))
        #expect(value.year == 2026)
        #expect(value.month == 12)
        #expect(value.rawValue == 202_612)
        #expect(YearMonth(rawValue: 202_613) == nil)
    }

    @Test func roundTripsMonthIndex() throws {
        let value = try #require(YearMonth(year: 2026, month: 3))
        #expect(YearMonth(monthIndex: value.monthIndex) == value)
    }

    @Test func addsMonthsAcrossYears() throws {
        let november = try #require(YearMonth(year: 2026, month: 11))
        #expect(november.adding(months: 2) == YearMonth(year: 2027, month: 1))
        #expect(november.adding(months: -11) == YearMonth(year: 2025, month: 12))
    }

    @Test func countsMonthsBetweenValues() throws {
        let start = try #require(YearMonth(year: 2025, month: 11))
        let end = try #require(YearMonth(year: 2026, month: 2))
        #expect(end.months(since: start) == 3)
        #expect(start.months(since: end) == -3)
        #expect(start < end)
    }

    @Test func convertsFromAndToDates() throws {
        let value = try #require(YearMonth(year: 2026, month: 2))
        #expect(YearMonth(value.startDate) == value)
        #expect(value.dayCount == 28)
        #expect(try #require(YearMonth(year: 2028, month: 2)).dayCount == 29)
    }
}
