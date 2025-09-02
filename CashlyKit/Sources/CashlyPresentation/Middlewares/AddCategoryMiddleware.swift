//
//  AddCategoryMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public actor AddCategoryMiddleware: CashlyMiddleware {
    let categoryUseCase: CategoryUseCase
    let transactionUseCase: TransactionUseCase
    
    public init(
        categoryUseCase: CategoryUseCase,
        transactionUseCase: TransactionUseCase
    ) {
        self.categoryUseCase = categoryUseCase
        self.transactionUseCase = transactionUseCase
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
                case .stopLoading, .error:
                    break
                }
            }
        }
    }
    
    func fetch(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            let category = try await categoryUseCase.getCategory(id: state.id)
            continuation.yield(
                .update(
                    id: category?.id ?? state.id,
                    name: category?.name ?? state.name,
                    color: category?.color ?? state.color,
                    icon: category?.icon ?? state.icon
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            guard !state.name.isEmpty,
                  !state.color.isEmpty,
                  !state.icon.isEmpty
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await categoryUseCase.addCategory(
                id: state.id,
                name: state.name,
                color: state.color,
                icon: state.icon
            )
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddCategoryState, continuation: AsyncStream<AddCategoryAction>.Continuation) async {
        do {
            let transaction = try await transactionUseCase.getTransactions(
                budget: nil,
                category: state.id,
                date: nil
            )
            guard let category = try await categoryUseCase.getCategory(id: state.id),
                  transaction.isEmpty
            else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await categoryUseCase.removeCategory(id: category.id)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
