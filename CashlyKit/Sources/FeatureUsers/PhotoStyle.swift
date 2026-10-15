import CashlyDomain

public enum PhotoStyle: CaseIterable, Identifiable, Sendable {
    case initials, symbol, illustration

    public var id: Self { self }

    public var title: String {
        switch self {
        case .initials: String(appLocalized: "Initials")
        case .symbol: String(appLocalized: "Symbol")
        case .illustration: String(appLocalized: "Illustration")
        }
    }

    public init(_ photo: ProfilePhoto) {
        switch photo {
        case .initials: self = .initials
        case .symbol: self = .symbol
        case .illustration: self = .illustration
        }
    }
}
