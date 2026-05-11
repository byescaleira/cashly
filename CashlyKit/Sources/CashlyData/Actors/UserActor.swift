//
//  UserActor.swift
//  CashlyKit
//
//  SwiftData-backed user persistence + current-user selection. Manual
//  ModelActor implementation (instead of the `@ModelActor` macro) so
//  we can inject a `UserPreferencesUseCase` for the
//  currentUser/selectUser surface without coupling Data to
//  UserDefaults directly.
//

import Foundation
import CashlyDomain
import SwiftData

public actor UserActor: UserUseCase, ModelActor {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor

    private let preferences: UserPreferencesUseCase
    private lazy var adapter: AdapterUseCase = AdapterActor(modelContainer: modelContainer)

    public init(
        modelContainer: ModelContainer,
        preferences: UserPreferencesUseCase
    ) {
        self.modelContainer = modelContainer
        let context = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: context)
        self.preferences = preferences
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
        if let id = await preferences.currentUserId(),
           let user = try await getUser(id: id) {
            return user
        }
        // Fall back to the first stored user and persist that choice.
        let users = try await getUsers()
        if let first = users.first {
            await preferences.setCurrentUserId(first.id)
        }
        return users.first
    }

    public func selectUser(user: User) async throws {
        await preferences.setCurrentUserId(user.id)
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
        let predicate: Predicate<UserEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<UserEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? UserEntity(
            id: id,
            name: name,
            photo: photo
        )
        entity.id = id
        entity.name = name
        entity.photo = photo
        modelContext.insert(entity)
        try modelContext.save()
    }
}
