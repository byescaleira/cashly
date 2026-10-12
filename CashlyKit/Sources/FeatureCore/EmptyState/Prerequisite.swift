import SwiftUI

public enum Prerequisite: CaseIterable, Sendable {
    case category, transaction, tag, budget

    var title: LocalizedStringKey {
        switch self {
        case .category: "No categories yet"
        case .transaction: "No transactions in this period"
        case .tag: "No tags yet"
        case .budget: "No budgets this month"
        }
    }

    var description: LocalizedStringKey {
        switch self {
        case .category: "Categories show where your money goes."
        case .transaction: "Record money in and out to follow the month."
        case .tag: "Tags group the spending of a trip, event or project."
        case .budget: "Set how much you want to spend in each category and follow the month's pace."
        }
    }

    var actionTitle: LocalizedStringKey {
        switch self {
        case .category: "Add Category"
        case .transaction: "Add Transaction"
        case .tag: "Add Tag"
        case .budget: "Create Budget"
        }
    }

    var route: Route {
        switch self {
        case .category: .addCategory(id: nil)
        case .transaction: .addTransaction(id: nil)
        case .tag: .addTag(id: nil)
        case .budget: .addBudget(id: nil, categoryID: nil, date: nil)
        }
    }
}
