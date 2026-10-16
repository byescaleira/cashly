import CashlyDomain
import FeatureCore
import FeatureTransactions
import Foundation
import Testing

@MainActor
struct EstimatedTransactionTests {
    @Test func editingAConvertedRecordKeepsTheOriginalAmountAndSplit() async throws {
        let fixture = try await TransactionFixture()
        let home = Money.currencyCode
        let other = home == "USD" ? "EUR" : "USD"
        CurrencySetting.shared.correction = CurrencyCorrection(
            target: home, date: .now, rates: [other: 5])
        var original = fixture.expense("old", cents: 2001)
        original.currencyCode = other
        original.participants = [
            Participant(
                id: "p", user: fixture.friend, splitMode: .equal, splitValue: 2, status: .settled,
                transaction: "old")
        ]
        original.splitMode = .equal
        original.splitValue = 10.01
        try await fixture.repositories.transactions.save(original)

        let edit = TransactionEditorModel(
            draft: .edit(id: "old"), repositories: fixture.repositories)
        await edit.load()
        #expect(edit.draft.isEstimated)
        #expect(edit.isAmountLocked)
        #expect(!edit.canEditParticipants)
        #expect(edit.estimateDescription != nil)
        #expect(edit.draft.amount == 100.05)
        edit.draft.summary = "Jantar editado"
        #expect(edit.canSave)
        await edit.save()
        #expect(edit.status.isSaved)
        let saved = try #require(try await fixture.repositories.transactions.transaction(id: "old"))
        #expect(saved.summary == "Jantar editado")
        #expect(saved.estimate?.money == Money(minorUnits: 2001))
        #expect(saved.estimate?.currencyCode == other)
        #expect(saved.money == Money(minorUnits: 10005))
    }
}
