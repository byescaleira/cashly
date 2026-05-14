//
//  AdapterUseCase.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import Foundation

public protocol AdapterUseCase: Sendable {
    func budgetAdapted(
        id: String,
        amount: Double,
        category: String,
        date: Int,
        summary: String,
        rollsOver: Bool
    ) async throws -> Budget?

    func categoryAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String,
        order: Int
    ) async throws -> CashlyDomain.Category?

    func userAdapted(
        id: String,
        name: String,
        photo: String
    ) async throws -> User

    func transactionAdapted(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: Int,
        needsReview: Bool,
        category: String?,
        attachmentPath: String?
    ) async throws -> Transaction?

    func tagAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> Tag?

    func participantAdapted(
        id: String,
        user: String,
        splitMode: Int,
        splitValue: Double,
        status: Int,
        transaction: String
    ) async throws -> Participant?
}

public extension AdapterUseCase {
    /// K8 back-compat: pre-K8 callsites don't pass order.
    func categoryAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> CashlyDomain.Category? {
        try await categoryAdapted(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon,
            order: 0
        )
    }

    /// K9 back-compat shim: pre-K9 callsites don't pass rollsOver.
    func budgetAdapted(
        id: String,
        amount: Double,
        category: String,
        date: Int,
        summary: String
    ) async throws -> Budget? {
        try await budgetAdapted(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary,
            rollsOver: false
        )
    }

    /// Back-compat shim for callsites that don't yet pass `category`.
    /// New code should always pass the FK explicitly.
    func transactionAdapted(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: Int,
        needsReview: Bool
    ) async throws -> Transaction? {
        try await transactionAdapted(
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
            category: nil,
            attachmentPath: nil
        )
    }

    /// K10 back-compat: pre-K10 callsites don't pass attachmentPath.
    func transactionAdapted(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int?,
        splitValue: Double?,
        paymentsPlan: Int?,
        kind: Int,
        needsReview: Bool,
        category: String?
    ) async throws -> Transaction? {
        try await transactionAdapted(
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
            category: category,
            attachmentPath: nil
        )
    }
}
