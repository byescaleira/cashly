//
//  AddTransactionAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import Foundation
import CashlyDomain

public enum AddTransactionAction: CashlyAction, CashlyReplaceableAction {
    public typealias State = AddTransactionState

    case fetch
    case save
    case remove
    case stopLoading
    case update(
        budgets: [Budget],
        id: String,
        participants: [Participant],
        budget: Budget?,
        amount: Double,
        date: Date,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        tags: [Tag],
        isNew: Bool,
        installmentIsOn: Bool,
        installmentPlan: Int
    )
    case saved
    case error(CashlyError)
    case replace(AddTransactionState)
}
