//
//  CategoryActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

public actor CategoryActor: CategoryUseCase {
    let modelContext: ModelContext
    let adapter: AdapterUseCase
    
    public init(
        modelContext: ModelContext,
        adapter: AdapterUseCase
    ) {
        self.modelContext = modelContext
        self.adapter = adapter
    }
    
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
    
    public func getCategories(users: [String]?) async throws -> [CashlyDomain.Category] {
        let predicate: Predicate<CategoryEntity> = #Predicate { entity in
            users?.isEmpty == false ? users!.contains(entity.user) : true
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
        let entity = CategoryEntity(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
