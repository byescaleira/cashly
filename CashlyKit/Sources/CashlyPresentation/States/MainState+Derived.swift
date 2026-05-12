//
//  MainState+Derived.swift
//  CashlyKit
//
//  Pre-computes the per-id totals and groupings consumed by HomeScreen
//  / TransactionScreen / BalanceView. Called from `MainReducer` on
//  `.update`, `.removeTag`, `.removeTransaction(s)` and `.replace`, so
//  view bodies never iterate the whole transaction list.
//

import Foundation
import CashlyDomain
import CashlyResource

extension MainState {
    /// Amount actually attributable to the transaction given splits and
    /// installments. Same rule used by every old computed property.
    private static func effectiveAmount(_ transaction: CashlyDomain.Transaction) -> Double {
        if !transaction.participants.isEmpty {
            return transaction.splitValue ?? .zero
        }
        if let plan = transaction.paymentsPlan, plan > 0 {
            return transaction.amount / plan.double
        }
        return transaction.amount
    }

    public mutating func recomputeDerived() {
        var byCategory: [String: Double] = [:]
        var byBudget: [String: Double] = [:]
        var byTagId: [String: Double] = [:]

        // Tag lookup once. Comparing summaries against lowercased tag
        // names happens N × M times so we lowercase tag names a single
        // time, not per-transaction.
        let lowercasedTags = tags.map { ($0.id, $0.name.lowercased()) }

        for transaction in transactions {
            let amount = Self.effectiveAmount(transaction)
            byCategory[transaction.budget.category.id, default: .zero] += amount
            byBudget[transaction.budget.id, default: .zero] += amount

            let summary = transaction.summary.lowercased()
            for (tagId, lowercasedName) in lowercasedTags {
                if summary.contains(lowercasedName) {
                    byTagId[tagId, default: .zero] += amount
                }
            }
        }

        var budgetsByCategory: [String: Double] = [:]
        for budget in budgets {
            budgetsByCategory[budget.category.id, default: .zero] += budget.amount
        }

        self.transactionsAmountByCategory = byCategory
        self.transactionsAmountByBudget = byBudget
        self.transactionsAmountByTag = byTagId
        self.budgetsAmountByCategory = budgetsByCategory

        // Sections: group by sort-pattern date string, descending.
        let grouped = Dictionary(grouping: transactions) { transaction in
            transaction.date.date.cashly(with: .sortPattern)
        }
        self.transactionSectionsCache = grouped
            .sorted { $0.key > $1.key }
            .map(\.value)

        // Biggest tags (top 5 by total amount).
        self.biggestTagsCache = tags
            .compactMap { tag -> (Tag, Double)? in
                guard let total = byTagId[tag.id], total > 0 else { return nil }
                return (tag, total)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map(\.0)
    }
}
