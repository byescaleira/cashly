//
//  MockUserActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import RyzeFoundation
import CashlyDomain
import SwiftData

actor MockUserActor: UserUseCase {
    var users = User.mocks
    
    func getUser(id: String) async throws -> User? {
        users.first(where: { $0.id == id })
    }
    
    func getCurrentUser() async throws -> User? {
        users.first
    }
    
    func getUsers() async throws -> [User] {
        users
    }
    
    func removeUser(id: String) async throws {
        guard let user = try await getUser(id: id),
              let index = users.firstIndex(of: user)
        else { return }
        let _ = users.remove(at: index)
    }
    
    func removeUsers() async throws {
        users = []
    }
    
    func addUser(
        id: String,
        name: String,
        photo: String
    ) async throws {
        let user = User(
            id: id,
            name: name,
            photo: photo
        )
        users.append(user)
    }
}
