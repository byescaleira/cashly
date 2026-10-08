import Foundation

public enum AppSection: String, CaseIterable, Identifiable {
    case intelligence, category, home, transaction
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .intelligence: "Intelligence"
        case .category: "Categories"
        case .home: "Home"
        case .transaction: "Transactions"
        }
    }
    public var systemImage: String {
        switch self {
        case .intelligence: "cpu"
        case .category: "tag"
        case .home: "house"
        case .transaction: "wallet.bifold"
        }
    }
}
