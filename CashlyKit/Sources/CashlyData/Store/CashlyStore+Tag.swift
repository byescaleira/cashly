import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func removeTag(id: String, userID: String) throws {
        do {
            _ = try requireTag(id: id, userID: userID)
            let predicate: Predicate<TagEntity> = #Predicate {
                $0.id == id
            }
            let descriptor = FetchDescriptor<TagEntity>(predicate: predicate)
            guard let entity = try modelContext.fetch(descriptor).first else { return }
            try detachTags(ids: [id], userID: userID)
            modelContext.delete(entity)
            try commit(userID: userID)

        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func detachTags(ids: Set<String>, userID: String) throws {
        var descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.ownerID == userID }, sortBy: [SortDescriptor(\.id)])
        descriptor.fetchLimit = 500
        var offset = 0
        while true {
            descriptor.fetchOffset = offset
            let rows = try modelContext.fetch(descriptor)
            for row in rows where !Set(row.tagIDs).isDisjoint(with: ids) {
                row.tagIDs.removeAll { ids.contains($0) }
                row.contentRevision = UUID().uuidString
            }
            offset += rows.count
            if rows.count < 500 { break }
        }
    }

    public func save(_ tag: Tag) throws {
        let id = tag.id
        let user = tag.user.id
        let name = tag.name
        let color = tag.color
        let icon = tag.icon
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3, !icon.isEmpty,
            try getUser(id: user) != nil
        else { throw CashlyError.onSave }
        let predicate: Predicate<TagEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<TagEntity>(predicate: predicate)
        let entity =
            try modelContext.fetch(descriptor).first
            ?? TagEntity(
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
