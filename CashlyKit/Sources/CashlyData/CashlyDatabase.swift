import CashlyDomain
import Foundation
import SwiftData

public struct CashlyDatabase: RepositoryProvider {
    public static let cloudContainer = "iCloud.cashly"
    public let modelContainer: ModelContainer
    let store: CashlyStore

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        store = CashlyStore(modelContainer: modelContainer)
    }

    public static func open(inMemory: Bool = false, cloudSync: Bool = true, storeURL: URL? = nil)
        throws -> CashlyDatabase
    {
        let schema = Schema(versionedSchema: CashlySchemaV3.self)
        let database: ModelConfiguration.CloudKitDatabase =
            inMemory || !cloudSync ? .none : .private(cloudContainer)
        let configuration =
            if let storeURL {
                ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: database)
            } else {
                ModelConfiguration(
                    schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: database)
            }
        return try CashlyMetrics.measure("OpenStore") {
            CashlyDatabase(
                modelContainer: try ModelContainer(
                    for: schema, migrationPlan: CashlyMigrationPlan.self,
                    configurations: configuration))
        }
    }

    public var changes: any StorageChangeFeed { store.changeHub }

    public var backup: any BackupRepository { SwiftDataBackupRepository(store: store) }

    public func repositories(for userID: String?) -> Repositories {
        let scope = StoreScope(store: store, userID: userID)
        return Repositories(
            userID: userID,
            users: SwiftDataUserRepository(scope: scope),
            categories: SwiftDataCategoryRepository(scope: scope),
            tags: SwiftDataTagRepository(scope: scope),
            budgets: SwiftDataBudgetRepository(scope: scope),
            transactions: SwiftDataTransactionRepository(scope: scope),
            dashboard: SwiftDataDashboardRepository(scope: scope))
    }
}
