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
        summary: String
    ) async throws -> Budget?

    func categoryAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
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
        needsReview: Bool
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
