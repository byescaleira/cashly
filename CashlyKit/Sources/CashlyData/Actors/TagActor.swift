//
//  TagActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import Foundation
import CashlyDomain
import SwiftData

@ModelActor
public actor TagActor: TagUseCase {
    lazy var adapter: AdapterUseCase = AdapterActor(modelContainer: modelContainer)

    public func getTag(id: String) async throws -> Tag? {
        let predicate: Predicate<TagEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TagEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.tagAdapted(
            id: entity.id,
            user: entity.user,
            name: entity.name,
            color: entity.color,
            icon: entity.icon
        )
    }

    public func getTags() async throws -> [Tag] {
        let descriptor = FetchDescriptor<TagEntity>(sortBy: [.init(\.name, order: .forward)])
        let entities = try modelContext.fetch(descriptor)
        return try await batchAdapt(entities)
    }

    public func getTags(users: [String]?) async throws -> [Tag] {
        let userIDs = users ?? []
        let predicate: Predicate<TagEntity> = #Predicate { entity in
            userIDs.isEmpty || userIDs.contains(entity.user)
        }

        let descriptor = FetchDescriptor<TagEntity>(
            predicate: predicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return try await batchAdapt(entities)
    }

    private func batchAdapt(_ entities: [TagEntity]) async throws -> [Tag] {
        let rows = entities.map { (
            id: $0.id, user: $0.user, name: $0.name, color: $0.color, icon: $0.icon
        ) }
        if let adapter = adapter as? AdapterActor {
            return try await adapter.tagsAdapted(rows)
        }
        var tags = [Tag]()
        for row in rows {
            if let tag = try await adapter.tagAdapted(
                id: row.id,
                user: row.user,
                name: row.name,
                color: row.color,
                icon: row.icon
            ) {
                tags.append(tag)
            }
        }
        return tags
    }

    public func removeTag(id: String) async throws {
        let predicate: Predicate<TagEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TagEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    public func removeTags() async throws {
        let descriptor = FetchDescriptor<TagEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func addTag(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws {
        let predicate: Predicate<TagEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<TagEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? TagEntity(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon
        )
        entity.id = id
        entity.user = user
        entity.name = name
        entity.color = color
        entity.icon = icon
        modelContext.insert(entity)
        try modelContext.save()
    }
}
