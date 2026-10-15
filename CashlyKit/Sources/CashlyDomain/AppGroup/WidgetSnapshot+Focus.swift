import Foundation

extension WidgetSnapshot.BudgetLine {
    public var ratio: Double {
        plannedMinorUnits > 0 ? Double(spentMinorUnits) / Double(plannedMinorUnits) : 0
    }
}

extension WidgetSnapshot {
    public var isFocusAutomatic: Bool { focusCategoryID == nil }

    public var focusLine: BudgetLine? {
        guard let focusCategoryID else { return automaticLine }
        return budgets.first { $0.categoryID == focusCategoryID }
    }

    public var automaticLine: BudgetLine? {
        budgets.filter { $0.plannedMinorUnits > 0 }.max {
            ($0.ratio, $0.plannedMinorUnits) < ($1.ratio, $1.plannedMinorUnits)
        }
    }

    public func focusing(categoryID: String?) -> WidgetSnapshot {
        guard categoryID != focusCategoryID else { return self }
        var snapshot = self
        snapshot.focusCategoryID = categoryID
        snapshot.focusCategoryName = budgets.first { $0.categoryID == categoryID }?.categoryName
        return snapshot
    }
}
