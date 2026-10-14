import CashlyDomain
import FeatureCore
import Foundation
import Testing

struct MonthCalendarTests {
    private let english = Locale(identifier: "en_US")

    private func month(_ raw: Int) throws -> YearMonth {
        try #require(YearMonth(rawValue: raw))
    }

    private func calendar(
        year: Int = 2026, selection: Int = 202_610, unavailable: Set<YearMonth> = []
    ) throws -> MonthCalendar {
        MonthCalendar(
            year: year, selection: try month(selection), today: try month(202_610),
            unavailable: unavailable, unavailableTitle: "Already has a budget", locale: english)
    }

    @Test func choicesCoverTheYearAndMarkSelectionAndToday() throws {
        let choices = try calendar(selection: 202_612).choices
        #expect(choices.count == 12)
        #expect(choices.map(\.title).first == "Jan")
        #expect(choices.filter(\.isSelected).map(\.month) == [try month(202_612)])
        #expect(choices.filter { $0.time == .current }.map(\.month) == [try month(202_610)])
        #expect(choices.prefix(9).allSatisfy { $0.time == .past })
        #expect(choices.suffix(2).allSatisfy { $0.time == .future })
        #expect(choices[9].fullTitle == "October 2026")
        #expect(choices[9].detail == "Current month")
    }

    @Test func unavailableMonthsAreDisabledAndDescribed() throws {
        let taken = try month(202_610)
        let calendar = try calendar(unavailable: [taken])
        let october = try #require(calendar.choices.first { $0.month == taken })
        #expect(!october.isAvailable)
        #expect(october.detail == "Current month and Already has a budget")
        #expect(calendar.choices.filter(\.isAvailable).count == 11)
        #expect(!calendar.canJumpToToday)
    }

    @Test func titlesDescribeTheSelection() throws {
        #expect(try calendar().selectionTitle == "October 2026")
        #expect(try calendar().relativeTitle == "This month")
        #expect(try calendar(selection: 202_611).relativeTitle == "Next month")
        #expect(try calendar(selection: 202_701).relativeTitle == "In 3 months")
        #expect(try calendar(selection: 202_608).relativeTitle == "2 months ago")
    }

    @Test func movingYearsKeepsTheSelection() throws {
        let next = try calendar().moving(by: 1)
        #expect(next.year == 2027)
        #expect(next.yearTitle == "2027")
        #expect(next.selection == (try month(202_610)))
        #expect(next.choices.allSatisfy { !$0.isSelected && $0.time == .future })
        #expect(next.canJumpToToday)
        #expect(!(try calendar().canJumpToToday))
    }

    @Test func columnsAdaptToTextSizeAndWidth() {
        #expect(MonthCalendar.columns(isAccessibilitySize: false, isWide: false) == 4)
        #expect(MonthCalendar.columns(isAccessibilitySize: false, isWide: true) == 6)
        #expect(MonthCalendar.columns(isAccessibilitySize: true, isWide: true) == 3)
    }
}
