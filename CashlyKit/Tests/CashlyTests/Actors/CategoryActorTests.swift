//
//  CategoryActorTests.swift
//  CashlyKit
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock

@Suite("Category Use Case", .tags(.unit, .data, .local))
actor CategoryActorTests {
    @MainActor let suite = CommonTestSuite()

    @Test("Add then fetch category roundtrips entity")
    func roundtrip() async throws {
        let category: CashlyDomain.Category = .mock

        try await suite.categoryUseCase.addCategory(
            id: category.id,
            user: category.user.id,
            name: category.name,
            color: category.color,
            icon: category.icon
        )

        let fetched = try await suite.categoryUseCase.getCategory(id: category.id)
        suite.assertEqual(category, fetched)
    }

    @Test("getCategory returns nil for unknown id")
    func getCategoryUnknown() async throws {
        let result = try await suite.categoryUseCase.getCategory(id: "nope-\(UUID().uuidString)")
        #expect(result == nil)
    }

    @Test("addCategory upserts on conflicting id")
    func upsert() async throws {
        let category: CashlyDomain.Category = .mock
        try await suite.categoryUseCase.addCategory(
            id: category.id,
            user: category.user.id,
            name: "Original",
            color: category.color,
            icon: category.icon
        )
        try await suite.categoryUseCase.addCategory(
            id: category.id,
            user: category.user.id,
            name: "Updated",
            color: category.color,
            icon: category.icon
        )
        let fetched = try await suite.categoryUseCase.getCategory(id: category.id)
        #expect(fetched?.name == "Updated")
    }
}
