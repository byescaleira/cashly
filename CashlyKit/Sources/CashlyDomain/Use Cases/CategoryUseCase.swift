//
//  CategoryUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public protocol CategoryUseCase: Sendable {
    func getCategory(id: UUID) async throws -> Category?
    func getCategories() async throws -> [Category]
    func removeCategory(id: UUID) async throws
    func removeCategories() async throws
    func addCategory(
        id: UUID,
        name: String,
        color: String,
        icon: String
    ) async throws
}
