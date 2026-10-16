import CashlyData
import CashlyDomain
import Foundation
import SwiftData

struct MigrationReport {
    struct User {
        let id: String
        let transactions: Int
        let loaded: Int
        let pending: Int
        let ownerMinor: Int64
        let budgetMinor: Int64
    }

    struct Record {
        let id: String
        let originalMinor: Int64
        let sharesMinor: Int64
        let ownerInstallmentsMinor: Int64
        let tagIDs: [String]
    }

    static let entities = [
        "users", "categories", "budgets", "tags", "transactions", "participants",
    ]

    var users: [User] = []
    var records: [Record] = []
    var counts: [String: Int] = [:]
    let copy: URL

    var lines: [String] {
        users.map {
            "MIGRATED user=\($0.id) transactions=\($0.transactions) loaded=\($0.loaded) pending=\($0.pending) ownerMinor=\($0.ownerMinor) budgetMinor=\($0.budgetMinor)"
        }
            + records.map {
                "RECORD id=\($0.id) originalMinor=\($0.originalMinor) sharesMinor=\($0.sharesMinor) ownerInstallmentsMinor=\($0.ownerInstallmentsMinor) tagIDs=\($0.tagIDs)"
            }
            + [
                "COUNTS "
                    + Self.entities.map { "\($0)=\(counts[$0, default: 0])" }.joined(separator: " ")
            ]
            + ["AUDIT_COPY \(copy.path)"]
    }

    @MainActor static func measure(store original: URL) async throws -> MigrationReport {
        let copy = try AuditFolder.make("cashly-audit").appending(path: original.lastPathComponent)
        for suffix in ["", "-wal", "-shm"]
        where FileManager.default.fileExists(atPath: original.path + suffix) {
            try FileManager.default.copyItem(
                at: URL(filePath: original.path + suffix), to: URL(filePath: copy.path + suffix))
        }
        let database = try CashlyDatabase.open(cloudSync: false, storeURL: copy)
        var report = MigrationReport(copy: copy)
        for user in try await database.repositories(for: nil).users.users() {
            let dashboard = database.repositories(for: user.id).dashboard
            let state = try await dashboard.load(query: .init())
            let page = try await dashboard.page(query: .init(), after: nil, limit: 50)
            report.users.append(
                User(
                    id: user.id, transactions: state.totalTransactionCount,
                    loaded: page.items.count,
                    pending: state.overview.pendingReferences,
                    ownerMinor: state.overview.expensesTotal.minorUnits,
                    budgetMinor: state.overview.budgetsTotal.minorUnits))
            report.records += try await dashboard.history().transactions.map(record)
        }
        report.counts = try counts(in: ModelContext(database.modelContainer))
        return report
    }

    private static func record(_ transaction: Transaction) throws -> Record {
        let shares = try transaction.participants.reduce(transaction.attributedMoney) {
            try $0.adding(transaction.participantMoney(id: $1.id))
        }
        let plan = transaction.paymentsPlan ?? 1
        let installments = try (0..<plan).reduce(Money.zero) {
            try $0.adding(transaction.attributedMoney.installment(at: $1, count: plan))
        }
        return Record(
            id: transaction.id, originalMinor: transaction.money.minorUnits,
            sharesMinor: shares.minorUnits, ownerInstallmentsMinor: installments.minorUnits,
            tagIDs: transaction.tagIDs.sorted())
    }

    private static func counts(in context: ModelContext) throws -> [String: Int] {
        [
            "users": try context.fetchCount(FetchDescriptor<UserEntity>()),
            "categories": try context.fetchCount(FetchDescriptor<CategoryEntity>()),
            "budgets": try context.fetchCount(FetchDescriptor<BudgetEntity>()),
            "tags": try context.fetchCount(FetchDescriptor<TagEntity>()),
            "transactions": try context.fetchCount(FetchDescriptor<TransactionEntity>()),
            "participants": try context.fetchCount(FetchDescriptor<ParticipantEntity>()),
        ]
    }
}
