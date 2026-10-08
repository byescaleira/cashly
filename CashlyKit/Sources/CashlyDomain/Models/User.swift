import Foundation

public struct User: CashlyEntity, Sendable {
    public var id: String
    public var name: String
    public var photo: String

    public var firstName: String {
        name.split(separator: " ").first?.capitalized ?? ""
    }

    public var selfFirstName: String {
        let firstName = firstName
        guard !firstName.isEmpty else { return "" }
        return firstName + "'s "
    }

    public init(
        id: String,
        name: String,
        photo: String
    ) {
        self.id = id
        self.name = name
        self.photo = photo
    }

    public static var empty: User {
        User(
            id: "",
            name: "",
            photo: ""
        )
    }
}
