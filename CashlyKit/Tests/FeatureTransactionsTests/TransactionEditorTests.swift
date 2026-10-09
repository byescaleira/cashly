import CashlyDomain
import FeatureCore
import FeatureTransactions
import Testing

@MainActor
struct TransactionEditorTests {
    @Test func incomeIsCreatedAndEditedWithoutBudget() async throws {
        let fixture = try await TransactionFixture()
        let form = TransactionEditorModel(repositories: fixture.repositories)
        await form.load()
        form.draft.kind = .income
        form.draft.date = fixture.january
        form.draft.amount = 500.02
        form.draft.summary = "Entrada pelo formulário"
        await form.save()
        #expect(form.status.isSaved)
        let saved = try #require(
            try await fixture.repositories.transactions.transaction(id: form.draft.id))
        #expect(saved.kind == .income)
        #expect(saved.money.minorUnits == 50002)

        let edit = TransactionEditorModel(
            draft: .edit(id: saved.id), repositories: fixture.repositories)
        await edit.load()
        #expect(edit.draft.kind == .income)
        #expect(edit.canRemove)
        edit.draft.amount = 500.03
        await edit.save()
        #expect(
            try await fixture.repositories.transactions.transaction(id: saved.id)?.money.minorUnits
                == 50003)
    }

    @Test func editingDoesNotCountTheTransactionTwice() async throws {
        let fixture = try await TransactionFixture()
        try await fixture.repositories.transactions.save(fixture.expense("existing", cents: 10_000))
        let month = YearMonth(fixture.january)
        let edit = TransactionEditorModel(
            draft: .edit(id: "existing"), repositories: fixture.repositories)
        await edit.load()
        #expect(edit.budgetImpact(in: month) == 0)
        edit.draft.amount = 150
        #expect(edit.budgetImpact(in: month) == 50)

        let new = TransactionEditorModel(repositories: fixture.repositories)
        await new.load()
        new.draft.amount = 30
        new.draft.date = fixture.january
        #expect(new.budgetImpact(in: month) == 30)
        new.draft.date = try #require(YearMonth(year: 2026, month: 2)).startDate
        #expect(new.budgetImpact(in: month) == 0)
    }

    @Test func installmentsAreDescribed() async throws {
        let fixture = try await TransactionFixture()
        let form = TransactionEditorModel(repositories: fixture.repositories)
        await form.load()
        form.draft.amount = 100
        #expect(form.installmentDescription == nil)
        form.draft.installmentIsOn = true
        form.draft.installmentPlan = 3
        #expect(form.installmentDescription?.hasPrefix("3x de") == true)
    }

    @Test func choosingCategoryStopsPrediction() async throws {
        let fixture = try await TransactionFixture()
        let form = TransactionEditorModel(repositories: fixture.repositories)
        await form.load()
        #expect(form.isPredictingCategory)
        form.chosenCategory = fixture.category
        #expect(!form.isPredictingCategory)
        form.enablePrediction()
        #expect(form.isPredictingCategory)
    }

    @Test func participantsSplitAndCanBeRemoved() async throws {
        let fixture = try await TransactionFixture()
        let form = TransactionEditorModel(repositories: fixture.repositories)
        await form.load()
        form.draft.amount = 100
        form.participantUsers = [fixture.friend]
        #expect(form.draft.splitMode == .equal)
        #expect(form.draft.splitValue == 50)
        let participant = try #require(form.draft.participants.first)
        form.removeParticipant(id: participant.id)
        #expect(form.draft.participants.isEmpty)
        #expect(form.draft.splitMode == nil)
    }
}
