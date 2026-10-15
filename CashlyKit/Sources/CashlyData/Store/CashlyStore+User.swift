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
        let events = try modelContext.fetch(
            FetchDescriptor<GameEventEntity>(predicate: #Predicate { $0.ownerID == id }))
        for event in events { modelContext.delete(event) }
        modelContext.delete(entity)
        try commit()
    }

    public func save(_ user: User, contextUserID: String?) throws {
        try upsert(user, contextUserID: contextUserID, replacing: false)
        try commit()
    }

    func upsert(_ user: User, contextUserID: String?, replacing: Bool) throws {
        let id = user.id
        let name = user.name
        let photo = user.photo
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3, photo.isValid
        else { throw CashlyError.onSave }
        let predicate: Predicate<UserEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        let previous = try modelContext.fetch(descriptor).first
        guard replacing || previous == nil || id == contextUserID else {
            throw CashlyError.onSave
        }
        let entity = previous ?? UserEntity(id: id, name: name, photo: photo.encoded)
        entity.name = name
        entity.photo = photo.encoded
        modelContext.insert(entity)
    }

    static func user(_ entity: UserEntity) -> User {
        User(id: entity.id, name: entity.name, photo: ProfilePhoto(encoded: entity.photo))
    }

}
