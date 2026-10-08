import CashlyDomain
import Foundation
import SwiftData

public struct CashlyDataFactory: CashlyDataFactoryProtocol {
    public let modelContainer: ModelContainer
    public let userID: String?
    private let repository: CashlyRepository
    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.userID = nil
        self.repository = CashlyRepository(modelContainer: modelContainer)
    }
    private init(modelContainer: ModelContainer, repository: CashlyRepository, userID: String?) {
        self.modelContainer = modelContainer
        self.repository = repository
        self.userID = userID
    }
    public static func make(inMemory: Bool = false, cloudSync: Bool = true, storeURL: URL? = nil)
        throws -> Self
    {
        let schema = Schema(versionedSchema: CashlySchemaV3.self)
        let database: ModelConfiguration.CloudKitDatabase =
            inMemory || !cloudSync ? .none : .private("iCloud.cashly")
        let configuration: ModelConfiguration
        if let storeURL {
            configuration = ModelConfiguration(
                schema: schema, url: storeURL, cloudKitDatabase: database)
        } else {
            configuration = ModelConfiguration(
                schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: database)
        }
        return try CashlyMetrics.measure("OpenStore") {
            Self(
                modelContainer: try ModelContainer(
                    for: schema, migrationPlan: CashlyMigrationPlan.self,
                    configurations: configuration))
        }
    }
    public func scoped(to userID: String?) -> any CashlyDataFactoryProtocol {
        Self(modelContainer: modelContainer, repository: repository, userID: userID)
    }
    private var gateway: CashlyScopedRepository {
        CashlyScopedRepository(repository: repository, userID: userID)
    }
    public func makeSnapshotUseCase() -> any SnapshotUseCase { gateway }
    public func makeDashboardUseCase() -> any DashboardUseCase { gateway }
    public func makeDataChangeUseCase() -> any DataChangeUseCase { repository.changeHub }
    public func makeBudgetUseCase() -> any BudgetUseCase { gateway }
    public func makeCategoryUseCase() -> any CategoryUseCase { gateway }
    public func makeUserUseCase() -> any UserUseCase { gateway }
    public func makeTransactionUseCase() -> any TransactionUseCase { gateway }
    public func makeTagUseCase() -> any TagUseCase { gateway }
}
