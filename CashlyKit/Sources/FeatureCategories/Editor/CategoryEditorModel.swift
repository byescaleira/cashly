import CashlyDesignSystem
import CashlyDomain
import FeatureCore
import Observation
import SwiftUI

@MainActor @Observable
public final class CategoryEditorModel {
    public var draft: CategoryDraft
    public var symbolCategory: SymbolCategory = .food
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories

    public init(draft: CategoryDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }
    public var canRemove: Bool { !draft.isNew && !status.isBusy }
    public var color: Color { Color(hex: draft.color) }

    public func load() async {
        await status.load {
            let record = try await repositories.categories.category(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            var currentUser: User?
            if let userID = repositories.userID {
                currentUser = try await repositories.users.user(id: userID)
            }
            try Task.checkCancellation()
            draft.apply(record, currentUser: currentUser)
            symbolCategory = SymbolCategory.containing(draft.icon) ?? symbolCategory
        }
    }

    public func save() async {
        await status.save { try await repositories.categories.save(draft.makeCategory()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await repositories.categories.delete(id: draft.id) }
    }
}
