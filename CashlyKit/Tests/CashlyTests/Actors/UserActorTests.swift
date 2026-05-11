//
//  UserActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("User Use Case", .tags(.unit, .data, .local))
actor UserActorTests {
    @MainActor let suite = CommonTestSuite()

    @Test("Add then fetch user roundtrips")
    func roundtrip() async throws {
        let user = User(id: UUID().uuidString, name: "Alice", photo: "https://x/a.png")
        try await suite.userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)
        let fetched = try await suite.userUseCase.getUser(id: user.id)
        suite.assertEqual(user, fetched)
    }

    @Test("getUser returns nil for unknown id")
    func unknown() async throws {
        let result = try await suite.userUseCase.getUser(id: "ghost-\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("getUsers sorts by name ascending")
    func sortedByName() async throws {
        try await suite.userUseCase.addUser(id: "1", name: "Charlie", photo: "p")
        try await suite.userUseCase.addUser(id: "2", name: "Alice", photo: "p")
        try await suite.userUseCase.addUser(id: "3", name: "Bob", photo: "p")
        let users = try await suite.userUseCase.getUsers()
        #expect(users.map(\.name) == ["Alice", "Bob", "Charlie"])
    }

    @Test("removeUser drops the row")
    func removeDrops() async throws {
        let user = User(id: UUID().uuidString, name: "Doomed", photo: "p")
        try await suite.userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)
        try await suite.userUseCase.removeUser(id: user.id)
        let fetched = try await suite.userUseCase.getUser(id: user.id)
        #expect(fetched == nil)
    }

    @Test("addUser upserts on conflicting id")
    func upsert() async throws {
        let id = UUID().uuidString
        try await suite.userUseCase.addUser(id: id, name: "Original", photo: "p1")
        try await suite.userUseCase.addUser(id: id, name: "Updated", photo: "p2")
        let fetched = try await suite.userUseCase.getUser(id: id)
        #expect(fetched?.name == "Updated")
        #expect(fetched?.photo == "p2")
    }
}
