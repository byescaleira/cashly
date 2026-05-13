//
//  CashlySchemaV1.swift
//  CashlyKit
//
//  Initial released SwiftData schema. Wraps the entities that
//  shipped before the J-eixo transaction restructure so future
//  migrations can reference an explicit baseline. Schema body stays
//  identical to the pre-versioned setup — no shape change here.
//

import Foundation
import SwiftData

public enum CashlySchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

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
