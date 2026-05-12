//
//  MainState.swift
//  CashlyKit
//

import CashlyDomain

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

    /// Cache populated by `MainReducer` whenever `transactions`,
    /// `budgets` or `tags` change. Computed views (HomeScreen,
    /// TransactionScreen, BalanceView) read from here so body
    /// evaluation never re-iterates the whole transaction list.
    /// See `recomputeDerived()` in MainState+Derived.
    public var transactionsAmountByCategory: [String: Double] = [:]
    public var transactionsAmountByBudget: [String: Double] = [:]
    public var transactionsAmountByTag: [String: Double] = [:]
    public var budgetsAmountByCategory: [String: Double] = [:]
    public var transactionSectionsCache: [[CashlyDomain.Transaction]] = []
    public var biggestTagsCache: [Tag] = []

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
