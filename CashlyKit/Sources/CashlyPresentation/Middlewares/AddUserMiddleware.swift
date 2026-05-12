//
import Foundation
//  AddUserMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

public struct AddUserMiddleware: PrismMiddleware {
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

    public func run(state: AddUserState, action: AddUserAction) -> PrismEffect<AddUserAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .save: return save(state: state)
        case .remove: return remove(state: state)
        case .update: return .send(.stopLoading)
        case .stopLoading, .saved, .error, .replace: return .none
        }
    }

    private func fetch(state: AddUserState) -> PrismEffect<AddUserAction> {
        .run { send in
            do {
                let user = try await userUseCase.getUser(id: state.id)
                send(.update(
                    id: user?.id ?? state.id,
                    name: user?.name ?? state.name,
                    photo: user?.photo ?? state.photo,
                    isNew: user == nil
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "User", underlying: error.localizedDescription))))
            }
        }
    }

    private func save(state: AddUserState) -> PrismEffect<AddUserAction> {
        .run { send in
            do {
                guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 else {
                    send(.error(.domain(.invalidInput(field: "name", reason: "Name must be at least 3 characters."))))
                    return
                }
                guard let photo = state.photo, URL(string: photo) != nil else {
                    send(.error(.domain(.invalidInput(field: "photo", reason: "Photo must be a valid URL."))))
                    return
                }
                if state.isNew {
                    let decision = await featureGate.decide(.addUser)
                    if case .blocked = decision {
                        send(.error(.domain(.featureGated(feature: "Multiple users", requiredTier: "Pro"))))
                        return
                    }
                }
                try await userUseCase.addUser(id: state.id, name: state.name, photo: photo)
                guard let user = try await userUseCase.getUser(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "User", id: state.id))))
                    return
                }
                try await userUseCase.selectUser(user: user)
                send(.saved)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "User", underlying: error.localizedDescription))))
            }
        }
    }

    private func remove(state: AddUserState) -> PrismEffect<AddUserAction> {
        .run { send in
            do {
                let categories = try await categoryUseCase.getCategories(ids: nil, users: [state.id])
                let budgets = try await budgetUseCase.getBudgets(categories: categories.map(\.id), date: nil)
                let transaction = try await transactionUseCase.getTransactions(
                    budgets: budgets.map(\.id), tags: nil, statuses: nil, participants: nil, date: nil
                )
                guard let user = try await userUseCase.getUser(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "User", id: state.id))))
                    return
                }
                guard categories.isEmpty, budgets.isEmpty, transaction.isEmpty else {
                    send(.error(.domain(.businessRuleViolated(rule: "User has related categories, budgets or transactions."))))
                    return
                }
                try await userUseCase.removeUser(id: user.id)
                send(.saved)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "User", underlying: error.localizedDescription))))
            }
        }
    }
}
