import CashlyDomain
import Foundation

public enum Route: Hashable {
    case addUser(id: String?)
    case addSharedProfile
    case sharedProfile(id: String)
    case addCategory(id: String?)
    case addBudget(id: String?, categoryID: String?, date: Date?, amount: Double? = nil)
    case addTransaction(id: String?)
    case classifyCapture(Capture)
    case addTag(id: String?)
    case budgets
    case budgetConflict(categoryID: String, month: YearMonth)
    case shop
    case converter
}
