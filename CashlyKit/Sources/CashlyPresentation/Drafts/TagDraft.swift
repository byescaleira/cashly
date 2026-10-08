import CashlyDesignSystem
import CashlyDomain
import Foundation
import SwiftUI

public struct TagDraft: Hashable {
    public var id: String
    public var user: User?
    public var name: String
    public var color: Color
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
        self.color = Color(hex: color)
        self.icon = icon
        self.isNew = isNew
    }

    public static func new() -> TagDraft {
        TagDraft()
    }

    public static func edit(id: String) -> TagDraft {
        TagDraft(id: id, isNew: false)
    }
}
