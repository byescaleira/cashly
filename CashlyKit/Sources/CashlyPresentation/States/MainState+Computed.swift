//
//  MainState+Computed.swift
//  CashlyKit
//
//  Derived helpers extracted from MainState to keep that file at the
//  data-shape only.
//

import Foundation
import CashlyDomain
import CashlyResource

public extension MainState {
    // MARK: - Subscription / gating helpers

    var isPro: Bool {
        subscriptionStatus.tier == .pro
    }

    /// Free-tier ceilings — single source of truth lives in
    /// CashlyDomain so view-side gating chips and save-time
    /// FeatureGate decisions cannot drift apart. Production gating
    /// still runs through the use case at save time.
    static var freeLimits: FeatureGateLimits { .freeDefault }

    /// True when the active tier allows adding another entity of the
    /// given kind. Used to disable + label save buttons before a
    /// .featureGated error round-trips through the middleware.
    func canAdd(_ feature: FeatureGate) -> Bool {
        if isPro { return true }
        switch feature {
        case .addUser: return users.count < Self.freeLimits.maxUsers
        case .addCategory: return categories.count < Self.freeLimits.maxCategories
        case .addBudget: return budgets.count < Self.freeLimits.maxBudgets
        case .intelligence, .multiUser: return false
        }
    }

    /// Human-readable "n / N" or "Pro" label for the given gate.
    func usageLabel(for feature: FeatureGate) -> String {
        if isPro { return CashlyL10n.string("Pro") }
        switch feature {
        case .addUser:
            return "\(users.count)/\(Self.freeLimits.maxUsers)"
        case .addCategory:
            return "\(categories.count)/\(Self.freeLimits.maxCategories)"
        case .addBudget:
            return "\(budgets.count)/\(Self.freeLimits.maxBudgets)"
        case .intelligence, .multiUser:
            return CashlyL10n.string("Pro")
        }
    }

    func participantsUser(
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
        }.sorted { $0.user.name < $1.user.name }
    }

    func transactionsAmount(for category: CashlyDomain.Category) -> Double {
        transactionsAmountByCategory[category.id] ?? .zero
    }

    func budgetsAmount(for category: CashlyDomain.Category) -> Double {
        budgetsAmountByCategory[category.id] ?? .zero
    }

    func transactionsAmount(for budget: Budget) -> Double {
        transactionsAmountByBudget[budget.id] ?? .zero
    }

    func transactionsAmount(for tag: Tag) -> Double {
        transactionsAmountByTag[tag.id] ?? .zero
    }

    func budgets(for category: CashlyDomain.Category) -> [Budget] {
        budgets.filter { $0.category == category }
    }

    func budget(for category: CashlyDomain.Category) -> Budget? {
        budgets.last(where: { $0.category.id == category.id })
    }

    var categoriesWithoutBudgets: [CashlyDomain.Category] {
        categories.filter { budget(for: $0) == nil }
    }

    var categoriesWithBudgets: [CashlyDomain.Category] {
        categories.filter { budget(for: $0) != nil }
    }

    var budgetsAmount: Double {
        budgets.reduce(.zero) { $0 + $1.amount }
    }

    var transactionsAmount: Double {
        transactions.reduce(.zero) { partialResult, transaction in
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }

    var score: BalanceScore {
        CashlySignpost.withInterval("MainState.score") {
            let variation = variation
            let percentage = variation * 100
            if percentage <= 85 { return BalanceScore(score: 1000) }
            let score = (1000 - (800 / 1.15) * (variation - 0.85)).int
            return BalanceScore(score: score)
        }
    }

    var remainingAmount: Double {
        budgetsAmount - transactionsAmount
    }

    var variation: Double {
        let budgetsAmount = budgetsAmount
        let transactionsAmount = transactionsAmount
        return transactionsAmount / (budgetsAmount == .zero ? 1 : budgetsAmount)
    }

    /// Categories whose spending is at 80%+ of their budgeted amount,
    /// top 5 by variation. Pre-paired with the variation itself so
    /// call sites that also need the value (e.g. BalanceView) don't
    /// recompute. Use ``warningCategories`` if you only need the
    /// `[Category]`.
    var warningCategoriesWithVariation: [(CashlyDomain.Category, Double)] {
        var matches = [(CashlyDomain.Category, Double)]()
        for category in self.categories {
            let variation = categoryVariation(category: category)
            if variation >= 0.8 {
                matches.append((category, variation))
            }
        }
        return Array(matches.sorted { $0.1 > $1.1 }.prefix(5))
    }

    var warningCategories: [CashlyDomain.Category] {
        warningCategoriesWithVariation.map(\.0)
    }

    func categoryVariation(category: CashlyDomain.Category, amount: Double = .zero) -> Double {
        let transactionsAmount = transactionsAmount(for: category) + amount
        let budgetsAmount = budgetsAmount(for: category)
        return transactionsAmount / (budgetsAmount == .zero ? 1 : budgetsAmount)
    }

    func categoryRemainingAmount(category: CashlyDomain.Category) -> Double {
        budgetsAmount(for: category) - transactionsAmount(for: category)
    }

    var transactionSections: [[CashlyDomain.Transaction]] {
        transactionSectionsCache
    }

    var transactionUsers: [User] {
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

    var transactionsAverageAmount: Double {
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

    var biggestCategories: [CashlyDomain.Category] {
        budgets
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map(\.category)
    }

    var biggestTags: [Tag] {
        biggestTagsCache
    }

    var biggestTransactions: [CashlyDomain.Transaction] {
        transactions
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map(\.self)
    }
}
