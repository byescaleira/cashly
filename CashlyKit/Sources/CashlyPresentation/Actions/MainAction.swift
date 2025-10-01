//
//  MainAction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 02/09/25.
//

import CashlyDomain

public enum MainAction: CashlyAction {
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
    case error(CashlyError)
}
