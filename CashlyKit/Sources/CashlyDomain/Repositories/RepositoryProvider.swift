public protocol RepositoryProvider: Sendable {
    var changes: any StorageChangeFeed { get }
    func repositories(for userID: String?) -> Repositories
}
