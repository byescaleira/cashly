//
//  MainState.swift
//  CashlyKit
//

import CashlyDomain
import PrismIntelligence

public struct MainState: CashlyState {
    public var isLoading: Bool
    public var filter: FilterState
    public var budgets: [Budget]
    public var categories: [CashlyDomain.Category]
    public var transactions: [CashlyDomain.Transaction]
    public var tags: [Tag]
    public var users: [User]
    public var user: User?

    public var predictedTransactionsAmount: Double

    public var error: CashlyError?

    public var intelligenceRouter: CashlyRouter<MainRoute> = .init()
    public var categoryRouter: CashlyRouter<MainRoute> = .init()
    public var homeRouter: CashlyRouter<MainRoute> = .init()
    public var transactionRouter: CashlyRouter<MainRoute> = .init()

    public init(
        isLoading: Bool = true,
        filter: FilterState = .init(),
        budgets: [Budget] = [],
        categories: [CashlyDomain.Category] = [],
        transactions: [CashlyDomain.Transaction] = [],
        tags: [Tag] = [],
        users: [User] = [],
        user: User? = nil,
        predictedTransactionsAmount: Double = .zero,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.filter = filter
        self.budgets = budgets
        self.categories = categories
        self.transactions = transactions
        self.tags = tags
        self.users = users
        self.user = user
        self.predictedTransactionsAmount = predictedTransactionsAmount
        self.error = error
    }
}
