//
//  TransactionUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import Foundation

public protocol TransactionUseCase: Sendable {
    func getTransaction(id: String) async throws -> Transaction?
    func getTransactions() async throws -> [Transaction]
    func getTransactions(
        budgets: [String]?,
        tags: [String]?,
        statuses: [Int]?,
        participants: [String]?,
        date: Date?
    ) async throws -> [Transaction]
    func removeTransaction(id: String) async throws
    func removeTransactions(ids: Set<String>) async throws
    func removeTransactions() async throws
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget?,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: TransactionKind,
        needsReview: Bool,
        category: CashlyDomain.Category
    ) async throws
}

public extension TransactionUseCase {
    /// Back-compat wrapper. Pre-J2 callsites still pass the nine-param
    /// (Budget-only) shape; defaults route the new fields to .expense
    /// and derive category from the budget.
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) async throws {
        try await addTransaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: splitMode,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan,
            kind: .expense,
            needsReview: false,
            category: budget.category
        )
    }

    /// Eleven-param shim — keeps J2b callsites compiling after the
    /// J5 protocol bump (which made budget optional + category
    /// required).
    func addTransaction(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: TransactionKind,
        needsReview: Bool
    ) async throws {
        try await addTransaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: splitMode,
            splitValue: splitValue,
            paymentsPlan: paymentsPlan,
            kind: kind,
            needsReview: needsReview,
            category: budget.category
        )
    }
}
