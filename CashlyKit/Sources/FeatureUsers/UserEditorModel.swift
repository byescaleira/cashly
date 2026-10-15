import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class UserEditorModel {
    public var draft: UserDraft
    public let status = EditorStatus()
    public internal(set) var style: PhotoStyle
    public var photoColor: String {
        didSet { draft.photo = draft.photo.recolored(photoColor) }
    }
    public internal(set) var symbol = ProfileSymbol.default.rawValue
    public internal(set) var illustration = ProfileIllustration.suggested?.id
    @ObservationIgnored private let users: any UserRepository

    public init(draft: UserDraft = .new(), users: any UserRepository) {
        self.draft = draft
        self.users = users
        style = PhotoStyle(draft.photo)
        photoColor = draft.photo.color ?? ProfilePhoto.defaultColor
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }
    public var canRemove: Bool { !draft.isNew && !status.isBusy }
    public var userToSelect: String? { draft.isNew ? draft.id : nil }

    public func load() async {
        await status.load {
            let record = try await users.user(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            draft.apply(record)
            adopt(draft.photo)
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
