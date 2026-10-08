import Foundation

public enum CashlyIntelligence: String, Identifiable, CaseIterable, Codable, Sendable {
    case budgetValue
    case categoryName
    case tagValue

    public var id: String {
        rawValue
    }

    public var name: String {
        switch self {
        case .budgetValue:
            return "Smart Budget"
        case .categoryName:
            return "Automatic Categorization"
        case .tagValue:
            return "Tag Spending Prediction"
        }
    }

    public var summary: String {
        switch self {
        case .budgetValue:
            return
                "Estimates monthly spending per category using the average of up to six recorded months."
        case .categoryName:
            return "Suggests a category using words from your previously recorded transactions."
        case .tagValue:
            return
                "Predicts the expected spending amount per tag for a specific month based on historical patterns."
        }
    }

    public var icon: String {
        switch self {
        case .budgetValue: return "dollarsign.bank.building.fill"
        case .categoryName: return "swatchpalette.fill"
        case .tagValue: return "tag.fill"
        }
    }

}
