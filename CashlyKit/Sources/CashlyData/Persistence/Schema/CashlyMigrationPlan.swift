//
//  CashlyMigrationPlan.swift
//  CashlyKit
//
//  Central SchemaMigrationPlan registry. Today only V1 exists, so
//  the stages list is empty; J2 inserts a V1 → V2 lightweight stage
//  with a custom willMigrate backfill.
//

import Foundation
import SwiftData

public enum CashlyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            CashlySchemaV1.self,
            CashlySchemaV2.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
            // V1 → V2 is purely additive: TransactionEntity gains
            // `kind` + `needsReview`, both with @Model defaults.
            // SwiftData can apply this with a lightweight migration —
            // no custom backfill needed.
            .lightweight(fromVersion: CashlySchemaV1.self, toVersion: CashlySchemaV2.self)
        ]
    }
}
