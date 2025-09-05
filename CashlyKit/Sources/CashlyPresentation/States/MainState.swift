//
//  MainState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
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
    public var error: CashlyError?
    
    public init(
        isLoading: Bool = true,
        filter: FilterState = .init(),
        budgets: [Budget] = [],
        categories: [CashlyDomain.Category] = [],
        transactions: [CashlyDomain.Transaction] = [],
        tags: [Tag] = [],
        users: [User] = [],
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.filter = filter
        self.budgets = budgets
        self.categories = categories
        self.transactions = transactions
        self.tags = tags
        self.users = users
        self.error = error
    }
    
    public func transactionsAmount(for category: CashlyDomain.Category) -> Double {
        transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.budget.category.id == category.id else { return partialResult }
            return partialResult + transaction.amount
        }
    }
    
    public func budgetsAmount(for category: CashlyDomain.Category) -> Double {
        budgets.reduce(.zero) { partialResult, budget in
            guard budget.category.id == category.id else { return partialResult }
            return partialResult + budget.amount
        }
    }
    
    public func budget(for category: CashlyDomain.Category) -> Budget? {
        budgets.last(where: { $0.category.id == category.id })
    }
    
    public var categoriesWithoutBudgets: [CashlyDomain.Category] {
        var categories = [CashlyDomain.Category]()
        for category in self.categories {
            if budget(for: category) == nil {
                categories.append(category)
            }
        }
        return categories
    }
    
    public var budgetsAmount: Double {
        budgets.reduce(.zero) { partialResult, budget in
            partialResult + budget.amount
        }
    }
    
    public var transactionsAmount: Double {
        transactions.reduce(.zero) { partialResult, transaction in
            partialResult + transaction.amount
        }
    }
    
    public var variation: Double {
        transactionsAmount / budgetsAmount
    }
    
    public var warningCategories: [CashlyDomain.Category] {
        var categories = [(CashlyDomain.Category, Double)]()
        for category in self.categories {
            let variation = categoryVariation(category: category)
            if variation >= 0.8 {
                categories.append((category, variation))
            }
        }
        return categories.sorted(by: \.1, using: >).prefix(5).map(\.0)
    }
    
    public func categoryVariation(category: CashlyDomain.Category, amount: Double = .zero) -> Double {
        let transactionsAmount = transactionsAmount(for: category) + amount
        let budgetsAmount = budgetsAmount(for: category)
        return transactionsAmount / budgetsAmount
    }
    
    public func categoryRemainingAmount(category: CashlyDomain.Category) -> Double {
        budgetsAmount(for: category) - transactionsAmount(for: category)
    }
}
