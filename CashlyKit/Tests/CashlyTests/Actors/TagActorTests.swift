//
//  TagActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("Tag Use Case", .tags(.unit, .data, .local))
actor TagActorTests {
    @MainActor let suite = CommonTestSuite()

    @Test("Add then fetch tag roundtrips")
    func roundtrip() async throws {
        let user: User = .mock
        try await suite.userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)

        let tagId = UUID().uuidString
        try await suite.tagUseCase.addTag(
            id: tagId,
            user: user.id,
            name: "Coffee",
            color: "#8B4513",
            icon: "cup.and.saucer"
        )

        let fetched = try await suite.tagUseCase.getTag(id: tagId)
        #expect(fetched?.id == tagId)
        #expect(fetched?.name == "Coffee")
        #expect(fetched?.color == "#8B4513")
        #expect(fetched?.icon == "cup.and.saucer")
        #expect(fetched?.user.id == user.id)
    }

    @Test("getTag returns nil for unknown")
    func unknown() async throws {
        let result = try await suite.tagUseCase.getTag(id: "ghost-\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("getTags returns all stored tags")
    func getAll() async throws {
        let user: User = .mock
        try await suite.userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)

        for i in 0 ..< 3 {
            try await suite.tagUseCase.addTag(
                id: "tag-\(i)",
                user: user.id,
                name: "Tag\(i)",
                color: "#000000",
                icon: "tag"
            )
        }
        let all = try await suite.tagUseCase.getTags()
        #expect(all.count >= 3)
    }

    @Test("removeTag drops the row")
    func remove() async throws {
        let user: User = .mock
        try await suite.userUseCase.addUser(id: user.id, name: user.name, photo: user.photo)

        let tagId = UUID().uuidString
        try await suite.tagUseCase.addTag(
            id: tagId, user: user.id,
            name: "Doomed", color: "#000", icon: "x"
        )
        try await suite.tagUseCase.removeTag(id: tagId)
        let result = try await suite.tagUseCase.getTag(id: tagId)
        #expect(result == nil)
    }
}
