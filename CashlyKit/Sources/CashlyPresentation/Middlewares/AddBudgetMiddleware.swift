//
//  AddBudgetMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture
import Foundation

public struct AddBudgetMiddleware: PrismMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let userUseCase: UserUseCase
    let featureGate: FeatureGateUseCase

    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        userUseCase: UserUseCase,
        featureGate: FeatureGateUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.userUseCase = userUseCase
        self.featureGate = featureGate
    }

    public func run(state: AddBudgetState, action: AddBudgetAction) -> PrismEffect<AddBudgetAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .save: return save(state: state)
        case .remove: return remove(state: state)
        case .update: return .send(.stopLoading)
        case .stopLoading, .saved, .error, .replace: return .none
        }
    }

    private func fetch(state: AddBudgetState) -> PrismEffect<AddBudgetAction> {
        .run { send in
            do {
                let budgets = try await budgetUseCase.getBudgets(
                    categories: state.category == nil ? nil : [state.category?.id ?? ""],
                    date: state.date
                )
                let fetchedBudget = try await budgetUseCase.getBudget(id: state.id)
                let budget = state.category != nil ? budgets.first : fetchedBudget
                let currentUser = try await userUseCase.getCurrentUser()
                let categories = try await categoryUseCase.getCategories(
                    ids: nil,
                    users: currentUser == nil ? nil : [currentUser?.id ?? ""]
                )
                send(.update(
                    categories: categories,
                    id: budget?.id ?? UUID().uuidString,
                    amount: budget?.amount ?? .zero,
                    category: budget?.category ?? state.category ?? categories.first,
                    date: budget?.date ?? state.date.timeIntervalSince1970.yearMonth,
                    summary: budget?.summary ?? "",
                    isNew: budget == nil
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "Budget", underlying: error.localizedDescription))))
            }
        }
    }

    private func save(state: AddBudgetState) -> PrismEffect<AddBudgetAction> {
        .run { send in
            do {
                guard let category = state.category else {
                    send(.error(.domain(.invalidInput(field: "category", reason: "Category is required."))))
                    return
                }
                guard state.amount > .zero else {
                    send(.error(.domain(.invalidInput(field: "amount", reason: "Amount must be greater than zero."))))
                    return
                }
                guard state.summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    send(.error(.domain(.invalidInput(field: "summary", reason: "Summary must be at least 3 characters."))))
                    return
                }
                if state.isNew {
                    let decision = await featureGate.decide(.addBudget)
                    if case .blocked = decision {
                        send(.error(.domain(.featureGated(feature: "Budgets", requiredTier: "Pro"))))
                        return
                    }
                }
                try await budgetUseCase.addBudget(
                    id: state.id,
                    amount: state.amount,
                    category: category,
                    date: state.date.timeIntervalSince1970.yearMonth,
                    summary: state.summary,
                    rollsOver: state.rollsOver
                )
                send(.saved)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Budget", underlying: error.localizedDescription))))
            }
        }
    }

    private func remove(state: AddBudgetState) -> PrismEffect<AddBudgetAction> {
        .run { send in
            do {
                let transaction = try await transactionUseCase.getTransactions(
                    budgets: [state.id], tags: nil, statuses: nil, participants: nil, date: nil
                )
                guard let budget = try await budgetUseCase.getBudget(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "Budget", id: state.id))))
                    return
                }
                guard transaction.isEmpty else {
                    send(.error(.domain(.businessRuleViolated(rule: "Budget has related transactions."))))
                    return
                }
                try await budgetUseCase.removeBudget(id: budget.id)
                send(.saved)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Budget", underlying: error.localizedDescription))))
            }
        }
    }
}
