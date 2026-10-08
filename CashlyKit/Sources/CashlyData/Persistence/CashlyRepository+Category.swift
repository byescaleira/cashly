import CashlyDomain
import Foundation
import SwiftData

extension CashlyRepository {
    public func removeCategory(id: String, userID: String) throws {
        try ensureNormalization()
        _ = try requireCategory(id: id, userID: userID)
        guard
            try modelContext.fetch(
                FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.category == id })
            ).isEmpty,
            try modelContext.fetchCount(
                FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate { $0.categoryID == id && $0.ownerID == userID })) == 0
        else { throw CashlyError.onRemove }
        let predicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try commit(userID: userID)
    }

    public func removeCategories(userID: String) throws {
        try ensureNormalization()
        guard
            try modelContext.fetchCount(
                FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.ownerID == userID })) == 0,
            try modelContext.fetchCount(
                FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.ownerID == userID }))
                == 0
        else {
            throw CashlyError.onRemove
        }
        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: #Predicate { $0.user == userID })
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try commit(userID: userID)
    }

    public func addCategory(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) throws {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3, !icon.isEmpty,
            try getUser(id: user) != nil
        else { throw CashlyError.onSave }
        let predicate: Predicate<CategoryEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        let entity =
            try modelContext.fetch(descriptor).first
            ?? CategoryEntity(
                id: id,
                user: user,
                name: name,
                color: color,
                icon: icon
            )
        entity.id = id
        guard entity.user.isEmpty || entity.user == user else { throw CashlyError.onSave }
        entity.user = user
        entity.name = name
        entity.color = color
        entity.icon = icon
        modelContext.insert(entity)
        try commit(userID: user)
    }

}
