//
//  CategoryActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation
import CashlyDomain
import SwiftData

@ModelActor
public actor CategoryActor: CategoryUseCase {
    lazy var adapter: AdapterUseCase = AdapterActor(modelContainer: modelContainer)

    public func getCategory(id: String) async throws -> CashlyDomain.Category? {
        let predicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.categoryAdapted(
            id: entity.id,
            user: entity.user,
            name: entity.name,
            color: entity.color,
            icon: entity.icon
        )
    }

    public func getCategories() async throws -> [CashlyDomain.Category] {
        let descriptor = FetchDescriptor<CategoryEntity>(sortBy: [
            .init(\.order, order: .forward),
            .init(\.name, order: .forward)
        ])
        let entities = try modelContext.fetch(descriptor)
        return try await batchAdapt(entities)
    }

    public func getCategories(ids: [String]?, users: [String]?) async throws -> [CashlyDomain.Category] {
        let predicateID: Predicate<String>
        if let ids {
            predicateID = #Predicate { ids.contains($0) }
        } else {
            predicateID = #Predicate { _ in true }
        }

        let predicateUser: Predicate<String>
        if let users {
            predicateUser = #Predicate { users.contains($0) }
        } else {
            predicateUser = #Predicate { _ in true }
        }

        let predicate: Predicate<CategoryEntity> = #Predicate {
            predicateID.evaluate($0.id) &&
            predicateUser.evaluate($0.user)
        }

        let descriptor = FetchDescriptor<CategoryEntity>(
            predicate: predicate,
            sortBy: [
                .init(\.order, order: .forward),
                .init(\.name, order: .forward)
            ]
        )

        let entities = try modelContext.fetch(descriptor)
        return try await batchAdapt(entities)
    }

    private func batchAdapt(_ entities: [CategoryEntity]) async throws -> [CashlyDomain.Category] {
        let rows = entities.map { (
            id: $0.id, user: $0.user, name: $0.name, color: $0.color, icon: $0.icon, order: $0.order
        ) }
        // Fast path when the adapter is the production `AdapterActor`
        // — it exposes a batch method that issues one UserEntity
        // fetch for the whole list. Falls back to the per-entity
        // protocol method for mocks that don't implement the batch.
        if let adapter = adapter as? AdapterActor {
            return try await adapter.categoriesAdapted(rows)
        }
        var categories = [CashlyDomain.Category]()
        for row in rows {
            if let category = try await adapter.categoryAdapted(
                id: row.id,
                user: row.user,
                name: row.name,
                color: row.color,
                icon: row.icon
            ) {
                categories.append(category)
            }
        }
        return categories
    }

    public func removeCategory(id: String) async throws {
        let predicate: Predicate<CategoryEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    public func removeCategories() async throws {
        let descriptor = FetchDescriptor<CategoryEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }

    public func addCategory(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String,
        order: Int
    ) async throws {
        let predicate: Predicate<CategoryEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? CategoryEntity(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon,
            order: order
        )
        entity.id = id
        entity.user = user
        entity.name = name
        entity.color = color
        entity.icon = icon
        entity.order = order
        modelContext.insert(entity)
        try modelContext.save()
    }

    public func reorderCategories(ids: [String]) async throws {
        let predicate: Predicate<CategoryEntity> = #Predicate { ids.contains($0.id) }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        let entities = try modelContext.fetch(descriptor)
        let byId = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
        for (index, id) in ids.enumerated() {
            byId[id]?.order = index
        }
        try modelContext.save()
    }
}
