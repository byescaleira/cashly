//
//  AddCategoryMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

public struct AddCategoryMiddleware: PrismMiddleware {
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

    public func run(state: AddCategoryState, action: AddCategoryAction) -> PrismEffect<AddCategoryAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .save: return save(state: state)
        case .remove: return remove(state: state)
        case .update: return .send(.stopLoading)
        case .stopLoading, .saved, .error, .replace: return .none
        }
    }

    private func fetch(state: AddCategoryState) -> PrismEffect<AddCategoryAction> {
        .run { send in
            do {
                let category = try await categoryUseCase.getCategory(id: state.id)
                let users = try await userUseCase.getUsers()
                let currentUser = try await userUseCase.getCurrentUser()
                send(.update(
                    id: category?.id ?? state.id,
                    user: category?.user ?? state.user ?? currentUser ?? users.first,
                    name: category?.name ?? state.name,
                    color: category?.color ?? state.color,
                    icon: category?.icon ?? state.icon,
                    isNew: category == nil
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "Category", underlying: error.localizedDescription))))
            }
        }
    }

    private func save(state: AddCategoryState) -> PrismEffect<AddCategoryAction> {
        .run { send in
            do {
                guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    send(.error(.domain(.invalidInput(field: "name", reason: "Name must be at least 3 characters."))))
                    return
                }
                guard !state.icon.isEmpty else {
                    send(.error(.domain(.invalidInput(field: "icon", reason: "Icon is required."))))
                    return
                }
                guard let user = state.user else {
                    send(.error(.domain(.invalidInput(field: "user", reason: "User is required."))))
                    return
                }
                // Only enforce the gate when creating; editing an
                // existing category should always be allowed even
                // above the free-tier ceiling.
                if state.isNew {
                    let decision = await featureGate.decide(.addCategory)
                    if case .blocked = decision {
                        send(.error(.domain(.featureGated(feature: "Categories", requiredTier: "Pro"))))
                        return
                    }
                }
                try await categoryUseCase.addCategory(
                    id: state.id, user: user.id, name: state.name,
                    color: state.color, icon: state.icon
                )
                send(.saved)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Category", underlying: error.localizedDescription))))
            }
        }
    }

    private func remove(state: AddCategoryState) -> PrismEffect<AddCategoryAction> {
        .run { send in
            do {
                let budgets = try await budgetUseCase.getBudgets(categories: [state.id], date: nil)
                let transaction = try await transactionUseCase.getTransactions(
                    budgets: budgets.map(\.id), tags: nil, statuses: nil, participants: nil, date: nil
                )
                guard let category = try await categoryUseCase.getCategory(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "Category", id: state.id))))
                    return
                }
                guard budgets.isEmpty, transaction.isEmpty else {
                    send(.error(.domain(.businessRuleViolated(rule: "Category has related budgets or transactions."))))
                    return
                }
                try await categoryUseCase.removeCategory(id: category.id)
                send(.saved)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Category", underlying: error.localizedDescription))))
            }
        }
    }
}
