//
//  Transaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

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
    
    public init(
        id: String,
        participants: [Participant],
        budget: Budget,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus
    ) {
        self.id = id
        self.participants = participants
        self.budget = budget
        self.amount = amount
        self.date = date
        self.summary = summary
        self.status = status
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
}
