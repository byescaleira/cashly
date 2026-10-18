import CashlyDomain

struct LibraryUserRepository: UserRepository {
    let main: any UserRepository
    let shared: any UserRepository
    let directory: SharedDirectory

    func users() async throws -> [User] {
        let personal = try await main.users()
        let joined = try await shared.users().map(SharedUserRepository.mark)
        directory.replace(with: joined.map(\.id))
        return personal + joined
    }

    func user(id: String) async throws -> User? {
        if let user = try await main.user(id: id) { return user }
        guard let user = try await shared.user(id: id) else { return nil }
        directory.insert(user.id)
        return SharedUserRepository.mark(user)
    }

    func save(_ user: User) async throws {
        if user.isShared || directory.contains(user.id) {
            try await shared.save(user)
        } else {
            try await main.save(user)
        }
    }

    func delete(id: String) async throws {
        guard !directory.contains(id) else { throw CashlyError.onRemove }
        try await main.delete(id: id)
    }
}

struct SharedUserRepository: UserRepository {
    let base: any UserRepository
    var profileID: String?

    static func mark(_ user: User) -> User {
        var value = user
        value.isShared = true
        return value
    }

    func users() async throws -> [User] {
        try await base.users().filter { profileID == nil || $0.id == profileID }.map(Self.mark)
    }

    func user(id: String) async throws -> User? { try await base.user(id: id).map(Self.mark) }

    func save(_ user: User) async throws { try await base.save(user) }

    func delete(id: String) async throws { throw CashlyError.onRemove }
}
