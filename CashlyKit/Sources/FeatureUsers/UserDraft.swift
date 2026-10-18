import CashlyDomain
import FeatureCore
import Foundation

public struct UserDraft: Hashable {
    public var id: String
    public var name: String
    public var photo: ProfilePhoto
    public var isNew: Bool
    public var isShared: Bool
    public var copiesCategories = true

    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && photo.isValid
    }

    private init(id: String = UUID().uuidString, isNew: Bool = true, isShared: Bool = false) {
        self.id = id
        self.name = ""
        self.photo = .suggested(for: id)
        self.isNew = isNew
        self.isShared = isShared
    }

    public static func new(shared: Bool = false) -> UserDraft {
        UserDraft(isShared: shared)
    }

    public static func edit(id: String) -> UserDraft {
        UserDraft(id: id, isNew: false)
    }

    public func makeUser() throws -> User {
        guard canSave else { throw CashlyError.onSave }
        return User(
            id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), photo: photo,
            isShared: isShared)
    }

    public mutating func apply(_ user: User?) {
        guard let user else { return }
        name = user.name
        photo = user.photo
        isShared = user.isShared
    }
}
