//
//  Transaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import Foundation
import SwiftUI

public struct Transaction: CashlyEntity, Sendable {
    public var id: String
    public var participants: [Participant]
    public var budget: Budget
    public var amount: Double
    public var date: TimeInterval
    public var summary: String
    public var status: TransactionStatus
    public var splitMode: TransactionSplitMode?
    public var splitValue: Double?
    public var paymentsPlan: Int?
    
    public init(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?
    ) {
        self.id = id
        self.participants = participants
        self.budget = budget
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.paymentsPlan = paymentsPlan
    }
}

public enum TransactionStatus: Int, CaseIterable, CashlyEntity, Sendable {
    case pendingToReceive = 3
    case pendingToPay = 2
    case settled = 0
    case canceled = 1
    
    public var id: Int {
        rawValue
    }
    
    public var summary: String {
        switch self {
        case .pendingToReceive: return "Pending to Receive"
        case .pendingToPay: return "Pending to Pay"
        case .settled: return "Settled"
        case .canceled: return "Canceled"
        }
    }
    
    public var color: Color {
        switch self {
        case .pendingToReceive: return .blue
        case .pendingToPay: return .orange
        case .settled: return .green
        case .canceled: return .red
        }
    }
    
    public var icon: String {
        switch self {
        case .pendingToReceive: return "arrow.down"
        case .pendingToPay: return "arrow.up"
        case .settled: return "checkmark"
        case .canceled: return "xmark"
        }
    }
    
    public var reverse: TransactionStatus {
        switch self {
        case .pendingToReceive: return .pendingToPay
        case .pendingToPay: return .pendingToReceive
        case .settled: return .settled
        case .canceled: return .canceled
        }
    }
}

public enum TransactionSplitMode: Int, CaseIterable, CashlyEntity, Sendable {
    case equal = 0
    case fixedAmount = 1
    case percentage = 2
    case payerBased = 3
    
    public var id: Int { rawValue }
    
    public var summary: String {
        switch self {
        case .equal:
            return "Equal"
        case .fixedAmount:
            return "Fixed Amount"
        case .percentage:
            return "Percentage"
        case .payerBased:
            return "Payer Based"
        }
    }
    
    public var description: String {
        switch self {
        case .equal:
            return "Split the total equally among all participants."
        case .fixedAmount:
            return "Assign a fixed amount to each participant."
        case .percentage:
            return "Distribute the total based on percentages."
        case .payerBased:
            return "One participant pays the full amount, others are marked as owing."
        }
    }
    
    public func value(splitValue: Double?, amount: Double) -> Double? {
        guard let splitValue else { return nil }
        switch self {
        case .equal:
            if splitValue > .zero {
                return amount / splitValue
            }
        case .fixedAmount:
            return splitValue
        case .percentage:
            return amount * splitValue
        case .payerBased:
            return .zero
        }
        
        return nil
    }
}

public extension Set where Element == Transaction {
    func shareMessage(participants: Set<User>) -> String {
        let transactions = self.sorted(by: \.date, using: <)
        
        let totalAmount = transactions.reduce(.zero) { partialResult, transaction in
            let amount = participants.isEmpty ?
            (!transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount) : transaction.participants.filter {
                participants.contains($0.user)
            }.reduce(.zero) {
                $0 + (
                    $1.splitMode.value(
                        splitValue: $1.splitValue,
                        amount: transaction.amount
                    ) ?? .zero
                )
            }
            return partialResult + amount
        }
        
        var messages = "💸 Expenses Summary ".breakLine.breakLine
        
        messages += transactions.map { transaction in
            let date = transaction.date.date.string(with: .transaction(.shareMessage)) ?? ""
            let amount = participants.isEmpty ?
            (!transaction.participants.isEmpty ?
            transaction.splitValue ?? .zero : transaction.paymentsPlan != nil ?
            transaction.amount / (transaction.paymentsPlan ?? 1).double : transaction.amount) : transaction.participants.filter {
                participants.contains($0.user)
            }.reduce(.zero) {
                $0 + (
                    $1.splitMode.value(
                        splitValue: $1.splitValue,
                        amount: transaction.amount
                    ) ?? .zero
                )
            }
            let category = transaction.budget.category.name.capitalized
            var message = " 💵 \(amount.currency() ?? "")".breakLine
            message += " 🗓 \(date)".breakLine
            message += " 🏷️ \(category)".space + "-".space + transaction.summary.breakLine
            return message
        }.joined(separator: "\n").breakLine
        
        messages += "📊 Transactions: \(transactions.count)\n"
        messages += "💰 Total: \(totalAmount.currency() ?? "")"
        return messages
    }
}
