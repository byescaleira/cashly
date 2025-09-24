//
//  MainState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import CashlyDomain
import RyzeArchitecture

public struct MainState: CashlyState {
    public var isLoading: Bool
    public var filter: FilterState
    public var budgets: [Budget]
    public var categories: [CashlyDomain.Category]
    public var transactions: [CashlyDomain.Transaction]
    public var tags: [Tag]
    public var users: [User]
    public var user: User?
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
        self.error = error
    }
    
    public func participantsUser(
        transaction: String,
        splitMode: TransactionSplitMode?,
    ) -> [Participant] {
        users.map {
            Participant(
                id: UUID().uuidString,
                user: $0,
                splitMode: splitMode ?? .equal,
                splitValue: .zero,
                status: .settled,
                transaction: transaction
            )
        }.sorted(by: \.user.name)
    }
    
    public func transactionsAmount(for category: CashlyDomain.Category) -> Double {
        transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.budget.category.id == category.id else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }
    
    public func budgetsAmount(for category: CashlyDomain.Category) -> Double {
        budgets.reduce(.zero) { partialResult, budget in
            guard budget.category.id == category.id else { return partialResult }
            return partialResult + budget.amount
        }
    }
    
    public func transactionsAmount(for budget: Budget) -> Double {
        transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.budget.id == budget.id else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }
    
    public func transactionsAmount(for tag: Tag) -> Double {
        let tag = tag.name.lowercased()
        return transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.summary.lowercased().contains(tag) else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }
    
    public func budgets(for category: CashlyDomain.Category) -> [Budget] {
        budgets.filter { $0.category == category }
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
    
    public var categoriesWithBudgets: [CashlyDomain.Category] {
        var categories = [CashlyDomain.Category]()
        for category in self.categories {
            if budget(for: category) != nil {
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
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }
    
    public var score: BalanceScore {
        let variation = variation
        let percentage = variation * 100
        if percentage <= 85 { return BalanceScore(score: 1000) }
        let score = (1000 - (800 / 1.15) * (variation - 0.85)).int
        
        return BalanceScore(score: score)
    }
    
    public var remainingAmount: Double {
        budgetsAmount - transactionsAmount
    }
    
    public var variation: Double {
        let budgetsAmount = budgetsAmount
        let transactionsAmount = transactionsAmount
        return transactionsAmount / (budgetsAmount == .zero ? 1 : budgetsAmount)
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
        return transactionsAmount / (budgetsAmount == .zero ? 1 : budgetsAmount)
    }
    
    public func categoryRemainingAmount(category: CashlyDomain.Category) -> Double {
        budgetsAmount(for: category) - transactionsAmount(for: category)
    }
    
    public var transactionSections: [[CashlyDomain.Transaction]] {
        let dict = Dictionary(grouping: transactions) { transaction in
            transaction.date.date.cashly(with: .sortPattern)
        }.sorted(by: \.key, using: >)
        var transactionSections: [[CashlyDomain.Transaction]] = []
        for (_, transactions) in dict {
            transactionSections.append(transactions)
        }
        return transactionSections
    }
    
    public var transactionUsers: [User] {
        let participants = transactions.flatMap(\.participants)
        let dict = Dictionary(grouping: participants, by: \.user).sorted { lhs, rhs in
            lhs.value.reduce(.zero) { partialResult, participant in
                partialResult + participant.splitValue
            } > rhs.value.reduce(.zero) { partialResult, participant in
                partialResult + participant.splitValue
            }
        }
        return dict.prefix(5).map(\.key)
    }
    
    public var transactionsAverageAmount: Double {
        let days = Dictionary(grouping: transactions) { transaction in
            transaction.date.date.cashly(with: .sortPattern)
        }
        
        let total = days.reduce(.zero) { partialResult, transactions in
            let amount: Double = transactions.value.reduce(.zero) { partialResult, transaction in
                let amount = !transaction.participants.isEmpty ?
                transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
                transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
                return partialResult + amount
            }
            return partialResult + amount
        }
        
        return total / (days.keys.count == .zero ? 1 : days.keys.count.double)
    }
    
    public var biggestCategories: [CashlyDomain.Category] {
        budgets
            .sorted(by: \.amount, using: >)
            .prefix(5)
            .map(\.category)
    }
    
    public var biggestTags: [Tag] {
        var tagsAmount: [Tag: Double] = [:]
        for transaction in transactions {
            let summary = transaction.summary.lowercased()
            for tag in tags {
                if summary.contains(tag.name.lowercased()) {
                    let amount = !transaction.participants.isEmpty ?
                    transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
                    transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
                    tagsAmount[tag, default: .zero] += amount
                }
            }
        }
        return tagsAmount
            .sorted(by: \.value, using: >)
            .prefix(5)
            .map(\.key)
    }
    
    public var biggestTransactions: [CashlyDomain.Transaction] {
        transactions
            .sorted(by: \.amount, using: >)
            .prefix(5)
            .map(\.self)
    }
}
