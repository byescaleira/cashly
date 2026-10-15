import CashlyData
import CashlyDomain
import FeatureCore
import FeatureGuides
import Testing

@MainActor
struct SpreadsheetImportModelTests {
    private let owner = User(id: "owner", name: "Ana")

    private func model() async throws -> (SpreadsheetImportModel, CashlyDatabase) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        try await database.repositories(for: owner.id).categories.save(
            Category(
                id: "market", user: owner, name: "Groceries", color: "C2602A", icon: "cart.fill")
        )
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        return (SpreadsheetImportModel(session: session), database)
    }

    @Test func reviewListsWhatWillBeCreated() async throws {
        let (model, _) = try await model()
        await model.load(SpreadsheetParser.template, fileName: "modelo.csv")
        #expect(model.step == .review)
        #expect(model.preview?.rows.count == 3)
        #expect(model.newCategories == ["Work", "Technology"])
        #expect(model.newTags == ["Housing"])
        #expect(model.canImport)
    }

    @Test func importingCreatesTransactionsInExistingAndNewCategories() async throws {
        let (model, database) = try await model()
        await model.load(SpreadsheetParser.template, fileName: "modelo.csv")
        await model.importRows()
        #expect(model.step == .done)
        #expect(model.imported == 3)
        let snapshot = try await database.repositories(for: owner.id).dashboard.snapshot(month: nil)
        #expect(Set(snapshot.categories.map(\.name)) == ["Groceries", "Work", "Technology"])
        #expect(snapshot.tags.map(\.name) == ["Housing"])
        #expect(
            try await database.repositories(for: owner.id).dashboard.trainingData().transactions
                .count == 3)
    }

    @Test func fileWithOnlyErrorsCannotBeImported() async throws {
        let (model, _) = try await model()
        await model.load("Data;Descrição;Valor\nontem;;x\n", fileName: "ruim.csv")
        #expect(!model.canImport)
        #expect(model.preview?.issues.count == 1)
    }
}
