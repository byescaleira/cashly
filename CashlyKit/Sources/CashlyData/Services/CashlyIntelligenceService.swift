//
//  CashlyIntelligenceService.swift
//  CashlyKit
//
//  Concrete training pipeline for the on-device models declared by
//  the `CashlyIntelligence` enum in Domain. Wraps
//  PrismTabularIntelligence + PrismTextIntelligence; called from
//  IntelligenceScreen via the train(model:user:transactions:tags:)
//  entry point.
//

import Foundation
import PrismIntelligence
import CashlyDomain

public struct CashlyIntelligenceService: Sendable {
    public init() {}

    public func train(
        model: CashlyIntelligence,
        user: User,
        transactions: [Transaction],
        tags: [Tag]
    ) async -> CashlyIntelligenceResult {
        let id = user.id + "_" + model.rawValue

        switch model {
        case .budgetValue:
            let data = Self.tabularData(model: model, transactions: transactions, tags: tags)
            let intelligence = PrismTabularIntelligence(data: data)
            return await intelligence.trainingRegressor(id: id, name: model.name, maxIterations: 3_500)
        case .categoryName:
            let data = Self.textData(model: model, transactions: transactions)
            let intelligence = PrismTextIntelligence(data: data)
            return await intelligence.trainingTextClassifier(id: id, name: model.name, maxIterations: 100)
        case .tagValue:
            let data = Self.tabularData(model: model, transactions: transactions, tags: tags)
            let intelligence = PrismTabularIntelligence(data: data)
            return await intelligence.trainingRegressor(id: id, name: model.name, maxIterations: 3_500)
        }
    }

    static func tabularData(
        model: CashlyIntelligence,
        transactions: [Transaction],
        tags: [Tag]
    ) -> [[String: Any]] {
        var data: [[String: Any]] = []

        switch model {
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
                data.append([
                    "date": date,
                    "category": category,
                    "target": target
                ])
            }
        case .tagValue:
            let transactions = Dictionary(grouping: transactions) {
                let summary = $0.summary.lowercased()
                let tag = tags.first(where: { summary.contains($0.name.lowercased()) })
                return tag
            }
            for transaction in transactions {
                if let tag = transaction.key {
                    let dict = Dictionary(grouping: transaction.value) { $0.date.yearMonth }
                    for (date, transactions) in dict {
                        let target = transactions.reduce(.zero) { $0 + $1.amount }
                        data.append([
                            "date": date,
                            "tag": tag.name,
                            "target": target
                        ])
                    }
                }
            }
        default:
            return []
        }

        return data
    }

    static func textData(
        model: CashlyIntelligence,
        transactions: [Transaction]
    ) -> [[String: String]] {
        var data: [[String: String]] = []

        switch model {
        case .categoryName:
            for transaction in transactions {
                data.append([
                    "text": transaction.summary,
                    "label": transaction.effectiveCategory.name
                ])
            }
        default:
            return []
        }

        return data
    }
}
