import CashlyDomain
import FeatureCore
import FeatureTransactions
import Foundation
import Testing

@MainActor
struct TransactionExchangeTests {
    let home = Money.currencyCode

    @Test func paymentInAnotherCurrencyUsesTheRateOfItsDate() async throws {
        let fixture = try await TransactionFixture()
        let rates = DatedRates(home: home)
        let form = TransactionEditorModel(repositories: fixture.repositories, rates: rates)
        await form.load()
        form.draft.date = fixture.january
        form.draft.summary = "Ramen em Tóquio"
        form.draft.amount = 10
        form.choosePaidCurrency("JPY")
        #expect(form.draft.isForeign)
        #expect(form.draft.paidAmount == 10)
        #expect(!form.canSave)
        form.draft.paidAmount = 1500
        await form.updateRate()
        #expect(form.draft.rate == Decimal(string: "0.04"))
        #expect(form.draft.amount == 60)
        #expect(form.rateDescription != nil)
        await form.save()
        #expect(form.status.isSaved)
        let saved = try #require(
            try await fixture.repositories.transactions.transaction(id: form.draft.id))
        #expect(saved.money == Money(minorUnits: 6000))
        #expect(saved.exchange?.currencyCode == "JPY")
        #expect(saved.exchange?.money == Money(minorUnits: 150_000))

        let edit = TransactionEditorModel(
            draft: .edit(id: saved.id), repositories: fixture.repositories, rates: rates)
        await edit.load()
        #expect(edit.draft.paidCurrency == "JPY")
        #expect(edit.draft.paidAmount == 1500)
        rates.shift()
        await edit.updateRate()
        #expect(edit.draft.rate == Decimal(string: "0.04"))
        edit.draft.date = fixture.january.addingTimeInterval(86_400 * 3)
        await edit.updateRate()
        #expect(edit.draft.rate == Decimal(string: "0.05"))
        #expect(edit.draft.amount == 75)
        edit.choosePaidCurrency(home)
        #expect(!edit.draft.isForeign)
        #expect(edit.draft.amount == 1500)
    }

    @Test func missingRateBlocksSaving() async throws {
        let fixture = try await TransactionFixture()
        let form = TransactionEditorModel(repositories: fixture.repositories)
        await form.load()
        form.draft.summary = "Café em Paris"
        form.draft.amount = 5
        form.choosePaidCurrency("EUR" == home ? "USD" : "EUR")
        await form.updateRate()
        #expect(form.rateFailed)
        #expect(!form.canSave)
    }
}

private final class DatedRates: ExchangeRateProviding, @unchecked Sendable {
    let home: String
    private var rate = Decimal(string: "0.04") ?? 0

    init(home: String) {
        self.home = home
    }

    func shift() {
        rate = Decimal(string: "0.05") ?? 0
    }

    func table(base: String, on date: Date?) async throws -> ExchangeTable {
        ExchangeTable(
            base: base, day: ExchangeTable.day(for: date ?? .now), rates: [home: rate],
            source: .currencyAPI)
    }

    func currencies() async throws -> [String] {
        ["JPY", "EUR", "USD", home]
    }
}
