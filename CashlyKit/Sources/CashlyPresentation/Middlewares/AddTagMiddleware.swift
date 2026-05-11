//
//  AddTagMiddleware.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 10/09/25.
//

import CashlyDomain

public actor AddTagMiddleware: CashlyMiddleware {
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase
    
    public init(
        tagUseCase: TagUseCase,
        userUseCase: UserUseCase
    ) {
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
    }
    
    public func run(state: AddTagState, action: AddTagAction) async -> AsyncStream<AddTagAction> {
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
    
    func fetch(state: AddTagState, continuation: AsyncStream<AddTagAction>.Continuation) async {
        do {
            let tag = try await tagUseCase.getTag(id: state.id)
            let users = try await userUseCase.getUsers()
            let currentUser = try await userUseCase.getCurrentUser()
            continuation.yield(
                .update(
                    id: tag?.id ?? state.id,
                    user: tag?.user ?? state.user ?? currentUser ?? users.first,
                    name: tag?.name ?? state.name,
                    color: tag?.color ?? state.color,
                    icon: tag?.icon ?? state.icon,
                    isNew: tag == nil
                )
            )
        } catch {
            continuation.yield(.error(.onFetch))
        }
    }
    
    func save(state: AddTagState, continuation: AsyncStream<AddTagAction>.Continuation) async {
        do {
            guard state.name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
                  !state.icon.isEmpty,
                  let user = state.user
            else {
                continuation.yield(.error(.onSave))
                return
            }
            try await tagUseCase.addTag(
                id: state.id,
                user: user.id,
                name: state.name,
                color: state.color,
                icon: state.icon
            )
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onSave))
        }
    }
    
    func remove(state: AddTagState, continuation: AsyncStream<AddTagAction>.Continuation) async {
        do {
            
            guard let tag = try await tagUseCase.getTag(id: state.id) else {
                continuation.yield(.error(.onRemove))
                return
            }
            try await tagUseCase.removeTag(id: tag.id)
            continuation.yield(.saved)
        } catch {
            continuation.yield(.error(.onRemove))
        }
    }
}
