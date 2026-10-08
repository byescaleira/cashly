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

    public func photos(for gender: Int = .zero) -> [String] {
        ((gender == .zero ? 1 : 51)...(gender == .zero ? 50 : 100)).map {
            "\($0)"
        }
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
}
