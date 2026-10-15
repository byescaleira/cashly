import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func exportBackup() throws -> BackupExport {
        let users = try getUsers()
        var categories: [CashlyDomain.Category] = []
        var tags: [Tag] = []
        var budgets: [Budget] = []
        var transactions: [CashlyDomain.Transaction] = []
        var skipped = 0
        for user in users {
            let userID = user.id
            let catalog = try catalog(userID: userID)
            let rows = try modelContext.fetch(
                FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate { $0.ownerID == userID },
                    sortBy: [SortDescriptor(\.date), SortDescriptor(\.id)]))
            let mapped = try mapTransactions(rows, userID: userID, catalog: catalog)
            categories += catalog.categories
            tags += catalog.tags
            budgets += catalog.budgets
            transactions += mapped.items
            skipped += mapped.pending
        }
        return BackupExport(
            backup: CashlyBackup(
                users: users, categories: categories, tags: tags, budgets: budgets,
                transactions: transactions),
            skipped: skipped)
    }

    public func recordBackup() throws {
        let users = try getUsers()
        guard !users.isEmpty else { return }
        for user in users {
            insertGameEvent(GameEvent(kind: .backupCreated), ownerID: user.id)
        }
        try commit()
    }

    public func restore(_ backup: CashlyBackup) throws {
        let entities = try backup.entities()
        do {
            try ensureNormalization()
            for user in entities.users { try upsert(user, contextUserID: nil, replacing: true) }
            for category in entities.categories { try upsert(category) }
            for tag in entities.tags { try upsert(tag) }
            for budget in entities.budgets {
                try upsert(budget, userID: budget.user.id, allowsConflict: true)
            }
            for transaction in entities.transactions {
                try upsert(transaction, userID: transaction.ownerID, recordsEvent: false)
            }
            try commit()
        } catch {
            modelContext.rollback()
            throw CashlyError.invalidInput(
                String(
                    appLocalized:
                        "The backup has records that conflict with the data on this device. Nothing was changed."
                )
            )
        }
    }

    public func eraseAll() throws -> [String] {
        let userIDs = try getUsers().map(\.id)
        do {
            try deleteAll(CaptureEntity.self)
            try deleteAll(MerchantMemoryEntity.self)
            try deleteAll(GameEventEntity.self)
            try deleteAll(ParticipantEntity.self)
            try deleteAll(TransactionEntity.self)
            try deleteAll(BudgetEntity.self)
            try deleteAll(TagEntity.self)
            try deleteAll(CategoryEntity.self)
            try deleteAll(UserEntity.self)
            try commit()
        } catch {
            modelContext.rollback()
            throw CashlyError.onRemove
        }
        return userIDs
    }

    private func deleteAll<Model: PersistentModel>(_ type: Model.Type) throws {
        for row in try modelContext.fetch(FetchDescriptor<Model>()) { modelContext.delete(row) }
    }
}
