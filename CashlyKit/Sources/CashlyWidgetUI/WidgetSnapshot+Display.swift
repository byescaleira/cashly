import CashlyDomain
import Foundation

extension WidgetSnapshot {
    public func money(_ minorUnits: Int64) -> String {
        (Decimal(minorUnits) / 100).formatted(
            .currency(code: currencyCode).precision(.fractionLength(0...2)).locale(.app))
    }

    public var monthLabel: String {
        guard let date = yearMonth?.startDate else { return "" }
        return date.formatted(.dateTime.month(.abbreviated).locale(.app)).uppercased()
    }

    public var monthName: String {
        guard let date = yearMonth?.startDate else { return "" }
        return date.formatted(.dateTime.month(.wide).year().locale(.app)).capitalized
    }

    public var pendingMinorUnits: Int64 {
        bills.reduce(0) { $0 + $1.amountMinorUnits }
    }

    public var overBudgetCount: Int {
        budgets.filter { $0.ratio > 1 }.count
    }

    public static var sample: WidgetSnapshot {
        WidgetSnapshot(
            userID: "sample", userName: "", month: YearMonth(.now),
            currencyCode: Money.currencyCode, plannedMinorUnits: 420_000,
            spentMinorUnits: 268_500, incomeMinorUnits: 650_000, transactionCount: 37,
            budgets: sampleBudgets, bills: sampleBills)
    }

    private static var sampleBudgets: [BudgetLine] {
        [
            BudgetLine(
                id: "market", categoryID: "market", categoryName: String(appLocalized: "Groceries"),
                color: "C2602A", icon: "cart", plannedMinorUnits: 150_000,
                spentMinorUnits: 112_000),
            BudgetLine(
                id: "transport", categoryID: "transport",
                categoryName: String(appLocalized: "Transport"), color: "3D5F86", icon: "car",
                plannedMinorUnits: 60_000, spentMinorUnits: 61_500),
            BudgetLine(
                id: "fun", categoryID: "fun", categoryName: String(appLocalized: "Leisure"),
                color: "2A7069", icon: "gamecontroller", plannedMinorUnits: 80_000,
                spentMinorUnits: 35_000),
            BudgetLine(
                id: "home", categoryID: "home", categoryName: String(appLocalized: "Housing"),
                color: "74415F", icon: "house", plannedMinorUnits: 130_000,
                spentMinorUnits: 60_000),
        ]
    }

    private static var sampleBills: [Bill] {
        [
            Bill(
                id: "light", summary: String(appLocalized: "Electricity"),
                amountMinorUnits: 18_900, date: .now.addingTimeInterval(86_400 * 2), icon: "bolt",
                color: "B8860B"),
            Bill(
                id: "rent", summary: String(appLocalized: "Rent"), amountMinorUnits: 180_000,
                date: .now.addingTimeInterval(86_400 * 6), icon: "house", color: "74415F"),
            Bill(
                id: "gym", summary: String(appLocalized: "Gym"), amountMinorUnits: 9_900,
                date: .now.addingTimeInterval(86_400 * 9), icon: "figure.run", color: "2A7069"),
        ]
    }
}
