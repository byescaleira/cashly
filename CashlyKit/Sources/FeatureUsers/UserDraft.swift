import CashlyDomain
import Foundation

public struct UserDraft: Hashable {
    public var id: String
    public var name: String
    public var photo: String?
    public var isNew: Bool

    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            && (1...100).contains(Int(photo ?? "") ?? 0)
    }

    private init(
        id: String = UUID().uuidString,
        name: String = "",
        photo: String? = nil,
        isNew: Bool = true,
    ) {
        self.id = id
        self.name = name
        self.photo = photo
        self.isNew = isNew
    }

    public static func new() -> UserDraft {
        UserDraft()
    }

    public static func edit(id: String) -> UserDraft {
        UserDraft(id: id, isNew: false)
    }

    public func makeUser() throws -> User {
        guard canSave, let photo else { throw CashlyError.onSave }
        return User(
            id: id, name: name.trimmingCharacters(in: .whitespacesAndNewlines), photo: photo)
    }

    public mutating func apply(_ user: User?) {
        if let user {
            name = user.name
            photo = user.photo
        }
        if photo == nil { photo = "1" }
    }
}
