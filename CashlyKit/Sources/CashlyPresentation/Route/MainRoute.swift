import CashlyDomain
import Foundation

public enum MainRoute: Hashable {
    case addUser(id: String?)
    case addCategory(id: String?)
    case addBudget(id: String?, categoryID: String?, date: Date?)
    case addTransaction(id: String?)
    case addTag(id: String?)
    case detailCategory(id: String)
    case budgetConflict(categoryID: String, month: YearMonth)
}

public enum CashlySection: String, CaseIterable, Identifiable {
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
