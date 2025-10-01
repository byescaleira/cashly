//
//  TagActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

@ModelActor
public actor TagActor: TagUseCase {
    let adapter: AdapterUseCase = CashlyDataFactory().makeAdapter()
    
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
        var tags = [Tag]()
        for entity in entities {
            if let tag = try await adapter.tagAdapted(
                id: entity.id,
                user: entity.user,
                name: entity.name,
                color: entity.color,
                icon: entity.icon
            ) {
                tags.append(tag)
            }
        }
        return tags
    }
    
    public func getTags(users: [String]?) async throws -> [Tag] {
        let predicate: Predicate<TagEntity> = #Predicate { entity in
            users?.isEmpty == false ? users!.contains(entity.user) : true
        }
        
        let descriptor = FetchDescriptor<TagEntity>(
            predicate: predicate,
            sortBy: [.init(\.name, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        var tags = [Tag]()
        for entity in entities {
            if let tag = try await adapter.tagAdapted(
                id: entity.id,
                user: entity.user,
                name: entity.name,
                color: entity.color,
                icon: entity.icon
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
