import CashlyData
import CashlyDomain
import Foundation
import SwiftData
import Testing

struct ScenarioTests {
    private func sharedTagged(_ db: TestDatabase) async throws {
        try await db.repositories.tags.save(
            Tag(id: "tag", user: db.owner, name: "Feira", color: "0099FF", icon: "tag"))
        let participant = Participant(
            id: "party", user: db.friend, splitMode: .equal, splitValue: 2, status: .settled,
            transaction: "transaction")
        try await db.repositories.transactions.save(
            db.transaction(
                "transaction", cents: 9, plan: 3, participants: [participant], splitValue: 0.05,
                tags: ["tag"]))
    }

    @Test func renamingTagKeepsAssociationAndChangesRevision() async throws {
        let db = try await TestDatabase()
        try await sharedTagged(db)
        let dashboard = db.repositories.dashboard
        let before = try await dashboard.datasetRevision()
        try await db.repositories.tags.save(
            Tag(id: "tag", user: db.owner, name: "Alimentação", color: "0099FF", icon: "tag"))
        let tagged = try await dashboard.overview(
            query: .init(month: db.month(202_601), tagIDs: ["tag"]))
        #expect(tagged.tagExpenses["tag"]?.minorUnits == 2)
        #expect(try await dashboard.datasetRevision() != before)
    }

    @Test func deletingTagDetachesTransactions() async throws {
        let db = try await TestDatabase()
        try await sharedTagged(db)
        try await db.repositories.tags.delete(id: "tag")
        let record = try await db.repositories.transactions.transaction(id: "transaction")
        #expect(record?.tagIDs.isEmpty == true)
        #expect(try await db.repositories.dashboard.overview(query: .init()).pendingReferences == 0)
    }

    @Test func concurrentResolutionsConvergeOnLatestChoice() async throws {
        let db = try await TestDatabase()
        let context = ModelContext(db.database.modelContainer)
        let first = BudgetEntity(
            id: "choice-a", amount: 100, category: "category", date: 202_602, summary: "Versão A")
        let second = BudgetEntity(
            id: "choice-b", amount: 200, category: "category", date: 202_602, summary: "Versão B")
        for row in [first, second] {
            row.ownerID = db.owner.id
            row.amountMinorUnits = Int64(row.amount * 100)
            row.amountSource = row.amount
        }
        first.mergedIntoID = "choice-b"
        first.resolvedTargetID = "choice-b"
        first.resolutionToken = "later"
        first.resolutionTimestamp = 2
        second.mergedIntoID = "choice-a"
        second.resolvedTargetID = "choice-a"
        second.resolutionToken = "earlier"
        second.resolutionTimestamp = 1
        context.insert(first)
        context.insert(second)
        try context.save()

        let imported = CashlyDatabase(modelContainer: db.database.modelContainer)
        let resolved = try await imported.repositories(for: db.owner.id).dashboard.overview(
            query: .init(month: db.month(202_602)))
        #expect(resolved.conflicts.isEmpty)
        #expect(resolved.budgetsTotal.minorUnits == 20000)
        #expect(resolved.budgets.map(\.id) == ["choice-b"])
    }

    @Test func aLaterChoiceWinsEvenWithAClockBehind() async throws {
        let db = try await TestDatabase()
        try await db.repositories.budgets.save(db.budget("a", cents: 1000, month: 202_603))
        let context = ModelContext(db.database.modelContainer)
        let other = BudgetEntity(
            id: "b", amount: 20, category: "category", date: 202_603, summary: "Outra")
        other.ownerID = db.owner.id
        other.amountMinorUnits = 2000
        other.amountSource = 20
        context.insert(other)
        try context.save()
        let rows = try context.fetch(
            FetchDescriptor<BudgetEntity>(
                predicate: #Predicate { $0.date == 202_603 && $0.id == "a" }))
        let future = Date.now.timeIntervalSince1970 + 86_400 * 365
        for row in rows {
            row.resolutionToken = "fast-clock"
            row.resolutionTimestamp = future
            row.resolvedTargetID = "a"
        }
        try context.save()

        let imported = CashlyDatabase(modelContainer: db.database.modelContainer)
        let repositories = imported.repositories(for: db.owner.id)
        try await repositories.budgets.resolveConflict(keeping: "b")
        let after = try await repositories.dashboard.overview(
            query: .init(month: db.month(202_603)))
        #expect(after.conflicts.isEmpty)
        #expect(after.budgets.map(\.id) == ["b"])
    }

    @Test func resolvingConflictKeepsChosenBudget() async throws {
        let db = try await TestDatabase()
        try await db.repositories.budgets.save(db.budget("kept", cents: 1000, month: 202_601))
        let context = ModelContext(db.database.modelContainer)
        let duplicate = BudgetEntity(
            id: "duplicate", amount: 15, category: "category", date: 202_601, summary: "Outra")
        duplicate.ownerID = db.owner.id
        duplicate.amountMinorUnits = 1500
        duplicate.amountSource = 15
        context.insert(duplicate)
        try context.save()

        let imported = CashlyDatabase(modelContainer: db.database.modelContainer)
        let repositories = imported.repositories(for: db.owner.id)
        let before = try await repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        try await repositories.budgets.resolveConflict(keeping: "kept")
        let after = try await repositories.dashboard.overview(
            query: .init(month: db.month(202_601)))
        #expect(before.conflicts.count == 1)
        #expect(after.conflicts.isEmpty)
        #expect(after.budgetsTotal.minorUnits == 1000)
    }

    @Test func intelligenceRequiresEnoughHistoryAndCurrentRevision() async throws {
        let db = try await TestDatabase()
        try await sharedTagged(db)
        let training = try await db.repositories.dashboard.trainingData()
        let service = LocalIntelligenceService(
            directory: FileManager.default.temporaryDirectory.appending(
                path: "cashly-tests-" + UUID().uuidString))
        await #expect(throws: CashlyError.self) {
            try await service.train(
                userID: db.owner.id, transactions: training.transactions, tags: training.tags,
                revision: training.revision)
        }
        var bakery = try #require(training.transactions.first)
        bakery.id = "another"
        bakery.summary = "Compra Padaria"
        bakery.date = try db.month(202_602).startDate
        bakery.category = Category(
            id: "bakery", user: db.owner, name: "Padaria", color: "0099FF", icon: "cart")
        _ = try await service.train(
            userID: db.owner.id, transactions: training.transactions + [bakery],
            tags: training.tags, revision: training.revision)
        let fresh = try await service.predict(
            userID: db.owner.id, input: .text("Padaria"), revision: training.revision)
        let stale = try await service.predict(
            userID: db.owner.id, input: .text("Padaria"), revision: "changed")
        #expect(fresh == .textClassification("bakery"))
        #expect(stale == .empty)
    }
}
