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
            CashlySchemaV1.self
            // Future: CashlySchemaV2.self appended here.
        ]
    }

    public static var stages: [MigrationStage] {
        [
            // J2 adds:
            // .custom(
            //     fromVersion: CashlySchemaV1.self,
            //     toVersion: CashlySchemaV2.self,
            //     willMigrate: backfillTransactionCategoryAndKind,
            //     didMigrate: nil
            // )
        ]
    }
}
