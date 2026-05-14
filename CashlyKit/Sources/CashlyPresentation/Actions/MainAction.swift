//
//  MainAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import Foundation
import CashlyDomain

public enum MainAction: CashlyAction, CashlyReplaceableAction {
    public typealias State = MainState

    case fetch
    case stopLoading
    case update(
        filter: FilterState,
        budgets: [Budget],
        categories: [CashlyDomain.Category],
        transactions: [CashlyDomain.Transaction],
        tags: [Tag],
        users: [User],
        user: User?,
        predictedTransactionsAmount: Double
    )
    case removeTag(Tag)
    case removeTransaction(CashlyDomain.Transaction)
    case removeTransactions(Set<CashlyDomain.Transaction>)
    case selectUser
    case fetchPredictions
    case subscriptionUpdated(SubscriptionStatus)
    case reachabilityUpdated(ReachabilityStatus)
    case syncStatusUpdated(SyncStatus)
    /// Wipe local data (current user pointer + every entity row).
    /// Behaves like a sign-out / factory-reset for offline storage —
    /// remote CloudKit copies follow on next sync.
    case wipeAllData
    /// K5: marks a loan transaction as settled so it stops counting
    /// against expense totals (and disappears from the pending loans
    /// list).
    case settleLoan(CashlyDomain.Transaction)
    /// K14: ingest a CSV file the user picked from disk. The
    /// middleware uses CashlyCSVImporter, maps rows onto the
    /// existing categories + budgets, and inserts new transactions.
    /// Rows that don't map to any category are skipped + summarised
    /// to the user via an error.
    case importCSV(URL)
    /// K14: outcome of an import — rows added vs rows skipped.
    case csvImportFinished(added: Int, skipped: Int)
    /// K8: persist the drag-reordered category list. UI passes the
    /// ids in the new order.
    case reorderCategories([String])
    case error(CashlyError)
    case replace(MainState)
}
