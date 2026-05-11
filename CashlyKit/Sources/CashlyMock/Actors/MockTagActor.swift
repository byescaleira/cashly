//
//  MockTagActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import SwiftData

actor MockTagActor: TagUseCase {
    var tags = Tag.mocks
    let users = User.mocks
    
    init() {}
    
    func getTag(id: String) async throws -> Tag? {
        tags.first(where: { $0.id == id })
    }
    
    func getTags() async throws -> [Tag] {
        tags
    }
    
    func getTags(users: [String]?) async throws -> [Tag] {
        tags
    }
    
    func removeTag(id: String) async throws {
        guard let tag = try await getTag(id: id),
              let index = tags.firstIndex(of: tag)
        else { return }
        let _ = tags.remove(at: index)
    }
    
    func removeTags() async throws {
        tags = []
    }
    
    func addTag(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws {
        guard let user = users.first(where: { $0.id == user }) else { return }
        let tag = Tag(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon
        )
        tags.append(tag)
    }
}

