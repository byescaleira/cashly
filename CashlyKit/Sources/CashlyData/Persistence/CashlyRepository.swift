import CashlyDomain
import Foundation
import SwiftData

/// A single actor owns the store. Immutable scoped gateways supply the window's user ID.
@ModelActor
public actor CashlyRepository {
    public nonisolated let changeHub = CashlyChangeHub()
    private var normalizedRevision: UInt64?
    var datasetCache: [String: String] = [:]
    func ensureNormalization() throws {
        let revision = changeHub.remoteRevision
        guard normalizedRevision != revision else { return }
        datasetCache.removeAll()
        do { try prepare() } catch {
            modelContext.rollback()
            throw error
        }
        normalizedRevision = revision
    }

    public func getUsers() throws -> [User] {
        try modelContext.fetch(
            FetchDescriptor<UserEntity>(sortBy: [SortDescriptor(\.name), SortDescriptor(\.id)])
        )
        .map { User(id: $0.id, name: $0.name, photo: $0.photo) }
    }
    public func getUser(id: String) throws -> User? {
        var descriptor = FetchDescriptor<UserEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 2
        let values = try modelContext.fetch(descriptor)
        guard values.count <= 1 else {
            throw CashlyError.persistence("Existem usuários com IDs conflitantes no armazenamento.")
        }
        return values.first.map { User(id: $0.id, name: $0.name, photo: $0.photo) }
    }
    func requireCategory(id: String, userID: String) throws -> CategoryEntity {
        var descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.id == id && $0.user == userID })
        descriptor.fetchLimit = 2
        let values = try modelContext.fetch(descriptor)
        guard values.count == 1, let row = values.first else { throw CashlyError.missingRecord }
        return row
    }
    func requireBudget(id: String, userID: String) throws -> BudgetEntity {
        var target = id
        var visited: Set<String> = []
        while visited.insert(target).inserted {
            let value = target
            var descriptor = FetchDescriptor<BudgetEntity>(
                predicate: #Predicate { $0.id == value && $0.ownerID == userID })
            descriptor.fetchLimit = 2
            let values = try modelContext.fetch(descriptor)
            guard values.count == 1, let row = values.first else { throw CashlyError.missingRecord }
            if row.mergedIntoID.isEmpty { return row }
            target = row.mergedIntoID
        }
        throw CashlyError.persistence(
            "Existem referências circulares entre orçamentos. Os dados foram preservados.")
    }
    func requireTag(id: String, userID: String) throws -> TagEntity {
        var descriptor = FetchDescriptor<TagEntity>(
            predicate: #Predicate { $0.id == id && $0.user == userID })
        descriptor.fetchLimit = 2
        let values = try modelContext.fetch(descriptor)
        guard values.count == 1, let row = values.first else { throw CashlyError.missingRecord }
        return row
    }
    func requireTransaction(id: String, userID: String) throws -> TransactionEntity {
        var descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.id == id && $0.ownerID == userID })
        descriptor.fetchLimit = 2
        let values = try modelContext.fetch(descriptor)
        guard values.count == 1, let row = values.first else { throw CashlyError.missingRecord }
        return row
    }
    func commit(userID: String? = nil) throws {
        do {
            try modelContext.save()
            normalizedRevision = nil
            if let userID {
                datasetCache.removeValue(forKey: userID)
            } else {
                datasetCache.removeAll()
            }
            changeHub.publish(StorageChange(userID: userID))
        } catch {
            modelContext.rollback()
            CashlyMetrics.failure("save", error: error)
            throw error
        }
    }
}
