//
import Foundation
//  MockAdapterActor.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain

actor MockAdapterActor: AdapterUseCase {
    let budgets = Budget.mocks
    let users = User.mocks
    let categories = CashlyDomain.Category.mocks
    let participants = Participant.mocks

    func budgetAdapted(
        id: String,
        amount: Double,
        category: String,
        date: Int,
        summary: String
    ) async throws -> Budget? {
        guard let category = categories.first(where: { $0.id == category }) else { return nil }
        return Budget(
            id: id,
            amount: amount,
            category: category,
            date: date,
            summary: summary
        )
    }

    func categoryAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> CashlyDomain.Category? {
        guard let user = users.first(where: { $0.id == user }) else { return nil }
        return Category(
            id: id,
            user: user,
            name: name.capitalized,
            color: color,
            icon: icon
        )
    }

    func userAdapted(
        id: String,
        name: String,
        photo: String
    ) async throws -> User {
        User(
            id: id,
            name: name,
            photo: photo
        )
    }

    func tagAdapted(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String
    ) async throws -> Tag? {
        guard let user = users.first(where: { $0.id == user }) else { return nil }
        return Tag(
            id: id,
            user: user,
            name: name,
            color: color,
            icon: icon
        )
    }

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
        guard let budget = budgets.first(where: { $0.id == budget }),
              let status = TransactionStatus(rawValue: status)
        else { return nil }
        let participants = self.participants.filter { participants.contains($0.id) }
        let resolvedCategory = category.flatMap { id in
            categories.first(where: { $0.id == id })
        }

        return CashlyDomain.Transaction(
            id: id,
            participants: participants,
            budget: budget,
            amount: amount,
            date: date,
            summary: summary,
            status: status,
            splitMode: TransactionSplitMode(rawValue: splitMode ?? -1),
            splitValue: splitValue,
            paymentsPlan: paymentsPlan,
            kind: TransactionKind(rawValue: kind) ?? .expense,
            needsReview: needsReview,
            category: resolvedCategory
        )
    }

    func participantAdapted(
        id: String,
        user: String,
        splitMode: Int,
        splitValue: Double,
        status: Int,
        transaction: String
    ) async throws -> Participant? {
        guard let user = users.first(where: { $0.id == user }),
              let splitMode = TransactionSplitMode(rawValue: splitMode),
              let status = TransactionStatus(rawValue: status)
        else { return nil }
        return Participant(
            id: id,
            user: user,
            splitMode: splitMode,
            splitValue: splitValue,
            status: status,
            transaction: transaction
        )
    }
}
