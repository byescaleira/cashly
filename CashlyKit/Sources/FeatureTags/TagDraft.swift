import CashlyDomain
import FeatureCore
import Foundation

public struct TagDraft: Hashable {
    public var id: String
    public var user: User?
    public var name: String
    public var color: String
    public var icon: String
    public var isNew: Bool

    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 && user != nil
            && !icon.isEmpty
    }

    private init(
        id: String = UUID().uuidString,
        user: User? = nil,
        name: String = "",
        color: String = RetroColor.default.hex,
        icon: String = "",
        isNew: Bool = true,
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
        self.isNew = isNew
    }

    public static func new() -> TagDraft {
        TagDraft()
    }

    public static func edit(id: String) -> TagDraft {
        TagDraft(id: id, isNew: false)
    }

    public func makeTag() throws -> Tag {
        guard canSave, let user else { throw CashlyError.onSave }
        return Tag(
            id: id, user: user, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color, icon: icon)
    }

    public mutating func apply(_ tag: Tag?, currentUser: User?) {
        user = tag?.user ?? user ?? currentUser
        if let tag {
            name = tag.name
            icon = tag.icon
            color = tag.color
        }
        if icon.isEmpty { icon = "tag.fill" }
    }
}
