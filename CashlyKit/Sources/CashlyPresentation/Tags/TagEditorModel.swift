import CashlyDomain
import Observation

@MainActor @Observable
public final class TagEditorModel {
    public var draft: TagDraft
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories

    public init(draft: TagDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }

    public func load() async {
        await status.load {
            let record = try await repositories.tags.tag(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            var currentUser: User?
            if let userID = repositories.userID {
                currentUser = try await repositories.users.user(id: userID)
            }
            try Task.checkCancellation()
            draft.apply(record, currentUser: currentUser)
        }
    }

    public func save() async {
        await status.save { try await repositories.tags.save(draft.makeTag()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await repositories.tags.delete(id: draft.id) }
    }
}
