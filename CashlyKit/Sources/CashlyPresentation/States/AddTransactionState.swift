//
//  AddTransactionState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

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
    public var isNew: Bool
    public var error: CashlyError?
    
    public var canSave: Bool {
        user != nil &&
        category != nil &&
        budget != nil &&
        amount > .zero &&
        summary.trimmingCharacters(in: .whitespacesAndNewlines).count > 3 &&
        (participants.isEmpty ? true : isValidParticipants)
    }
    
    private var isValidParticipants: Bool {
        let valueParticipants: Double = participants.compactMap {
            let value = $0.splitMode.value(
                splitValue: $0.splitValue,
                amount: amount
            )
            return value
        }.reduce(.zero, +)
        let value = splitValue ?? .zero
        let total = valueParticipants + value
        return Int(total - amount) == .zero
    }
    
    public var categories: [Category] {
        budgets.map(\.category)
    }
    
    public var category: Category? {
        budget?.category
    }
    
    public var user: User? {
        category?.user
    }
    
    public init(
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
        isNew: Bool = true,
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
        self.isNew = isNew
        self.error = error
    }
}
