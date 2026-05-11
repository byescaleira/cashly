//
//  CashlyIntelligence.swift
//  CashlyKit
//

import Foundation
import PrismIntelligence

public enum CashlyIntelligence: String, Identifiable, CaseIterable, Sendable {
    case budgetValue
    case categoryName
    case tagValue

    public func model(for user: User) -> PrismIntelligenceModel? {
        let id = user.id + "_" + rawValue
        return PrismIntelligenceModel.models.first { model in
            model.id == id
        } ?? PrismIntelligenceModel(
            id: id,
            name: name
        )
    }

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .budgetValue: return "Smart Budget"
        case .categoryName: return "Automatic Categorization"
        case .tagValue: return "Tag Spending Prediction"
        }
    }

    public var summary: String {
        switch self {
        case .budgetValue:
            return "Predicts the ideal monthly budget amount for each category by analyzing your spending history."
        case .categoryName:
            return "Automatically classifies your transactions into the correct category based on context."
        case .tagValue:
            return "Predicts the expected spending amount per tag for a specific month based on historical patterns."
        }
    }

    public var icon: String {
        switch self {
        case .budgetValue: return "dollarsign.bank.building.fill"
        case .categoryName: return "swatchpalette.fill"
        case .tagValue: return "tag.fill"
        }
    }

    public static func clean() {
        CashlyIntelligenceModel.clean()
    }
}

public typealias CashlyIntelligenceModel = PrismIntelligenceModel
public typealias CashlyIntelligenceResult = PrismIntelligenceResult
public typealias CashlyPrediction = PrismIntelligencePrediction
public typealias CashlyPredictionResult = PrismIntelligencePredictionResult
public typealias CashlyPredictionInput = PrismIntelligencePredictionInput

extension PrismIntelligencePredictionInput: @retroactive @unchecked Sendable {}
public typealias CashlyFileManager = PrismFileManager
public typealias CashlyTabularData = [String: Any]

public extension CashlyTabularData {
    static func budgetValue(date: Int, category: String) -> [String: Any] {
        [
            "date": date,
            "category": category
        ]
    }

    static func tagValue(date: Int, tag: String) -> [String: Any] {
        [
            "date": date,
            "tag": tag
        ]
    }
}
