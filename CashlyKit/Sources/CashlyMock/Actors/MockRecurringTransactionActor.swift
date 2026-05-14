//
//  MockRecurringTransactionActor.swift
//  CashlyKit
//

import Foundation
import CashlyDomain

public actor MockRecurringTransactionActor: RecurringTransactionUseCase {
    private var stored: [RecurringTransactionTemplate] = []

    public init() {}

    public func templates() async throws -> [RecurringTransactionTemplate] {
        stored
    }

    public func add(_ template: RecurringTransactionTemplate) async throws {
        if let index = stored.firstIndex(where: { $0.id == template.id }) {
            stored[index] = template
        } else {
            stored.append(template)
        }
    }

    public func remove(id: String) async throws {
        stored.removeAll { $0.id == id }
    }

    public func materializeDue(
        now: Date,
        materialize: @Sendable (RecurringTransactionTemplate, TimeInterval) async throws -> Void
    ) async throws {
        for index in stored.indices {
            let due = stored[index].instancesDue(now: now)
            for date in due {
                try await materialize(stored[index], date)
            }
            if let latest = due.last {
                stored[index].lastMaterializedAt = latest
            }
        }
    }
}
