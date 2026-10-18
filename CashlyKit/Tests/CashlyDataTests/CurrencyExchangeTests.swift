import CashlyData
import CashlyDomain
import Foundation
import Testing

struct CurrencyExchangeTests {
    @Test func foreignPaymentKeepsPaidAmountAndRate() async throws {
        let db = try await TestDatabase()
        var transaction = try db.transaction("trip", cents: 5265)
        let rateDate = try db.month(202_601).startDate
        transaction.exchange = TransactionExchange(
            currencyCode: "JPY", money: Money(minorUnits: 150_000),
            rate: try #require(Decimal(string: "0.0351")), date: rateDate)
        try await db.repositories.transactions.save(transaction)
        let saved = try #require(await db.repositories.transactions.transaction(id: "trip"))
        #expect(saved.money == Money(minorUnits: 5265))
        #expect(saved.exchange?.currencyCode == "JPY")
        #expect(saved.exchange?.money == Money(minorUnits: 150_000))
        #expect(saved.exchange?.rate == Decimal(string: "0.0351"))
        #expect(saved.exchange?.date == rateDate)
        let january = try await db.repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        let february = try await db.repositories.dashboard.overview(
            query: .init(month: db.month(202_602)))
        #expect(january.convertedCount == 1)
        #expect(february.convertedCount == 0)

        var plain = saved
        plain.exchange = nil
        try await db.repositories.transactions.save(plain)
        let cleared = try #require(await db.repositories.transactions.transaction(id: "trip"))
        #expect(cleared.exchange == nil)
    }

    @Test func recordsInOtherCurrenciesAreShownConvertedButSavedAsOriginal() async throws {
        let db = try await TestDatabase()
        let home = Money.currencyCode
        let other = home == "USD" ? "EUR" : "USD"
        CurrencySetting.shared.correction = CurrencyCorrection(
            target: home, date: .now, rates: [other: 5])
        var transaction = try db.transaction(
            "old", cents: 2001,
            participants: [
                Participant(
                    id: "p", user: db.friend, splitMode: .equal, splitValue: 2, status: .settled,
                    transaction: "old")
            ], splitValue: 10.01)
        transaction.currencyCode = other
        try await db.repositories.transactions.save(transaction)
        var budget = try db.budget("plan", cents: 1000, month: 202_601)
        budget.currencyCode = other
        try await db.repositories.budgets.save(budget)

        let shown = try #require(await db.repositories.transactions.transaction(id: "old"))
        #expect(shown.money == Money(minorUnits: 10005))
        #expect(shown.currencyCode == home)
        #expect(shown.estimate?.currencyCode == other)
        #expect(shown.estimate?.money == Money(minorUnits: 2001))
        let shared = shown.participants.compactMap(\.allocatedMoney).reduce(0) {
            $0 + $1.minorUnits
        }
        #expect((shown.ownerMoney?.minorUnits ?? 0) + shared == 10005)

        var edited = shown
        edited.summary = "Registro editado"
        try await db.repositories.transactions.save(edited)
        let again = try #require(await db.repositories.transactions.transaction(id: "old"))
        #expect(again.summary == "Registro editado")
        #expect(again.estimate?.money == Money(minorUnits: 2001))
        #expect(again.estimate?.currencyCode == other)

        let plan = try #require(await db.repositories.budgets.budget(id: "plan"))
        #expect(plan.money == Money(minorUnits: 5000))
        #expect(plan.estimate?.money == Money(minorUnits: 1000))
        try await db.repositories.budgets.save(plan)
        let stillOriginal = try #require(await db.repositories.budgets.budget(id: "plan"))
        #expect(stillOriginal.estimate?.money == Money(minorUnits: 1000))
    }

    @Test func capturesKeepTheirCurrency() async throws {
        let db = try await TestDatabase()
        var capture = Capture(
            ownerID: db.owner.id, money: Money(minorUnits: 4200), merchant: "Café", date: .now,
            source: .manual)
        capture.currencyCode = "USD" == Money.currencyCode ? "EUR" : "USD"
        let saved = try await db.repositories.captures.save(capture)
        let read = try await db.repositories.captures.capture(id: saved.id)
        #expect(read?.currencyCode == capture.currencyCode)
        #expect(read?.money == Money(minorUnits: 4200))
    }

    @Test func backupCarriesCurrencyAndExchange() throws {
        let owner = User(id: "owner", name: "Perfil")
        let category = Category(
            id: "category", user: owner, name: "Geral", color: "0099FF", icon: "cart")
        let transaction = Transaction(
            id: "t", participants: [], category: category, money: Money(minorUnits: 5265),
            date: Date(timeIntervalSince1970: 1_800_000_000), summary: "Sushi", status: .settled,
            splitMode: nil, splitValue: nil, paymentsPlan: nil, currencyCode: "EUR",
            exchange: TransactionExchange(
                currencyCode: "JPY", money: Money(minorUnits: 150_000), rate: 2,
                date: Date(timeIntervalSince1970: 1_800_000_000)))
        let backup = CashlyBackup(
            users: [owner], categories: [category], tags: [], budgets: [],
            transactions: [transaction])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let restored = try CashlyBackup(data: encoder.encode(backup)).entities()
        let value = try #require(restored.transactions.first)
        #expect(value.currencyCode == "EUR")
        #expect(value.exchange?.currencyCode == "JPY")
        #expect(value.exchange?.money == Money(minorUnits: 150_000))
    }
}
