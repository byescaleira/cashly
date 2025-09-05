//
//  UserActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

public actor UserActor: UserUseCase {
    let modelContext: ModelContext
    let adapter: AdapterUseCase
    
    public init(
        modelContext: ModelContext,
        adapter: AdapterUseCase
    ) {
        self.modelContext = modelContext
        self.adapter = adapter
    }
    
    public func getUser(id: String) async throws -> User? {
        let predicate: Predicate<UserEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return nil }
        return try await adapter.userAdapted(
            id: entity.id,
            name: entity.name,
            photo: entity.photo
        )
    }
    
    public func getCurrentUser() async throws -> User? {
        let users = try await getUsers()
        let userID = UserDefaults.standard.string(forKey: "cashly.user")
        return users.first(where: { $0.id == userID })
    }
    
    public func getUsers() async throws -> [User] {
        let descriptor = FetchDescriptor<UserEntity>(sortBy: [.init(\.name, order: .forward)])
        let entities = try modelContext.fetch(descriptor)
        var users = [User]()
        for entity in entities {
            users.append(
                try await adapter.userAdapted(
                    id: entity.id,
                    name: entity.name,
                    photo: entity.photo
                )
            )
        }
        return users
    }
    
    public func removeUser(id: String) async throws {
        let predicate: Predicate<UserEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }
    
    public func removeUsers() async throws {
        let descriptor = FetchDescriptor<UserEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            modelContext.delete(entity)
        }
        try modelContext.save()
    }
    
    public func addUser(
        id: String,
        name: String,
        photo: String
    ) async throws {
        let entity = UserEntity(
            id: id,
            name: name,
            photo: photo
        )
        modelContext.insert(entity)
        try modelContext.save()
    }
}
