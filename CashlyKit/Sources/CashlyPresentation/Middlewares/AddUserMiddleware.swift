//
//  AddUserMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 06/09/25.
//

import CashlyDomain
import RyzeUI

public actor AddUserMiddleware: CashlyMiddleware {
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
    
    public func run(state: AddUserState, action: AddUserAction) async -> AsyncStream<AddUserAction> {
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
    
    func fetch(state: AddUserState, continuation: AsyncStream<AddUserAction>.Continuation) async {
        do {
            let user = try await userUseCase.getUser(id: state.id)
            continuation.yield(
                .update(
                    id: user?.id ?? state.id,
                    name: user?.name ?? state.name,
                    photo: user?.photo ?? state.photo,
                    isNew: user == nil
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddUserState, continuation: AsyncStream<AddUserAction>.Continuation) async {
        do {
            guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
                  let photo = state.photo,
                  URL(string: photo) != nil
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await userUseCase.addUser(
                id: state.id,
                name: state.name,
                photo: photo
            )
            
            guard let user = try await userUseCase.getUser(id: state.id) else {
                continuation.yield(.error(.onSave))
                return
            }
            try await userUseCase.selectUser(user: user)
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddUserState, continuation: AsyncStream<AddUserAction>.Continuation) async {
        do {
            let categories = try await categoryUseCase.getCategories(ids: nil, users: [state.id])
            let budgets = try await budgetUseCase.getBudgets(
                categories: categories.map(\.name),
                date: nil
            )
            let transaction = try await transactionUseCase.getTransactions(
                budgets: budgets.map(\.id),
                tags: nil,
                statuses: nil,
                participants: nil,
                date: nil
            )
            
            guard let user = try await userUseCase.getUser(id: state.id),
                  categories.isEmpty,
                  budgets.isEmpty,
                  transaction.isEmpty
            else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await userUseCase.removeUser(id: user.id)
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
