//
//  CashlySchemaV2.swift
//  CashlyKit
//
//  ADR-0009 J2c. Adds `kind` + `needsReview` columns to
//  TransactionEntity. The migration from V1 is lightweight (only
//  new columns with defaults) — SwiftData applies the defaults
//  automatically when materializing pre-J2 rows.
//

import Foundation
import SwiftData

public enum CashlySchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self
        ]
    }
}
