//
//  CashlySchemaV3.swift
//  CashlyKit
//
//  K12. Adds RecurringTransactionEntity to the model graph.
//  Lightweight migration covers the new table — SwiftData creates
//  it empty on first launch of upgraded builds.
//

import Foundation
import SwiftData

public enum CashlySchemaV3: VersionedSchema {
    public static let versionIdentifier = Schema.Version(3, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            BudgetEntity.self,
            CategoryEntity.self,
            TransactionEntity.self,
            UserEntity.self,
            TagEntity.self,
            ParticipantEntity.self,
            RecurringTransactionEntity.self
        ]
    }
}
