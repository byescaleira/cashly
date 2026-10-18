import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct SpendingAnalysesTests {
    private let owner = User(id: "owner", name: "Ana")
    private var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart")
    }
    private let calendar = CashlyCalendar.current

    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12)) ?? .now
    }

    private func date(month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)) ?? .now
    }

    private func daysAgo(_ days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: today) ?? today
    }

    private func purchase(
        _ id: String, _ cents: Int64, on date: Date, summary: String = "Compra", plan: Int? = nil
    ) -> Transaction {
        Transaction(
            id: id, participants: [], category: market, money: Money(minorUnits: cents),
            date: date, summary: summary, status: .settled, splitMode: nil, splitValue: nil,
            paymentsPlan: plan)
    }

    private func ledger(_ transactions: [Transaction]) -> LedgerSnapshot {
        LedgerSnapshot(
            transactions: transactions, categories: [market], tags: [], budgets: [],
            revision: "r1", today: today)
    }

    private func history(_ cents: Int64 = 5_000, perMonth: Int = 2) -> [Transaction] {
        (4...9).flatMap { month in
            (0..<perMonth).map {
                purchase("h\(month)-\($0)", cents, on: date(month: month, day: 2))
            }
        }
    }

    @Test func driversSplitAChangeIntoFrequency() throws {
        let current = (0..<6).map { purchase("c\($0)", 5_000, on: date(month: 10, day: 3)) }
        let result = try #require(SpendingDrivers().run(ledger(history() + current)))
        let finding = try #require(result.findings.first)
        #expect(finding.impact == 20_000)
        #expect(finding.metric("count")?.value == 6)
        #expect(finding.metric("typicalCount")?.value == 2)
        #expect(finding.metric("frequency")?.value == 200)
        #expect(finding.metric("ticketEffect")?.value == 0)
    }

    @Test func driversSplitAChangeIntoTicket() throws {
        let current = (0..<2).map { purchase("c\($0)", 15_000, on: date(month: 10, day: 3)) }
        let finding = try #require(
            SpendingDrivers().run(ledger(history() + current))?.findings.first)
        #expect(finding.metric("frequency")?.value == 0)
        #expect(finding.metric("ticketEffect")?.value == 200)
    }

    @Test func driversIgnoreSmallChanges() {
        let current = (0..<2).map { purchase("c\($0)", 5_500, on: date(month: 10, day: 3)) }
        #expect(SpendingDrivers().run(ledger(history() + current)) == nil)
    }

    @Test func merchantsGroupNormalizedDescriptions() throws {
        let rides =
            (0..<3).map { purchase("u\($0)", 2_000, on: daysAgo($0 * 10), summary: "Uber *Trip") }
            + [purchase("u9", 2_000, on: daysAgo(40), summary: "UBER TRIP")]
        let once = purchase("tv", 300_000, on: daysAgo(5), summary: "Televisão")
        let result = try #require(TopMerchants().run(ledger(rides + [once])))
        let first = try #require(result.findings.first)
        #expect(result.findings.count == 1)
        #expect(first.subject == "uber trip")
        #expect(first.label == "Uber *Trip")
        #expect(first.metric("count")?.value == 4)
        #expect(
            first.metric("monthly")?.value == Double(Int64((8_000.0 * 30 / 41).rounded())) / 100)
    }

    @Test func smallPurchasesUseTheUsualAmount() throws {
        let past = [8, 9].flatMap { month in
            (0..<5).map { purchase("s\(month)-\($0)", 1_000, on: date(month: month, day: 5)) }
                + (0..<5).map { purchase("b\(month)-\($0)", 9_000, on: date(month: month, day: 6)) }
        }
        let now =
            (3...5).map { purchase("n\($0)", 1_000, on: date(month: 10, day: $0)) }
            + [purchase("big", 9_000, on: date(month: 10, day: 6))]
        let result = try #require(SmallPurchases().run(ledger(past + now)))
        #expect(result.metric("threshold")?.value == 10)
        #expect(result.metric("count")?.value == 3)
        #expect(result.metric("total")?.value == 30)
        #expect(result.metric("yearly")?.value == 600)
    }

    @Test func niceFloorRoundsDownToFriendlyAmounts() {
        #expect(SmallPurchases.niceFloor(4_230) == 3_000)
        #expect(SmallPurchases.niceFloor(999) == 500)
        #expect(SmallPurchases.niceFloor(100) == 100)
        #expect(SmallPurchases.niceFloor(0) == 0)
    }

    @Test func weekdayPatternFindsTheBiggestDay() throws {
        let daily = (0..<91).map { purchase("d\($0)", 500, on: daysAgo($0)) }
        let saturdays = (0..<91).compactMap { offset -> Transaction? in
            let day = daysAgo(offset)
            return calendar.component(.weekday, from: day) == 7
                ? purchase("s\(offset)", 10_000, on: day) : nil
        }
        let result = try #require(WeekdayPattern().run(ledger(daily + saturdays)))
        #expect(result.metric("weekday")?.value == 7)
        #expect(result.series.count == 7)
        #expect(result.findings.first?.subject == "weekday-7")
    }

    @Test func driversRoundAnEvenMedianOfCharges() throws {
        let past = (6...9).flatMap { month in
            (0..<(month < 8 ? 1 : 2)).map {
                purchase("h\(month)-\($0)", 10_000, on: date(month: month, day: 2))
            }
        }
        let current = (0..<2).map { purchase("c\($0)", 10_500, on: date(month: 10, day: 3)) }
        let finding = try #require(
            SpendingDrivers().run(ledger(past + current))?.findings.first)
        #expect(finding.metric("typicalCount")?.value == 2)
        #expect(finding.metric("typicalTicket")?.value == 100)
        #expect(finding.metric("frequency")?.value == 0)
        #expect(finding.metric("ticketEffect")?.value == 60)
    }

    @Test func driversReportACategoryThatDropped() throws {
        let finding = try #require(SpendingDrivers().run(ledger(history()))?.findings.first)
        #expect(finding.impact == -10_000)
        #expect(finding.metric("frequency")?.value == -100)
    }

    @Test func merchantsLeaveInstallmentsOutAndNeedAMonth() {
        let plans = (0..<3).map {
            purchase("p\($0)", 90_000, on: daysAgo($0 * 20), summary: "Loja", plan: 3)
        }
        #expect(TopMerchants().run(ledger(plans)) == nil)
        let recent = (0..<3).map { purchase("r\($0)", 2_000, on: daysAgo($0), summary: "Café") }
        #expect(TopMerchants().run(ledger(recent)) == nil)
    }

    @Test func smallPurchasesProjectTheMonthWithoutHistory() throws {
        let now =
            (1...17).map { purchase("n\($0)", 1_000, on: date(month: 10, day: $0)) }
            + (1...6).map { purchase("b\($0)", 9_000, on: date(month: 10, day: $0)) }
        let result = try #require(SmallPurchases().run(ledger(now)))
        #expect(result.metric("count")?.value == 17)
        #expect(
            result.metric("monthly")?.value == Double(Int64((17_000.0 * 31 / 20).rounded())) / 100)
    }

    @Test func weekdayPatternWithoutABigDayHasNoFinding() throws {
        let daily = (0..<91).map { purchase("d\($0)", 500, on: daysAgo($0)) }
        let result = try #require(WeekdayPattern().run(ledger(daily)))
        #expect(result.findings.isEmpty)
        #expect(WeekdayPattern().run(ledger(Array(daily.prefix(20)))) == nil)
    }
}
