//
//  CategoryUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public protocol CategoryUseCase: Sendable {
    func getCategory(id: String) async throws -> Category?
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
        icon: String
    ) async throws
}
