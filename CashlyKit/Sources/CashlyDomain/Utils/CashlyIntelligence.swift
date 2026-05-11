//
//  CashlyIntelligence.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 19/09/25.
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
    
    func tabularData(transactions: [Transaction], tags: [Tag]) -> [[String: Any]] {
        var data: [[String: Any]] = []
        
        switch self {
        case .budgetValue:
            let dict = Dictionary(grouping: transactions, by: \.budget)
            for item in dict {
                let date = item.key.date
                let category = item.key.category.name
                let target = item.value.reduce(.zero) { partialResult, transaction in
                    let amount = !transaction.participants.isEmpty ?
                    transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
                    transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount
                    return partialResult + amount
                }
                data.append(
                    [
                        "date": date,
                        "category": category,
                        "target": target
                    ]
                )
            }
        case .tagValue:
            let transactions = Dictionary(grouping: transactions) {
                let summary = $0.summary.lowercased()
                let tag = tags.first(where: { summary.contains($0.name.lowercased()) })
                return tag
            }
            for transaction in transactions {
                if let tag = transaction.key {
                    let dict = Dictionary(grouping: transaction.value) {
                        $0.date.yearMonth
                    }
                    for (date, transactions) in dict {
                        let target = transactions.reduce(.zero) { $0 + $1.amount }
                        data.append(
                            [
                                "date": date,
                                "tag": tag.name,
                                "target": target
                            ]
                        )
                    }
                }
            }
        default:
            return []
        }
        
        return data
    }
    
    func textData(transactions: [Transaction]) -> [[String: String]] {
        var data: [[String: String]] = []
        
        switch self {
        case .categoryName:
            for transaction in transactions {
                data.append(
                    [
                        "text": transaction.summary,
                        "label": transaction.budget.category.name
                    ]
                )
            }
        default:
            return []
        }
        
        return data
    }
    
    public func train(
        user: User,
        transactions: [Transaction],
        tags: [Tag]
    ) async -> CashlyIntelligenceResult {
        let id = user.id + "_" + rawValue
        
        switch self {
        case .budgetValue:
            let data = tabularData(transactions: transactions, tags: tags)
            let intelligence = PrismTabularIntelligence(data: data)
            return await intelligence.trainingRegressor(id: id, name: name, maxIterations: 3_500)
        case .categoryName:
            let data = textData(transactions: transactions)
            let intelligence = PrismTextIntelligence(data: data)
            return await intelligence.trainingTextClassifier(id: id, name: name, maxIterations: 100)
        case .tagValue:
            let data = tabularData(transactions: transactions, tags: tags)
            let intelligence = PrismTabularIntelligence(data: data)
            return await intelligence.trainingRegressor(id: id, name: name, maxIterations: 3_500)
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
