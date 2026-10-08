import Foundation

public protocol UserUseCase: Sendable {
    func getUser(id: String) async throws -> User?
    func getUsers() async throws -> [User]
    func removeUser(id: String) async throws
    func removeUsers() async throws
    func addUser(
        id: String,
        name: String,
        photo: String
    ) async throws
}
