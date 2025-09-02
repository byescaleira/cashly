//
//  UserUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

public protocol UserUseCase: Sendable {
    func getUser(id: UUID) async throws -> User?
    func getUsers() async throws -> [User]
    func removeUser(id: UUID) async throws
    func removeUsers() async throws
    func addUser(
        id: UUID,
        name: String,
        photo: Data?
    ) async throws
}
