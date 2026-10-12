import AppIntents
import CashlyDomain
import FeatureCore
import Foundation

public struct CashlyIntentsPackage: AppIntentsPackage {
    public init() {}
}

public struct AddExpenseIntent: AppIntent {
    public static let title: LocalizedStringResource = "Add Expense"
    public static let description = IntentDescription("Records an expense in the current profile.")

    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?")
    public var amount: Double
    @Parameter(title: "Category")
    public var category: CategoryEntity?
    @Parameter(title: "Description")
    public var summary: String?
    @Parameter(title: "Tags")
    public var tags: [TagEntity]?
    @Parameter(title: "Date")
    public var date: Date?

    public static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$amount) in \(\.$category)") {
            \.$summary
            \.$tags
            \.$date
        }
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let actions = try await IntentWorkspace.actions(writing: true)
        let saved = try await actions.addExpense(
            amount: amount, categoryID: category?.id, summary: summary ?? "", date: date,
            tagIDs: Set((tags ?? []).map(\.id)))
        return .result(dialog: "Added \(saved.money.formatted) in \(saved.category.name).")
    }
}

public struct MonthSpentIntent: AppIntent {
    public static let title: LocalizedStringResource = "How Much Did I Spend This Month"
    public static let description = IntentDescription(
        "Tells how much went out this month and what is left of the budgets.")

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog
    {
        let month = try await IntentWorkspace.actions().monthSummary()
        let spent = month.spent.formatted
        let dialog: IntentDialog =
            month.planned.minorUnits > 0
            ? "You spent \(spent) this month. \(month.available.formatted) of \(month.planned.formatted) planned is still available."
            : "You spent \(spent) this month."
        return .result(value: month.spent.doubleValue, dialog: dialog)
    }
}

public struct CategoryRemainingIntent: AppIntent {
    public static let title: LocalizedStringResource = "How Much Is Left in a Category"
    public static let description = IntentDescription(
        "Compares what you spent in a category with its budget this month.")

    @Parameter(title: "Category")
    public var category: CategoryEntity

    public static var parameterSummary: some ParameterSummary {
        Summary("How much is left in \(\.$category)")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ReturnsValue<Double> & ProvidesDialog
    {
        let remaining = try await IntentWorkspace.actions().remaining(categoryID: category.id)
        let name = remaining.category.name
        guard let left = remaining.remaining else {
            return .result(
                value: remaining.spent.doubleValue,
                dialog:
                    "There is no budget for \(name) this month. You spent \(remaining.spent.formatted)."
            )
        }
        let dialog: IntentDialog =
            left.minorUnits >= 0
            ? "\(left.formatted) left in \(name) this month."
            : "\(name) is \(Money(minorUnits: -left.minorUnits).formatted) over budget this month."
        return .result(value: left.doubleValue, dialog: dialog)
    }
}

public struct MarkBillPaidIntent: AppIntent {
    public static let title: LocalizedStringResource = "Mark Bill as Paid"
    public static let description = IntentDescription("Settles a pending bill.")

    @Parameter(title: "Bill")
    public var bill: PendingBillEntity

    public static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$bill) as paid")
    }

    public init() {}

    @MainActor
    public func perform() async throws -> some IntentResult & ProvidesDialog {
        let actions = try await IntentWorkspace.actions(writing: true)
        let paid = try await actions.markPaid(transactionID: bill.id)
        let name = paid.summary.isEmpty ? paid.category.name : paid.summary
        return .result(dialog: "\(name) marked as paid.")
    }
}
