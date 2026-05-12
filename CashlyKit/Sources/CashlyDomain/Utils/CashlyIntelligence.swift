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

    /// Returns the trained model for this intelligence/user pair, or
    /// `nil` if no model has been persisted yet. Use
    /// ``placeholderModel(for:)`` if you need a metadata-only handle
    /// for upcoming training — the previous behaviour silently
    /// returned a fresh placeholder here, which made every
    /// `guard let` succeed and shipped untrained models into the
    /// prediction cache.
    public func model(for user: User) -> PrismIntelligenceModel? {
        let id = user.id + "_" + rawValue
        return PrismIntelligenceModel.models.first { $0.id == id }
    }

    /// A new, untrained model handle. Used by training flows that
    /// need to seed an entry on disk before the first `fit`.
    public func placeholderModel(for user: User) -> PrismIntelligenceModel {
        PrismIntelligenceModel(id: user.id + "_" + rawValue, name: name)
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
