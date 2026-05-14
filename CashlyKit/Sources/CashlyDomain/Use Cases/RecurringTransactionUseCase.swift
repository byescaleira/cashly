//
//  RecurringTransactionUseCase.swift
//  CashlyKit
//
//  CRUD + materialization contract for recurring transaction
//  templates. The scheduler runs `materializeDue` at app launch +
//  on every BG refresh to produce missed instances since the last
//  pass; CRUD methods drive the manage-templates screen.
//

import Foundation

public protocol RecurringTransactionUseCase: Sendable {
    func templates() async throws -> [RecurringTransactionTemplate]
    func add(_ template: RecurringTransactionTemplate) async throws
    func remove(id: String) async throws
    /// Walks every template, produces past-due instances via
    /// `instancesDue(now:)`, hands them to the supplied closure
    /// (typically a TransactionUseCase.addTransaction call), then
    /// stamps the template with the new lastMaterializedAt.
    func materializeDue(
        now: Date,
        materialize: @Sendable (RecurringTransactionTemplate, TimeInterval) async throws -> Void
    ) async throws
}
