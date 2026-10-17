import CashlyAnalytics
import CashlyDomain
import Foundation
import Testing

struct ForecastTests {
    private let owner = User(id: "owner", name: "Ana")
    private var market: CashlyDomain.Category {
        CashlyDomain.Category(
            id: "market", user: owner, name: "Mercado", color: "C2602A", icon: "cart")
    }
    private let calendar = CashlyCalendar.current

    private var today: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 20, hour: 12)) ?? .now
    }

    private var lateToday: Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: 29, hour: 12)) ?? .now
    }

    private func charge(_ id: String, _ cents: Int64, on date: Date, plan: Int? = nil)
        -> Transaction
    {
        Transaction(
            id: id, participants: [], category: market, money: Money(minorUnits: cents),
            date: date, summary: "Compra", status: .settled, splitMode: nil, splitValue: nil,
            paymentsPlan: plan)
    }

    private func ledger(_ transactions: [Transaction], budget: Int64 = 0, today: Date? = nil)
        -> LedgerSnapshot
    {
        let october = YearMonth(year: 2026, month: 10) ?? YearMonth(.now)
        return LedgerSnapshot(
            transactions: transactions, categories: [market], tags: [],
            budgets: budget > 0
                ? [
                    Budget(
                        id: "b", money: Money(minorUnits: budget), category: market,
                        month: october, summary: "")
                ] : [],
            revision: "r1", today: today ?? self.today)
    }

    @Test func aFlatHistoryIsForecastExactly() throws {
        let forecast = try #require(Forecaster.forecast(Array(repeating: 1_000, count: 10)))
        #expect(forecast.value == 1_000)
        #expect(forecast.low == 1_000)
        #expect(forecast.high == 1_000)
    }

    @Test func seasonalHistoryPicksTheSeasonalModel() throws {
        let year: [Double] = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 900]
        let forecast = try #require(Forecaster.forecast(year + year + year, origins: 12))
        #expect(forecast.model == .seasonalNaive)
        #expect(forecast.value == 100)
    }

    @Test func crostonSpreadsIntermittentDemandOverItsInterval() throws {
        let history: [Double] = [0, 0, 300, 0, 0, 300, 0, 0, 300, 0, 0, 300]
        let value = try #require(ForecastModel.croston.predict(history))
        #expect(abs(value - 100) < 1)
        #expect(ForecastModel.croston.predict([100, 100, 100, 100]) == nil)
        let forecast = try #require(
            Forecaster.forecast(history, models: [.naive, .croston], origins: 6))
        #expect(forecast.model == .croston)
    }

    @Test func seasonalForecastTwoMonthsAheadUsesTheRightMonth() throws {
        let year: [Double] = [100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 900, 100]
        #expect(ForecastModel.seasonalNaive.predict(year + year, horizon: 2) == 100)
        #expect(
            ForecastModel.seasonalNaive.predict(Array((year + year).dropLast(2)), horizon: 2) == 100
        )
        #expect(
            ForecastModel.seasonalNaive.predict(Array((year + year).dropLast(3)), horizon: 2) == 900
        )
    }

    @Test func fewResidualsWidenTheRange() throws {
        let forecast = try #require(Forecaster.forecast([100, 120, 90, 110, 100, 130, 95]))
        #expect(forecast.residuals < 10)
        #expect(abs(forecast.high - forecast.value - 1.6 * forecast.meanAbsoluteError) < 0.000_1)
    }

    @Test func tooShortAHistoryHasNoForecast() {
        #expect(Forecaster.forecast([1, 2, 3, 4, 5]) == nil)
    }

    @Test func nextMonthAddsCommittedInstallments() throws {
        let past = (1...8).map { offset in
            charge(
                "p\(offset)", 50_000,
                on: calendar.date(byAdding: .month, value: -offset, to: today) ?? today)
        }
        let tv = charge("tv", 120_000, on: today, plan: 12)
        let result = try #require(NextMonthForecast().run(ledger(past + [tv])))
        #expect(result.metric("committed")?.value == 100)
        #expect(result.metric("variable")?.value == 500)
        #expect(result.metric("total")?.value == 600)
    }

    @Test func overPlanRiskIsStableAndBounded() throws {
        let daily = (0..<91).map { offset in
            charge(
                "d\(offset)", 2_000,
                on: calendar.date(byAdding: .day, value: -offset, to: today) ?? today)
        }
        let tight = try #require(OverPlanRisk().run(ledger(daily, budget: 50_000)))
        let loose = try #require(OverPlanRisk().run(ledger(daily, budget: 500_000)))
        #expect(tight.metric("probability")?.value == 1)
        #expect(loose.metric("probability")?.value == 0)
        #expect(OverPlanRisk().run(ledger(daily)) == nil)
    }

    @Test func overPlanRiskIsDeterministicAndAgreesWithTheForecast() throws {
        let amounts: [Int64] = [500, 9_000, 1_200, 0, 3_000, 15_000, 700]
        let daily = (0..<91).map { offset in
            charge(
                "d\(offset)", amounts[offset % amounts.count] + 1,
                on: calendar.date(byAdding: .day, value: -offset, to: today) ?? today)
        }
        let projected = try #require(MonthPace.projection(ledger(daily))?.projected)
        let under = try #require(OverPlanRisk().run(ledger(daily, budget: projected + 3_000)))
        let over = try #require(OverPlanRisk().run(ledger(daily, budget: projected - 3_000)))
        let chance = try #require(under.metric("probability")?.value)
        #expect(chance > 0 && chance < 0.5)
        #expect((over.metric("probability")?.value ?? 0) > 0.5)
        let again = try #require(OverPlanRisk().run(ledger(daily, budget: projected + 3_000)))
        #expect(again.metric("probability")?.value == chance)
    }

    @Test func scheduledInstallmentsSetTheFloorOfTheRisk() throws {
        let daily = (0..<91).map { offset in
            charge(
                "d\(offset)", 2_000,
                on: calendar.date(byAdding: .day, value: -offset, to: today) ?? today)
        }
        let late =
            calendar.date(from: DateComponents(year: 2026, month: 10, day: 28, hour: 12)) ?? today
        let laptop = charge("laptop", 600_000, on: late, plan: 12)
        let projection = try #require(MonthPace.projection(ledger(daily + [laptop])))
        #expect(projection.projected == 40_000 + 50_000)
        let risk = try #require(
            OverPlanRisk().run(ledger(daily + [laptop], budget: projection.projected - 1)))
        #expect(risk.metric("probability")?.value == 1)
    }

    @Test func overPlanRiskNeverTiesWithTheForecastSide() throws {
        let sparse = (0..<91).map { offset in
            charge(
                "s\(offset)", offset.isMultiple(of: 3) ? 9_000 : 0,
                on: calendar.date(byAdding: .day, value: -offset, to: lateToday) ?? lateToday)
        }
        let snapshot = { (budget: Int64) in
            self.ledger(sparse, budget: budget, today: self.lateToday)
        }
        let projected = try #require(MonthPace.projection(snapshot(1))?.projected)
        let equal = try #require(
            OverPlanRisk().run(snapshot(projected))?.metric("probability")?.value)
        let below = try #require(
            OverPlanRisk().run(snapshot(projected - 1))?.metric("probability")?.value)
        let above = try #require(
            OverPlanRisk().run(snapshot(projected + 1))?.metric("probability")?.value)
        #expect(equal < 0.5)
        #expect(above < 0.5)
        #expect(below >= 0.5)
    }
}
