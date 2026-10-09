import CashlyDomain

extension User {
    public var firstName: String {
        name.split(separator: " ").first?.capitalized ?? ""
    }
}
