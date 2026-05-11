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
        transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.budget.category.id == category.id else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }

    func budgetsAmount(for category: CashlyDomain.Category) -> Double {
        budgets.reduce(.zero) { partialResult, budget in
            guard budget.category.id == category.id else { return partialResult }
            return partialResult + budget.amount
        }
    }

    func transactionsAmount(for budget: Budget) -> Double {
        transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.budget.id == budget.id else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
    }

    func transactionsAmount(for tag: Tag) -> Double {
        let tag = tag.name.lowercased()
        return transactions.reduce(.zero) { partialResult, transaction in
            guard transaction.summary.lowercased().contains(tag) else { return partialResult }
            let amount = !transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
            return partialResult + amount
        }
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

    var warningCategories: [CashlyDomain.Category] {
        var categories = [(CashlyDomain.Category, Double)]()
        for category in self.categories {
            let variation = categoryVariation(category: category)
            if variation >= 0.8 {
                categories.append((category, variation))
            }
        }
        return categories.sorted { $0.1 > $1.1 }.prefix(5).map(\.0)
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
        CashlySignpost.withInterval("MainState.transactionSections") {
            let dict = Dictionary(grouping: transactions) { transaction in
                transaction.date.date.cashly(with: .sortPattern)
            }.sorted { $0.key > $1.key }
            var sections: [[CashlyDomain.Transaction]] = []
            for (_, transactions) in dict {
                sections.append(transactions)
            }
            return sections
        }
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
        CashlySignpost.withInterval("MainState.biggestTags") {
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
                .sorted { $0.value > $1.value }
                .prefix(5)
                .map(\.key)
        }
    }

    var biggestTransactions: [CashlyDomain.Transaction] {
        transactions
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map(\.self)
    }
}
