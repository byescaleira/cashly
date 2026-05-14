//
//  RecurringTransactionEntity.swift
//  CashlyKit
//
//  K12. SwiftData entity backing RecurringTransactionTemplate.
//  Schema joins V2 — only an additive change, lightweight migration.
//

import Foundation
import SwiftData

@Model
public class RecurringTransactionEntity {
    public var id: String = ""
    public var summary: String = ""
    public var amount: Double = 0
    public var budgetId: String = ""
    public var categoryId: String = ""
    public var startDate: TimeInterval = 0
    public var cadence: String = "monthly"
    public var kind: Int = 0
    public var lastMaterializedAt: TimeInterval?

    public init(
        id: String,
        summary: String,
        amount: Double,
        budgetId: String,
        categoryId: String,
        startDate: TimeInterval,
        cadence: String,
        kind: Int,
        lastMaterializedAt: TimeInterval?
    ) {
        self.id = id
        self.summary = summary
        self.amount = amount
        self.budgetId = budgetId
        self.categoryId = categoryId
        self.startDate = startDate
        self.cadence = cadence
        self.kind = kind
        self.lastMaterializedAt = lastMaterializedAt
    }
}
