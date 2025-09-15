//
//  AddCategoryMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain
import RyzeUI

public actor AddCategoryMiddleware: CashlyMiddleware {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    let userUseCase: UserUseCase
    
    public init(
        budgetUseCase: BudgetUseCase,
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase,
        userUseCase: UserUseCase
    ) {
        self.budgetUseCase = budgetUseCase
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
        self.userUseCase = userUseCase
    }
    
    public func run(state: AddCategoryState, action: AddCategoryAction) async -> AsyncStream<AddCategoryAction> {
        AsyncStream { continuation in
            Task {
                switch action {
                case .fetch:
                    await fetch(state: state, continuation: continuation)
                case .save:
                    await save(state: state, continuation: continuation)
                case .remove:
                    await remove(state: state, continuation: continuation)
                case .update:
                    continuation.yield(.stopLoading)
                case .stopLoading, .saved, .error:
                    break
                }
            }
        }
    }
    
    func fetch(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            let category = try await categoryUseCase.getCategory(id: state.id)
            let users = try await userUseCase.getUsers()
            let currentUser = try await userUseCase.getCurrentUser()
            let color = category?.color == nil ? nil : Color(hex: category?.color)
            continuation.yield(
                .update(
                    id: category?.id ?? state.id,
                    user: category?.user ?? state.user ?? currentUser ?? users.first,
                    name: category?.name ?? state.name,
                    color: color ?? state.color,
                    icon: category?.icon ?? state.icon,
                    isNew: category == nil
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
                  !state.icon.isEmpty,
                  let user = state.user
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await categoryUseCase.addCategory(
                id: state.id,
                user: user.id,
                name: state.name,
                color: state.color.hex,
                icon: state.icon
            )
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            let budgets = try await budgetUseCase.getBudgets(
                categories: [state.id],
                date: nil
            )
            let transaction = try await transactionUseCase.getTransactions(
                budgets: budgets.map(\.id),
                tags: nil,
                date: nil
            )
            
            guard let category = try await categoryUseCase.getCategory(id: state.id),
                  budgets.isEmpty,
                  transaction.isEmpty
            else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await categoryUseCase.removeCategory(id: category.id)
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
