import CashlyDomain

public enum PhotoStyle: CaseIterable, Identifiable, Sendable {
    case initials, symbol, memoji

    public var id: Self { self }

    public var title: String {
        switch self {
        case .initials: String(appLocalized: "Initials")
        case .symbol: String(appLocalized: "Symbol")
        case .memoji: String(appLocalized: "Memoji")
        }
    }

    public init(_ photo: ProfilePhoto) {
        switch photo {
        case .initials: self = .initials
        case .symbol: self = .symbol
        case .emoji, .memoji: self = .memoji
        }
    }
}
