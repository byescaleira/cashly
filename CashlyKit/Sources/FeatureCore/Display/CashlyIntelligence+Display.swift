import CashlyDesignSystem
import CashlyDomain
import SwiftUI

extension CashlyIntelligence {
    public var name: String {
        switch self {
        case .budgetValue: String(appLocalized: "Smart Budget")
        case .categoryName: String(appLocalized: "Auto Categorization")
        case .tagValue: String(appLocalized: "Tag Forecast")
        }
    }

    public var summary: String {
        switch self {
        case .budgetValue:
            String(
                appLocalized:
                    "Estimates each category's monthly spending from the average of up to six recorded months."
            )
        case .categoryName:
            String(
                appLocalized:
                    "Suggests a category from the words in transactions you've already recorded.")
        case .tagValue:
            String(appLocalized: "Predicts each tag's expected monthly spending from your history.")
        }
    }

    public var icon: String {
        switch self {
        case .budgetValue: "dollarsign.bank.building"
        case .categoryName: "swatchpalette"
        case .tagValue: "tag"
        }
    }

    public var color: Color {
        switch self {
        case .budgetValue: .retroDenim
        case .categoryName: .retroOlive
        case .tagValue: .retroOrange
        }
    }
}
