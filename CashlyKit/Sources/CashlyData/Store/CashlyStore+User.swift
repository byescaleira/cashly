import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func removeUser(id: String) throws {
        guard
            try modelContext.fetchCount(
                FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.ownerID == id }))
                == 0,
            try modelContext.fetchCount(
                FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.ownerID == id })) == 0
        else { throw CashlyError.onRemove }
        guard
            try modelContext.fetch(
                FetchDescriptor<CategoryEntity>(predicate: #Predicate { $0.user == id })
            ).isEmpty,
            try modelContext.fetch(
                FetchDescriptor<TagEntity>(predicate: #Predicate { $0.user == id })
            )
            .isEmpty,
            try modelContext.fetch(
                FetchDescriptor<ParticipantEntity>(predicate: #Predicate { $0.user == id })
            ).isEmpty
        else { throw CashlyError.onRemove }
        let predicate: Predicate<UserEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try commit()
    }

    public func save(_ user: User, contextUserID: String?) throws {
        let id = user.id
        let name = user.name
        let photo = user.photo
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
            (1...100).contains(Int(photo) ?? 0)
        else { throw CashlyError.onSave }
        let predicate: Predicate<UserEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        let previous = try modelContext.fetch(descriptor).first
        guard previous == nil || id == contextUserID else { throw CashlyError.onSave }
        let entity =
            try modelContext.fetch(descriptor).first
            ?? UserEntity(
                id: id,
                name: name,
                photo: photo
            )
        entity.id = id
        entity.name = name
        entity.photo = photo
        modelContext.insert(entity)
        try commit()
    }

}
