//
//  AddTagMiddleware.swift
//  CashlyKit
//

import CashlyDomain
import PrismArchitecture

public struct AddTagMiddleware: PrismMiddleware {
    let tagUseCase: TagUseCase
    let userUseCase: UserUseCase

    public init(tagUseCase: TagUseCase, userUseCase: UserUseCase) {
        self.tagUseCase = tagUseCase
        self.userUseCase = userUseCase
    }

    public func run(state: AddTagState, action: AddTagAction) -> PrismEffect<AddTagAction> {
        switch action {
        case .fetch: return fetch(state: state)
        case .save: return save(state: state)
        case .remove: return remove(state: state)
        case .update: return .send(.stopLoading)
        case .stopLoading, .saved, .error, .replace: return .none
        }
    }

    private func fetch(state: AddTagState) -> PrismEffect<AddTagAction> {
        .run { send in
            do {
                let tag = try await tagUseCase.getTag(id: state.id)
                let users = try await userUseCase.getUsers()
                let currentUser = try await userUseCase.getCurrentUser()
                send(.update(
                    id: tag?.id ?? state.id,
                    user: tag?.user ?? state.user ?? currentUser ?? users.first,
                    name: tag?.name ?? state.name,
                    color: tag?.color ?? state.color,
                    icon: tag?.icon ?? state.icon,
                    isNew: tag == nil
                ))
            } catch {
                send(.error(.persistence(.fetchFailed(entity: "Tag", underlying: error.localizedDescription))))
            }
        }
    }

    private func save(state: AddTagState) -> PrismEffect<AddTagAction> {
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
                try await tagUseCase.addTag(
                    id: state.id, user: user.id, name: state.name,
                    color: state.color, icon: state.icon
                )
                send(.saved)
            } catch {
                send(.error(.persistence(.saveFailed(entity: "Tag", underlying: error.localizedDescription))))
            }
        }
    }

    private func remove(state: AddTagState) -> PrismEffect<AddTagAction> {
        .run { send in
            do {
                guard let tag = try await tagUseCase.getTag(id: state.id) else {
                    send(.error(.persistence(.notFound(entity: "Tag", id: state.id))))
                    return
                }
                try await tagUseCase.removeTag(id: tag.id)
                send(.saved)
            } catch {
                send(.error(.persistence(.removeFailed(entity: "Tag", underlying: error.localizedDescription))))
            }
        }
    }
}
