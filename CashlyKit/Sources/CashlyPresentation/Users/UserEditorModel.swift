import CashlyDomain
import FeatureCore
import Observation

@MainActor @Observable
public final class UserEditorModel {
    public var draft: UserDraft
    public let status = EditorStatus()
    @ObservationIgnored private let users: any UserRepository

    public init(draft: UserDraft = .new(), users: any UserRepository) {
        self.draft = draft
        self.users = users
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }

    public func load() async {
        await status.load {
            let record = try await users.user(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            draft.apply(record)
        }
    }

    public func save() async {
        await status.save { try await users.save(draft.makeUser()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await users.delete(id: draft.id) }
    }
}
