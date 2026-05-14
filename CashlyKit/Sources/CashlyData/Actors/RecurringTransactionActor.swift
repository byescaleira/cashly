//
//  RecurringTransactionActor.swift
//  CashlyKit
//
//  K12. SwiftData actor backing the RecurringTransactionUseCase.
//

import Foundation
import CashlyDomain
import SwiftData

@ModelActor
public actor RecurringTransactionActor: RecurringTransactionUseCase {
    public func templates() async throws -> [RecurringTransactionTemplate] {
        let descriptor = FetchDescriptor<RecurringTransactionEntity>(
            sortBy: [.init(\.startDate, order: .forward)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.compactMap(Self.toDomain)
    }

    public func add(_ template: RecurringTransactionTemplate) async throws {
        let predicate: Predicate<RecurringTransactionEntity> = #Predicate { $0.id == template.id }
        let descriptor = FetchDescriptor<RecurringTransactionEntity>(predicate: predicate)
        let entity = try modelContext.fetch(descriptor).first ?? RecurringTransactionEntity(
            id: template.id,
            summary: template.summary,
            amount: template.amount,
            budgetId: template.budgetId,
            categoryId: template.categoryId,
            startDate: template.startDate,
            cadence: template.cadence.rawValue,
            kind: template.kind.rawValue,
            lastMaterializedAt: template.lastMaterializedAt
        )
        entity.id = template.id
        entity.summary = template.summary
        entity.amount = template.amount
        entity.budgetId = template.budgetId
        entity.categoryId = template.categoryId
        entity.startDate = template.startDate
        entity.cadence = template.cadence.rawValue
        entity.kind = template.kind.rawValue
        entity.lastMaterializedAt = template.lastMaterializedAt
        modelContext.insert(entity)
        try modelContext.save()
    }

    public func remove(id: String) async throws {
        let predicate: Predicate<RecurringTransactionEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<RecurringTransactionEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try modelContext.save()
    }

    public func materializeDue(
        now: Date,
        materialize: @Sendable (RecurringTransactionTemplate, TimeInterval) async throws -> Void
    ) async throws {
        let descriptor = FetchDescriptor<RecurringTransactionEntity>()
        let entities = try modelContext.fetch(descriptor)
        for entity in entities {
            guard let template = Self.toDomain(entity) else { continue }
            let due = template.instancesDue(now: now)
            for date in due {
                try await materialize(template, date)
            }
            if let latest = due.last {
                entity.lastMaterializedAt = latest
            }
        }
        try modelContext.save()
    }

    private static func toDomain(_ entity: RecurringTransactionEntity) -> RecurringTransactionTemplate? {
        guard let cadence = RecurringCadence(rawValue: entity.cadence),
              let kind = TransactionKind(rawValue: entity.kind)
        else { return nil }
        return RecurringTransactionTemplate(
            id: entity.id,
            summary: entity.summary,
            amount: entity.amount,
            budgetId: entity.budgetId,
            categoryId: entity.categoryId,
            startDate: entity.startDate,
            cadence: cadence,
            kind: kind,
            lastMaterializedAt: entity.lastMaterializedAt
        )
    }
}
