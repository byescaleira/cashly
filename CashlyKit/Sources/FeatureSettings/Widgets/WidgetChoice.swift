import CashlyDomain
import CashlyWidgetUI
import Foundation

struct WidgetChoice: Identifiable, Equatable {
    let id: String
    let categoryID: String?
    let title: String
    let detail: String
    let symbol: String
    let color: String?
    let ratio: Double?

    static let automaticID = "automatic"

    var isAutomatic: Bool { categoryID == nil }

    static func automatic(_ line: WidgetSnapshot.BudgetLine?) -> WidgetChoice {
        WidgetChoice(
            id: automaticID, categoryID: nil, title: String(appLocalized: "Automatic"),
            detail: line.map { String(appLocalized: "Closest to its limit: \($0.categoryName)") }
                ?? String(appLocalized: "The budget closest to its limit"),
            symbol: "wand.and.sparkles", color: nil, ratio: nil)
    }

    init(line: WidgetSnapshot.BudgetLine, snapshot: WidgetSnapshot) {
        let remaining = line.remainingMinorUnits
        id = line.categoryID ?? line.id
        categoryID = line.categoryID
        title = line.categoryName
        detail =
            remaining < 0
            ? String(appLocalized: "\(snapshot.money(-remaining)) over")
            : String(appLocalized: "\(snapshot.money(remaining)) left")
        symbol = line.icon
        color = line.color
        ratio = line.ratio
    }

    init(missingID: String, name: String) {
        id = missingID
        categoryID = missingID
        title = name
        detail = String(appLocalized: "No budget this month")
        symbol = "scope"
        color = nil
        ratio = nil
    }

    private init(
        id: String, categoryID: String?, title: String, detail: String, symbol: String,
        color: String?, ratio: Double?
    ) {
        self.id = id
        self.categoryID = categoryID
        self.title = title
        self.detail = detail
        self.symbol = symbol
        self.color = color
        self.ratio = ratio
    }
}
