//
//  TransactionKind.swift
//  CashlyKit
//
//  Direction of money flow for a Transaction. Drives aggregation in
//  Insights, Budget.spent, and the lifecycle rules for loans.
//
//  Lifecycle nuance: ``loan`` counts as an expense while
//  ``TransactionStatus`` is one of the pending states. Once the
//  loan settles (`.settled`), the amount stops contributing to the
//  budget's spent total.
//

import Foundation

public enum TransactionKind: Int, CaseIterable, Sendable, Codable, Equatable {
    /// Money leaving the user's pocket. Default — every legacy
    /// transaction migrates as `.expense`.
    case expense = 0
    /// Money coming in. Never sums into spending charts.
    case income = 1
    /// Money lent out. Sums as expense until status is `.settled`;
    /// stops summing afterwards.
    case loan = 2

    public var summary: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        case .loan: return "Loan"
        }
    }

    public var icon: String {
        switch self {
        case .expense: return "arrow.up.right"
        case .income: return "arrow.down.left"
        case .loan: return "arrow.left.arrow.right"
        }
    }
}
