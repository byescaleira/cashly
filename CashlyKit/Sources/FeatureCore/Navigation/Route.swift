import CashlyDomain
import Foundation

public enum Route: Hashable {
    case addUser(id: String?)
    case addCategory(id: String?)
    case addBudget(id: String?, categoryID: String?, date: Date?)
    case addTransaction(id: String?)
    case addTag(id: String?)
    case budgets
    case budgetConflict(categoryID: String, month: YearMonth)
}
