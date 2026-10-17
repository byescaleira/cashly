import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct SavingAnalysesTests {
    private let owner = User(id: "owner", name: "Ana")
    private var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart")
    }
    private var fun: CashlyDomain.Category {
        CashlyDomain.Category(id: "fun", user: owner, name: "Lazer", color: "3D5F86", icon: "star")
    }
    private let calendar = CashlyCalendar.current
    private let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)

    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12)) ?? .now
    }

    private func date(month: Int, day: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12)) ?? .now
    }

    private func charge(
        _ id: String, _ cents: Int64, on date: Date, summary: String = "Compra",
        category: CashlyDomain.Category? = nil, plan: Int? = nil
    ) -> Transaction {
        Transaction(
            id: id, participants: [], category: category ?? market,
            money: Money(minorUnits: cents), date: date, summary: summary, status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: plan)
    }

    private func ledger(
        _ transactions: [Transaction], budgets: [Budget] = [], today: Date? = nil
    ) -> LedgerSnapshot {
        LedgerSnapshot(
            transactions: transactions, categories: [market, fun], tags: [], budgets: budgets,
            revision: "r1", today: today ?? self.today)
    }

    @Test func recurringChargesFindMonthlySubscriptions() throws {
        let netflix = (6...10).map {
            charge(
                "n\($0)", $0 == 9 ? 4_290 : 3_990, on: date(month: $0, day: 5),
                summary: "NETFLIX.COM")
        }
        let rides = (0..<12).map {
            charge("u\($0)", 2_000, on: date(month: 7 + $0 % 4, day: 1 + $0), summary: "Uber")
        }
        let result = try #require(RecurringCharges().run(ledger(netflix + rides)))
        #expect(result.findings.map(\.subject) == ["netflix com"])
        let finding = try #require(result.findings.first)
        #expect(finding.metric("monthly")?.value == 39.9)
        #expect(finding.metric("yearly")?.value == 478.8)
        #expect(finding.recommendation?.action == .review)
    }

    @Test func recurringChargesIgnoreStoppedOrVaryingCharges() {
        let stopped = (6...8).map {
            charge("s\($0)", 3_990, on: date(month: $0, day: 5), summary: "Gym")
        }
        let varying = zip(7...9, [10_000, 20_000, 30_000]).map {
            charge("v\($0)", Int64($1), on: date(month: $0, day: 5), summary: "Luz")
        }
        #expect(RecurringCharges().run(ledger(stopped + varying)) == nil)
    }

    @Test func suggestedBudgetsSkipCategoriesWithABudget() throws {
        let history = (4...9).flatMap { month in
            [
                charge("m\(month)", 41_234, on: date(month: month, day: 3)),
                charge("f\(month)", 12_000, on: date(month: month, day: 4), category: fun),
            ]
        }
        let budget = Budget(
            id: "b", money: Money(minorUnits: 50_000), category: market, month: october,
            summary: "")
        let result = try #require(SuggestedBudgets().run(ledger(history, budgets: [budget])))
        #expect(result.findings.map(\.subject) == ["fun"])
        #expect(result.findings.first?.metric("suggested")?.value == 120)
        let unbudgeted = try #require(SuggestedBudgets().run(ledger(history)))
        #expect(unbudgeted.findings.first?.metric("suggested")?.value == 420)
    }

    @Test func endingInstallmentsFreeTheMonthAfterTheLastOne() throws {
        let phone = charge("phone", 300_000, on: date(month: 9, day: 10), plan: 3)
        let sofa = charge("sofa", 1_200_000, on: date(month: 9, day: 10), plan: 12)
        let result = try #require(EndingInstallments().run(ledger([phone, sofa])))
        let finding = try #require(result.findings.first)
        #expect(result.findings.count == 1)
        #expect(finding.metric("month")?.value == 202_612)
        #expect(finding.metric("freed")?.value == 1_000)
    }

    @Test func dismissedFindingsLeaveTheRankingForGood() throws {
        let finding = Finding(
            analysisID: "recurring-charges", topic: .saving, subject: "netflix", label: "Netflix",
            summary: "", impact: 3_990, confidence: .high)
        var feedback = InsightFeedback()
        feedback.dismiss(finding)
        #expect(InsightRanking.rank([finding], feedback: feedback, in: october).isEmpty)
        let november = try #require(YearMonth(year: 2026, month: 11))
        #expect(InsightRanking.rank([finding], feedback: feedback, in: november).isEmpty)
    }

    @Test func feedbackSavedBeforeDismissalsStillDecodes() throws {
        let data = Data(#"{"expected":["202610|unusual-categories|market"]}"#.utf8)
        let feedback = try JSONDecoder().decode(InsightFeedback.self, from: data)
        #expect(feedback.expected.count == 1)
        #expect(feedback.dismissed.isEmpty)
    }

    @Test func recurringChargesNeedConsecutiveMonths() {
        let skipped = [6, 8, 10].map {
            charge("p\($0)", 20_000, on: date(month: $0, day: 5), summary: "Posto")
        }
        #expect(RecurringCharges().run(ledger(skipped)) == nil)
    }

    @Test func recurringChargesSplitAmountsUnderTheSameDescription() throws {
        let apple = (7...10).flatMap { month in
            [
                charge("i\(month)", 990, on: date(month: month, day: 3), summary: "APPLE.COM/BILL"),
                charge(
                    "m\(month)", 3_490, on: date(month: month, day: 9), summary: "APPLE.COM/BILL"),
            ]
        }
        let result = try #require(RecurringCharges().run(ledger(apple)))
        #expect(result.findings.map(\.impact) == [3_490, 990])
        #expect(result.findings.map(\.subject) == ["apple com bill|3490", "apple com bill|990"])
        #expect(result.metric("yearly")?.value == 537.6)
    }

    @Test func recurringChargesKeepAGraceAfterTheExpectedDay() throws {
        let gym = (7...9).map {
            charge("g\($0)", 9_900, on: date(month: $0, day: 15), summary: "Academia")
        }
        let finding = try #require(RecurringCharges().run(ledger(gym))?.findings.first)
        #expect(finding.metric("nextIn")?.value == 0)
    }

    @Test func recurringChargesCrossTheYear() throws {
        let january = date(month: 1, day: 10, year: 2027)
        let music = (10...12).map {
            charge("s\($0)", 2_190, on: date(month: $0, day: 15), summary: "Spotify")
        }
        let finding = try #require(
            RecurringCharges().run(ledger(music, today: january))?.findings.first)
        #expect(finding.metric("nextIn")?.value == 5)
    }

    @Test func suggestedBudgetsNeedRelevantRegularSpending() {
        let rare = [4, 6, 8].map { charge("r\($0)", 30_000, on: date(month: $0, day: 3)) }
        let tiny = (4...9).map {
            charge("t\($0)", 2_000, on: date(month: $0, day: 4), category: fun)
        }
        let filler = (5...9).filter { $0.isMultiple(of: 2) == false }.map {
            charge("x\($0)", 100, on: date(month: $0, day: 5), category: fun)
        }
        #expect(SuggestedBudgets().run(ledger(rare + tiny + filler)) == nil)
        #expect(SuggestedBudgets().run(ledger(Array(tiny.prefix(2)))) == nil)
    }

    @Test func endingInstallmentsCrossTheYear() throws {
        let tv = charge("tv", 300_000, on: date(month: 10, day: 2), plan: 3)
        let finding = try #require(EndingInstallments().run(ledger([tv]))?.findings.first)
        #expect(finding.metric("month")?.value == 202_701)
        #expect(finding.metric("month")?.unit == .month)
    }

    @Test func varyingPurchasesAtTheSameShopAreNotRecurring() {
        let amounts: [Int64] = [800, 1_500, 2_500]
        let bakery = (0..<26).map { week in
            charge(
                "b\(week)", amounts[week % 3],
                on: calendar.date(byAdding: .day, value: -week * 7, to: today) ?? today,
                summary: "Padaria")
        }
        let everyThreeWeeks = (0..<8).map { step in
            charge(
                "w\(step)", 2_500,
                on: calendar.date(byAdding: .day, value: -step * 21, to: today) ?? today,
                summary: "Feira")
        }
        #expect(RecurringCharges().run(ledger(everyThreeWeeks)) == nil)
        #expect(RecurringCharges().run(ledger(bakery)) == nil)
    }

    @Test func billsPaidAroundTheTurnOfTheMonthAreRecurring() throws {
        let dates = [
            date(month: 6, day: 1), date(month: 7, day: 1), date(month: 7, day: 31),
            date(month: 9, day: 1), date(month: 10, day: 2),
        ]
        let rent = dates.enumerated().map {
            charge("r\($0.offset)", 250_000, on: $0.element, summary: "Aluguel")
        }
        #expect(RecurringCharges().run(ledger(rent))?.findings.first?.subject == "aluguel")
    }

    @Test func monthlyPurchasesOnScatteredDaysAreNotRecurring() {
        let shop = zip(7...10, [2, 20, 9, 18]).map {
            charge("s\($0)", 5_000, on: date(month: $0, day: $1), summary: "Livraria")
        }
        #expect(RecurringCharges().run(ledger(shop)) == nil)
    }
}
