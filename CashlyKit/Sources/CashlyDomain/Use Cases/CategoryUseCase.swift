//
//  CategoryUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public protocol CategoryUseCase: Sendable {
    func getCategory(id: String) async throws -> CashlyDomain.Category?
    func getCategories() async throws -> [Category]
    func getCategories(
        ids: [String]?,
        users: [String]?
    ) async throws -> [Category]
    func removeCategory(id: String) async throws
    func removeCategories() async throws
    func addCategory(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String,
        order: Int
    ) async throws

    /// K8: persists the user's drag-reordered list. The default
    /// implementation calls `addCategory` upsert-style for each id
    /// with the new order index.
    func reorderCategories(ids: [String]) async throws
}

public extension CategoryUseCase {
    /// K8 back-compat: pre-K8 callsites pass five params, defaulting
    /// order to 0 so the next reorder fixes the index.
    func addCategory(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws {
        try await addCategory(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon,
            order: 0
        )
    }
}
