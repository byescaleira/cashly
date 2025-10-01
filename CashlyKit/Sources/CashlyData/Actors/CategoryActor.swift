//
//  CategoryActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

@ModelActor
public actor CategoryActor: CategoryUseCase {
    let adapter: AdapterUseCase = CashlyDataFactory().makeAdapter()
    
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
        let descriptor = FetchDescriptor<CategoryEntity>(sortBy: [.init(\.name, order: .forward)])
        let entities = try modelContext.fetch(descriptor)
        var categories = [CashlyDomain.Category]()
        for entity in entities {
            if let category = try await adapter.categoryAdapted(
                id: entity.id,
                user: entity.user,
                name: entity.name,
                color: entity.color,
                icon: entity.icon
            ) {
                categories.append(category)
            }
        }
        return categories
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
            sortBy: [.init(\.name, order: .forward)]
        )
        
        let entities = try modelContext.fetch(descriptor)
        var categories = [CashlyDomain.Category]()
        for entity in entities {
            if let category = try await adapter.categoryAdapted(
                id: entity.id,
                user: entity.user,
                name: entity.name,
                color: entity.color,
                icon: entity.icon
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
        icon: String
    ) async throws {
        let predicate: Predicate<CategoryEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<CategoryEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? CategoryEntity(
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
