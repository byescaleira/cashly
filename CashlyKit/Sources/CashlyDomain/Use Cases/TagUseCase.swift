//
//  TagUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

public protocol TagUseCase: Sendable {
    func getTag(id: String) async throws -> Tag?
    func getTags() async throws -> [Tag]
    func getTags(users: [String]?) async throws -> [Tag]
    func removeTag(id: String) async throws
    func removeTags() async throws
    func addTag(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws
}
