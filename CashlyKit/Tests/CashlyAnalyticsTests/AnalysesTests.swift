import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct AnalysesTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart.fill")
    }

    private func date(_ day: Int, month: Int = 10) -> Date {
        CashlyCalendar.current.date(
            from: DateComponents(year: 2026, month: month, day: day, hour: 12)) ?? .now
    }

    private func transaction(
        _ id: String, _ amount: Int64, day: Int, month: Int = 10, plan: Int? = nil
    ) -> Transaction {
        Transaction(
            id: id, participants: [], category: market, money: Money(minorUnits: amount),
            date: date(day, month: month), summary: id, status: .settled, splitMode: nil,
            splitValue: nil, paymentsPlan: plan)
    }

    private func ledger(
        _ transactions: [Transaction], budget: Int64 = 0, today: Int = 10, month: Int = 10
    ) -> LedgerSnapshot {
        let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)
        let budgets =
            budget > 0
            ? [
                Budget(
                    id: "b", money: Money(minorUnits: budget), category: market, month: october,
                    summary: "")
            ]
            : []
        return LedgerSnapshot(
            transactions: transactions, categories: [market], tags: [], budgets: budgets,
            revision: "r1", today: date(today, month: month))
    }

    @Test func installmentsInTheFutureAreCertainCommitments() throws {
        let result = try #require(
            InstallmentCommitments().run(ledger([transaction("tv", 300_000, day: 5, plan: 3)])))
        #expect(result.metric("total")?.value == 2000)
        #expect(result.metric("nextMonth")?.value == 1000)
        #expect(result.series.count == 2)
        #expect(result.provenance.confidence == .certain)
        #expect(result.provenance.evidence == ["tv"])
    }

    @Test func monthPaceProjectsFromDaysElapsedWithoutHistory() throws {
        let result = try #require(
            MonthPace().run(
                ledger(
                    [transaction("a", 10_000, day: 2), transaction("b", 20_000, day: 9)],
                    budget: 50_000)))
        #expect(result.metric("projected")?.value == 930)
        #expect(result.summary.contains("passa"))
        #expect(result.provenance.confidence == .medium)
    }

    @Test func monthPaceUsesWhatUsuallyLeavesAfterToday() throws {
        let result = try #require(
            MonthPace().run(
                ledger([
                    transaction("aug-early", 10_000, day: 3, month: 8),
                    transaction("aug-late", 40_000, day: 25, month: 8),
                    transaction("sep-early", 12_000, day: 4, month: 9),
                    transaction("sep-late", 20_000, day: 28, month: 9),
                    transaction("oct", 15_000, day: 5),
                ])))
        #expect(result.metric("spent")?.value == 150)
        #expect(result.metric("remaining")?.value == 300)
        #expect(result.metric("projected")?.value == 450)
    }

    @Test func monthPaceExpectsNothingMoreOnTheLastDayOfAShortMonth() throws {
        let result = try #require(
            MonthPace().run(
                ledger(
                    [
                        transaction("jul", 50_000, day: 31, month: 7),
                        transaction("aug", 50_000, day: 31, month: 8),
                        transaction("sep", 50_000, day: 30, month: 9),
                    ], today: 30, month: 9)))
        #expect(result.metric("spent")?.value == 500)
        #expect(result.metric("remaining")?.value == 0)
        #expect(result.metric("projected")?.value == 500)
    }

    @Test func dailyAllowanceSubtractsUpcomingBills() throws {
        let result = try #require(
            DailyAllowance().run(
                ledger(
                    [transaction("a", 20_000, day: 3), transaction("rent", 50_000, day: 20)],
                    budget: 100_000)))
        #expect(result.metric("free")?.value == 300)
        #expect(result.metric("daysLeft")?.value == 22)
        #expect(abs((result.metric("daily")?.value ?? 0) - 13.63) < 0.01)
    }

    @Test func engineCachesByRevisionAndListsTheCatalog() async {
        let engine = AnalysisEngine()
        let snapshot = ledger([transaction("a", 10_000, day: 2)], budget: 50_000)
        let all = await engine.runAll(on: snapshot)
        #expect(Set(all.map(\.id)) == ["month-pace", "daily-allowance"])
        #expect(engine.catalog.count == 5)
        #expect(await engine.run("unknown", on: snapshot) == nil)
    }

    @Test func samePointComparesWithPreviousMonths() throws {
        let result = try #require(
            SamePointComparison().run(
                ledger([
                    transaction("jul", 30_000, day: 5, month: 7),
                    transaction("aug", 50_000, day: 8, month: 8),
                    transaction("aug-late", 90_000, day: 25, month: 8),
                    transaction("sep", 40_000, day: 3, month: 9),
                    transaction("oct", 20_000, day: 4),
                ])))
        #expect(result.metric("average")?.value == 400)
        #expect(result.metric("difference")?.value == -200)
        #expect(result.series.map(\.value) == [300, 500, 400, 200])
    }

    @Test func unusualCategoryNeedsHistoryAndAClearGap() throws {
        let history = (4...9).map { transaction("m\($0)", 10_000, day: 2, month: $0) }
        #expect(
            UnusualCategories().run(ledger(history + [transaction("now", 12_000, day: 3)])) == nil)
        let result = try #require(
            UnusualCategories().run(ledger(history + [transaction("now", 40_000, day: 3)])))
        #expect(result.series.first?.label == "Mercado")
        #expect(result.series.first?.value == 400)
        #expect(result.series.first?.reference == 100)
    }

    @Test func unusualCategoryIgnoresABillPaidEarlierThanUsual() {
        let history = (4...9).map { transaction("rent\($0)", 100_000, day: 5, month: $0) }
        #expect(
            UnusualCategories().run(
                ledger(history + [transaction("now", 100_000, day: 3)], today: 3)) == nil)
    }
}
