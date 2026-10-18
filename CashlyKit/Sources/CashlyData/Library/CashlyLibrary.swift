import CashlyDomain
import Foundation

public struct CashlyLibrary: RepositoryProvider {
    public let main: CashlyDatabase
    public let shared: CashlyDatabase
    let directory = SharedDirectory()

    public init(main: CashlyDatabase, shared: CashlyDatabase) {
        self.main = main
        self.shared = shared
    }

    public static func open(cloudSync: Bool) throws -> CashlyLibrary {
        let main = try CashlyDatabase.open(cloudSync: cloudSync)
        let shared = try CashlyDatabase.open(cloudSync: false, storeURL: sharedStoreURL)
        return CashlyLibrary(main: main, shared: shared)
    }

    public static func inMemory() throws -> CashlyLibrary {
        CashlyLibrary(
            main: try CashlyDatabase.open(inMemory: true),
            shared: try CashlyDatabase.open(inMemory: true))
    }

    public static var sharedStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "Sharing.store")
    }

    public static var sharingStateDirectory: URL {
        URL.applicationSupportDirectory.appending(path: "Sharing", directoryHint: .isDirectory)
    }

    public var changes: any StorageChangeFeed {
        MergedChangeFeed(feeds: [main.changes, shared.changes])
    }

    public func prepare() async {
        directory.replace(with: (try? await shared.store.sharedProfileIDs()) ?? [])
    }

    public func isShared(_ userID: String) -> Bool { directory.contains(userID) }

    public func repositories(for userID: String?) -> Repositories {
        guard let userID else {
            let base = main.repositories(for: nil)
            return base.replacing(
                users: LibraryUserRepository(
                    main: base.users, shared: shared.repositories(for: nil).users,
                    directory: directory))
        }
        guard directory.contains(userID) else { return main.repositories(for: userID) }
        let base = shared.repositories(for: userID)
        return base.replacing(users: SharedUserRepository(base: base.users, profileID: userID))
    }
}

extension Repositories {
    func replacing(users: any UserRepository) -> Repositories {
        Repositories(
            userID: userID, users: users, categories: categories, tags: tags, budgets: budgets,
            transactions: transactions, dashboard: dashboard, game: game, captures: captures)
    }
}
