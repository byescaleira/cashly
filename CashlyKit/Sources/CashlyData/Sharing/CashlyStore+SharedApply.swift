import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    func upsertShared(_ record: SharedRecord) throws {
        let id = record.key.id
        switch record.key.kind {
        case .profile:
            let row = try record.decode(ProfileRow.self)
            let entity =
                try fetchFirst(#Predicate<UserEntity> { $0.id == id })
                ?? insert(UserEntity(id: id, name: row.name, photo: row.photo))
            row.apply(to: entity)
        case .category:
            let row = try record.decode(LabelRow.self)
            let entity =
                try fetchFirst(#Predicate<CategoryEntity> { $0.id == id })
                ?? insert(
                    CategoryEntity(
                        id: id, user: row.user, name: row.name, color: row.color, icon: row.icon))
            row.apply(to: entity)
        case .tag:
            let row = try record.decode(LabelRow.self)
            let entity =
                try fetchFirst(#Predicate<TagEntity> { $0.id == id })
                ?? insert(
                    TagEntity(
                        id: id, user: row.user, name: row.name, color: row.color, icon: row.icon))
            row.apply(to: entity)
        case .budget:
            let row = try record.decode(BudgetRow.self)
            let entity =
                try fetchFirst(#Predicate<BudgetEntity> { $0.id == id })
                ?? insert(
                    BudgetEntity(
                        id: id, amount: row.amount, category: row.category, date: row.date,
                        summary: row.summary))
            row.apply(to: entity)
        case .transaction:
            let row = try record.decode(TransactionRow.self)
            let entity =
                try fetchFirst(#Predicate<TransactionEntity> { $0.id == id })
                ?? insert(
                    TransactionEntity(
                        id: id, participants: row.participants, budget: row.budget,
                        amount: row.amount, date: row.date, summary: row.summary,
                        status: row.status))
            row.apply(to: entity)
        case .participant:
            let row = try record.decode(ParticipantRow.self)
            let entity =
                try fetchFirst(#Predicate<ParticipantEntity> { $0.id == id })
                ?? insert(
                    ParticipantEntity(
                        id: id, user: row.user, name: row.name, photo: row.photo,
                        splitMode: row.splitMode, splitValue: row.splitValue, status: row.status,
                        transaction: row.transaction))
            row.apply(to: entity)
        }
    }

    func deleteShared(_ key: SharedRecord.Key) throws {
        let id = key.id
        switch key.kind {
        case .profile: try deleteAll(#Predicate<UserEntity> { $0.id == id })
        case .category: try deleteAll(#Predicate<CategoryEntity> { $0.id == id })
        case .tag: try deleteAll(#Predicate<TagEntity> { $0.id == id })
        case .budget: try deleteAll(#Predicate<BudgetEntity> { $0.id == id })
        case .transaction: try deleteAll(#Predicate<TransactionEntity> { $0.id == id })
        case .participant: try deleteAll(#Predicate<ParticipantEntity> { $0.id == id })
        }
    }

    private func fetchFirst<Row: PersistentModel>(_ predicate: Predicate<Row>) throws -> Row? {
        var descriptor = FetchDescriptor<Row>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func insert<Row: PersistentModel>(_ row: Row) -> Row {
        modelContext.insert(row)
        return row
    }

    private func deleteAll<Row: PersistentModel>(_ predicate: Predicate<Row>) throws {
        for row in try modelContext.fetch(FetchDescriptor<Row>(predicate: predicate)) {
            modelContext.delete(row)
        }
    }
}
