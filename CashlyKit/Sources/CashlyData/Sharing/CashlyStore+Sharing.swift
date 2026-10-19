import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    func sharedProfileIDs() throws -> [String] {
        try modelContext.fetch(FetchDescriptor<UserEntity>()).map(\.id)
    }

    func sharedRecords(profileID: String, known: Set<String> = []) throws -> [SharedRecord] {
        var records: [SharedRecord] = []
        for row in try rows(#Predicate<UserEntity> { $0.id == profileID }) {
            records.append(try SharedRecord(kind: .profile, id: row.id, row: ProfileRow(row)))
        }
        for row in try rows(#Predicate<CategoryEntity> { $0.user == profileID }) {
            records.append(try SharedRecord(kind: .category, id: row.id, row: LabelRow(row)))
        }
        for row in try rows(#Predicate<TagEntity> { $0.user == profileID }) {
            records.append(try SharedRecord(kind: .tag, id: row.id, row: LabelRow(row)))
        }
        for row in try rows(#Predicate<BudgetEntity> { $0.ownerID == profileID }) {
            records.append(try SharedRecord(kind: .budget, id: row.id, row: BudgetRow(row)))
        }
        let transactions = try rows(#Predicate<TransactionEntity> { $0.ownerID == profileID })
        for row in transactions {
            records.append(
                try SharedRecord(kind: .transaction, id: row.id, row: TransactionRow(row)))
        }
        let owned = Set(transactions.map(\.id))
        for row in try modelContext.fetch(FetchDescriptor<ParticipantEntity>())
        where owned.contains(row.transaction)
            || known.contains(SharedRecord.Key(kind: .participant, id: row.id).name)
        {
            records.append(
                try SharedRecord(kind: .participant, id: row.id, row: ParticipantRow(row)))
        }
        return records
    }

    func sharedRecord(_ key: SharedRecord.Key) throws -> SharedRecord? {
        let id = key.id
        return switch key.kind {
        case .profile:
            try rows(#Predicate<UserEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .profile, id: id, row: ProfileRow($0))
            }
        case .category:
            try rows(#Predicate<CategoryEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .category, id: id, row: LabelRow($0))
            }
        case .tag:
            try rows(#Predicate<TagEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .tag, id: id, row: LabelRow($0))
            }
        case .budget:
            try rows(#Predicate<BudgetEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .budget, id: id, row: BudgetRow($0))
            }
        case .transaction:
            try rows(#Predicate<TransactionEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .transaction, id: id, row: TransactionRow($0))
            }
        case .participant:
            try rows(#Predicate<ParticipantEntity> { $0.id == id }).first.map {
                try SharedRecord(kind: .participant, id: id, row: ParticipantRow($0))
            }
        }
    }

    func sharedDigests(_ keys: [SharedRecord.Key]) throws -> [String: String] {
        var digests: [String: String] = [:]
        for key in keys {
            if let record = try sharedRecord(key) { digests[record.name] = record.digest }
        }
        return digests
    }

    func applyShared(_ records: [SharedRecord], deleting keys: [SharedRecord.Key]) throws {
        guard !records.isEmpty || !keys.isEmpty else { return }
        do {
            for record in records { try upsertShared(record) }
            for key in keys { try deleteShared(key) }
            try commit(isRemote: true)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    func purgeShared(profileID: String) throws {
        do {
            let transactions = try rows(#Predicate<TransactionEntity> { $0.ownerID == profileID })
            let owned = Set(transactions.map(\.id))
            for row in try modelContext.fetch(FetchDescriptor<ParticipantEntity>())
            where owned.contains(row.transaction) {
                modelContext.delete(row)
            }
            transactions.forEach(modelContext.delete)
            try rows(#Predicate<UserEntity> { $0.id == profileID }).forEach(modelContext.delete)
            try rows(#Predicate<CategoryEntity> { $0.user == profileID })
                .forEach(modelContext.delete)
            try rows(#Predicate<TagEntity> { $0.user == profileID }).forEach(modelContext.delete)
            try rows(#Predicate<BudgetEntity> { $0.ownerID == profileID })
                .forEach(modelContext.delete)
            try rows(#Predicate<GameEventEntity> { $0.ownerID == profileID })
                .forEach(modelContext.delete)
            try rows(#Predicate<CaptureEntity> { $0.ownerID == profileID })
                .forEach(modelContext.delete)
            try rows(#Predicate<MerchantMemoryEntity> { $0.ownerID == profileID })
                .forEach(modelContext.delete)
            try commit(isRemote: true)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func rows<Row: PersistentModel>(_ predicate: Predicate<Row>) throws -> [Row] {
        try modelContext.fetch(FetchDescriptor<Row>(predicate: predicate))
    }
}
