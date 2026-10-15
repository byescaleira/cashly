import CashlyData
import CashlyDomain
import Foundation
import SwiftData

enum BenchmarkFixture {
    static let owners = ["a", "b"]
    static let budgetMinor: Int64 = 100_000
    static let transactionMinor: Int64 = 1001

    @MainActor static func create(count: Int, in folder: URL) throws -> CashlyDatabase {
        guard (1...100_000).contains(count) else {
            throw CashlyError.invalidInput("Volume permitido: 1…100000.")
        }
        let database = try CashlyDatabase.open(
            cloudSync: false, storeURL: folder.appending(path: "benchmark.store"))
        let context = ModelContext(database.modelContainer)
        for id in owners {
            context.insert(UserEntity(id: id, name: id, photo: ProfilePhoto.default.encoded))
            context.insert(
                CategoryEntity(
                    id: "category-" + id, user: id, name: "Mercado", color: "0099FF", icon: "cart"))
            context.insert(budget(id: "budget-" + id, owner: id, minor: budgetMinor))
        }
        let january = try YearMonth.audit(202601).startDate.timeIntervalSince1970
        for index in 0..<count {
            context.insert(transaction(index: index, date: january + Double(index % 10)))
            if index % 1000 == 999 { try context.save() }
        }
        try context.save()
        return database
    }

    @MainActor static func addConflict(to database: CashlyDatabase) throws {
        let context = ModelContext(database.modelContainer)
        context.insert(budget(id: "duplicate", owner: "a", minor: 150_000))
        try context.save()
    }

    @MainActor static func archivedBudgets(in database: CashlyDatabase) throws -> Int {
        try ModelContext(database.modelContainer).fetchCount(
            FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.mergedIntoID != "" }))
    }

    private static func budget(id: String, owner: String, minor: Int64) -> BudgetEntity {
        let amount = Double(minor) / 100
        let budget = BudgetEntity(
            id: id, amount: amount, category: "category-" + owner, date: 202601, summary: "Mensal")
        budget.ownerID = owner
        budget.amountMinorUnits = minor
        budget.amountSource = amount
        return budget
    }

    private static func transaction(index: Int, date: TimeInterval) -> TransactionEntity {
        let owner = owners[index % owners.count]
        let amount = Double(transactionMinor) / 100
        let row = TransactionEntity(
            id: String(format: "%08d", index), participants: [], budget: "budget-" + owner,
            amount: amount, date: date, summary: "Compra", status: 0)
        row.dateSource = row.date
        row.paymentsPlanSource = row.paymentsPlan
        row.ownerID = owner
        row.amountMinorUnits = transactionMinor
        row.amountSource = amount
        row.ownerMinorUnits = transactionMinor
        row.tagsMigrated = true
        row.startMonthIndex = 2026 * 12
        row.endMonthIndex = 2026 * 12
        row.contentRevision = UUID().uuidString
        return row
    }
}
