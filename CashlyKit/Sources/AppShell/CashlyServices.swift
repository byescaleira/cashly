import CashlyData
import CashlyDomain
import FeatureCore
import Foundation

@MainActor
public final class CashlyServices {
    public static let shared = CashlyServices()
    private var opening: Task<CashlyDatabase, any Error>?

    private init() {}

    public func database(cloudSync: Bool) async throws -> CashlyDatabase {
        if let opening {
            do { return try await opening.value } catch { self.opening = nil }
        }
        let task = Task.detached(priority: .userInitiated) {
            try CashlyDatabase.open(cloudSync: cloudSync)
        }
        opening = task
        do {
            return try await task.value
        } catch {
            opening = nil
            throw error
        }
    }

    public func workspace(
        cloudSync: Bool, preference: UserPreference = .standard
    ) async throws -> (Repositories, User) {
        let database = try await database(cloudSync: cloudSync)
        let users = try await database.repositories(for: nil).users.users()
        guard let user = users.first(where: { $0.id == preference.selectedUserID }) ?? users.first
        else { throw CashlyError.missingRecord }
        return (database.repositories(for: user.id), user)
    }
}
