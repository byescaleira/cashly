import CashlyDomain
import Foundation
import Testing

struct ExchangeTests {
    @Test func convertsMoneyWithRounding() throws {
        let yen = Money(minorUnits: 150_000)
        #expect(try yen.converted(by: decimal("0.0351")) == Money(minorUnits: 5265))
        #expect(
            try Money(minorUnits: 1).converted(by: decimal("0.5")) == Money(minorUnits: 1))
        #expect(throws: CashlyError.self) { try yen.converted(by: 0) }
    }

    @Test func correctionInvertsTheTargetTable() {
        let table = ExchangeTable(
            base: "USD", day: "2026-10-14", rates: ["BRL": 5, "EUR": decimal("0.8")],
            source: .currencyAPI)
        let correction = CurrencyCorrection(table: table, codes: ["BRL", "EUR", "USD", "JPY"])
        #expect(correction.target == "USD")
        #expect(correction.rate(from: "BRL") == Decimal(string: "0.2"))
        #expect(correction.rate(from: "EUR") == Decimal(string: "1.25"))
        #expect(correction.rate(from: "USD") == 1)
        #expect(correction.rate(from: "JPY") == nil)
    }

    @Test func settingOnlyCorrectsOtherCurrencies() {
        let setting = CurrencySetting(code: "USD")
        #expect(setting.correctionRate(from: "BRL") == nil)
        setting.correction = CurrencyCorrection(
            target: "USD", date: .now, rates: ["BRL": decimal("0.2")])
        #expect(setting.correctionRate(from: "BRL")?.rate == Decimal(string: "0.2"))
        #expect(setting.correctionRate(from: "USD") == nil)
        setting.code = "EUR"
        #expect(setting.correctionRate(from: "BRL") == nil)
    }

    @Test func dayKeysUseTheCalendarDay() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Sao_Paulo") ?? .gmt
        let date = try #require(
            calendar.date(from: DateComponents(year: 2026, month: 3, day: 9, hour: 23)))
        #expect(ExchangeTable.day(for: date, calendar: calendar) == "2026-03-09")
        #expect(ExchangeTable.date(for: "bad") == nil)
    }

    @Test func storedTransactionRestoresTheOriginalAmount() {
        let user = User(id: "u", name: "Ana", photo: .default)
        let category = Category(id: "c", user: user, name: "Food", color: "#000000", icon: "fork")
        let transaction = Transaction(
            id: "t", participants: [], category: category, money: Money(minorUnits: 2000),
            date: .now, summary: "Lunch", status: .settled, splitMode: nil, splitValue: nil,
            paymentsPlan: nil, currencyCode: "USD",
            estimate: CurrencyEstimate(
                currencyCode: "BRL", money: Money(minorUnits: 10_000),
                ownerMoney: Money(minorUnits: 10_000), rate: decimal("0.2"), date: .now))
        let stored = transaction.stored
        #expect(stored.money == Money(minorUnits: 10_000))
        #expect(stored.currencyCode == "BRL")
        #expect(stored.estimate == nil)
    }
}

private func decimal(_ text: String) -> Decimal {
    Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) ?? .nan
}

struct ProportionalSplitTests {
    @Test func keepsTheTotalAndNeverGoesNegative() {
        let shares = ProportionalSplit.distribute(
            Money(minorUnits: 2),
            like: [.zero, Money(minorUnits: 1), Money(minorUnits: 1), Money(minorUnits: 1)])
        #expect(shares.reduce(0) { $0 + $1.minorUnits } == 2)
        #expect(shares.allSatisfy { $0.minorUnits >= 0 })
        #expect(shares[0] == .zero)
    }

    @Test func followsTheOriginalShares() {
        let shares = ProportionalSplit.distribute(
            Money(minorUnits: 10005), like: [Money(minorUnits: 1001), Money(minorUnits: 1000)])
        #expect(shares == [Money(minorUnits: 5005), Money(minorUnits: 5000)])
        let empty = ProportionalSplit.distribute(Money(minorUnits: 7), like: [.zero, .zero])
        #expect(empty == [Money(minorUnits: 7), .zero])
    }
}
