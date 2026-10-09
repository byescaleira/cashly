import CashlyDomain
import Foundation

public struct CategoryDraft: Hashable {
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
        color: String = "",
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

    public static func new() -> CategoryDraft {
        CategoryDraft()
    }

    public static func edit(id: String) -> CategoryDraft {
        CategoryDraft(id: id, isNew: false)
    }

    public func makeCategory() throws -> CashlyDomain.Category {
        guard canSave, let user else { throw CashlyError.onSave }
        return CashlyDomain.Category(
            id: id, user: user, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            color: color, icon: icon)
    }

    public mutating func apply(_ category: CashlyDomain.Category?, currentUser: User?) {
        user = category?.user ?? user ?? currentUser
        if let category {
            name = category.name
            icon = category.icon
            color = category.color
        }
        if icon.isEmpty { icon = "tag.fill" }
    }
}
