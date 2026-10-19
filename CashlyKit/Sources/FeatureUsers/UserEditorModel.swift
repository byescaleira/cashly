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
    @ObservationIgnored let sharing: SharingModel?
    public let sourceCategories: [CashlyDomain.Category]
    public let sourceName: String?

    public init(
        draft: UserDraft = .new(), users: any UserRepository, sharing: SharingModel? = nil,
        sourceCategories: [CashlyDomain.Category] = [], sourceName: String? = nil
    ) {
        self.draft = draft
        self.users = users
        self.sharing = sharing
        self.sourceCategories = sourceCategories
        self.sourceName = sourceName
        style = PhotoStyle(draft.photo)
        photoColor = draft.photo.color ?? ProfilePhoto.defaultColor
    }

    public var canSave: Bool {
        status.isLoaded && !status.isLocked && draft.canSave && (!createsShared || canShare)
    }
    public var canRemove: Bool { !draft.isNew && !draft.isShared && !status.isBusy }
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
        let copies = draft.copiesCategories ? sourceCategories : []
        await status.save {
            let user = try draft.makeUser()
            if createsShared, let sharing {
                try await sharing.create(user, copying: copies)
            } else {
                try await users.save(user)
            }
        }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await users.delete(id: draft.id) }
    }
}
