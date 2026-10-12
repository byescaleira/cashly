import Foundation
import SwiftData

public enum CashlySchemaV4: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(4, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [
            UserEntity.self, CategoryEntity.self, BudgetEntity.self, TagEntity.self,
            TransactionEntity.self, ParticipantEntity.self, GameEventEntity.self,
        ]
    }
}

public enum CashlyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [CashlySchemaV1.self, CashlySchemaV2.self, CashlySchemaV3.self, CashlySchemaV4.self]
    }
    public static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: CashlySchemaV1.self, toVersion: CashlySchemaV2.self),
            .lightweight(fromVersion: CashlySchemaV2.self, toVersion: CashlySchemaV3.self),
            .lightweight(fromVersion: CashlySchemaV3.self, toVersion: CashlySchemaV4.self),
        ]
    }
}
