//
//  AddTransactionState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import Foundation
import CashlyDomain

public struct AddTransactionState: CashlyState {
    public var isLoading: Bool
    public var budgets: [Budget]
    public var id: String
    public var participants: [Participant]
    public var budget: Budget?
    public var amount: Double
    public var date: Date
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var tags: [Tag]
    public var isNew: Bool
    public var isSaved: Bool = false
    public var installmentIsOn: Bool
    public var installmentPlan: Int
    public var error: CashlyError?

    public var canSave: Bool {
        user != nil &&
        category != nil &&
        budget != nil &&
        amount > .zero &&
        summary.trimmingCharacters(in: .whitespacesAndNewlines).count > 3 &&
        (participants.isEmpty ? true : isValidParticipants)
    }

    public var isValidParticipants: Bool {
        let valueParticipants: Double = participants.compactMap {
            let value = $0.splitMode.value(
                splitValue: $0.splitValue,
                amount: amount
            )
            return value
        }.reduce(.zero, +)
        let value = splitValue ?? .zero < .zero ? .zero : splitValue ?? .zero
        let total = valueParticipants + value
        return Int(total - amount) == .zero
    }

    public var categories: [CashlyDomain.Category] {
        budgets.map(\.category)
    }

    public var category: CashlyDomain.Category? {
        budget?.category
    }

    public var user: User? {
        category?.user
    }

    public var summaryTags: [Tag] {
        let summary = summary.lowercased()
        return tags.filter { summary.contains($0.name.lowercased()) }
    }

    private init(
        isLoading: Bool = true,
        budgets: [Budget] = [],
        id: String = UUID().uuidString,
        participants: [Participant] = [],
        budget: Budget? = nil,
        amount: Double = .zero,
        date: Date = .now,
        summary: String = "",
        status: TransactionStatus = .settled,
        splitMode: TransactionSplitMode? = nil,
        splitValue: Double? = nil,
        tags: [Tag] = [],
        isNew: Bool = true,
        installmentIsOn: Bool = false,
        installmentPlan: Int = 1,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.budgets = budgets
        self.id = id
        self.participants = participants
        self.budget = budget
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.tags = tags
        self.isNew = isNew
        self.installmentIsOn = installmentIsOn
        self.installmentPlan = installmentPlan
        self.error = error
    }

    public static func new() -> AddTransactionState {
        AddTransactionState()
    }

    public static func new(budget: Budget, date: Date) -> AddTransactionState {
        AddTransactionState(budget: budget, date: date)
    }

    public static func edit(id: String) -> AddTransactionState {
        AddTransactionState(id: id, isNew: false)
    }
}
