import CashlyDomain

extension User {
    public var firstName: String {
        name.split(separator: " ").first?.capitalized ?? ""
    }

    public var selfFirstName: String {
        firstName.isEmpty ? "" : firstName + "'s "
    }
}
