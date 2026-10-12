import CashlyData
import CashlyDomain
import FeatureCore
import FeatureSettings
import FeatureStore
import Foundation
import Observation

@MainActor @Observable
public final class CashlyServices {
    public static let shared = CashlyServices()
    public var pendingURL: URL?
    @ObservationIgnored private var opening: Task<CashlyDatabase, any Error>?

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

    public static var launchCloudSync: Bool {
        #if targetEnvironment(simulator)
            false
        #else
            SettingsModel.launchSyncPreference
        #endif
    }

    public func canWrite() async -> Bool {
        guard FeatureFlags().isOn(.pro) else { return true }
        let plans = Set(ShopCatalog.plans.map(\.id))
        return await StoreKitClient().currentEntitlements().contains { transaction in
            plans.contains(transaction.productID) && transaction.revocationDate == nil
                && (transaction.expirationDate ?? .distantFuture) > .now
        }
    }

    public func workspace(
        cloudSync: Bool = CashlyServices.launchCloudSync, preference: UserPreference = .standard
    ) async throws -> (Repositories, User) {
        let database = try await database(cloudSync: cloudSync)
        let users = try await database.repositories(for: nil).users.users()
        guard let user = users.first(where: { $0.id == preference.selectedUserID }) ?? users.first
        else { throw CashlyError.missingRecord }
        return (database.repositories(for: user.id), user)
    }
}
