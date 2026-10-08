import CashlyDomain

extension CashlyIntelligence {
    public var name: String {
        switch self {
        case .budgetValue: "Smart Budget"
        case .categoryName: "Automatic Categorization"
        case .tagValue: "Tag Spending Prediction"
        }
    }

    public var summary: String {
        switch self {
        case .budgetValue:
            "Estimates monthly spending per category using the average of up to six recorded months."
        case .categoryName:
            "Suggests a category using words from your previously recorded transactions."
        case .tagValue:
            "Predicts the expected spending amount per tag for a specific month based on historical patterns."
        }
    }

    public var icon: String {
        switch self {
        case .budgetValue: "dollarsign.bank.building.fill"
        case .categoryName: "swatchpalette.fill"
        case .tagValue: "tag.fill"
        }
    }
}
