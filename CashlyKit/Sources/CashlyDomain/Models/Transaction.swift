//
//  Transaction.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

public struct Transaction: CashlyEntity, Sendable {
    public var id: UUID
    public var user: User
    public var participants: [User]
    public var category: Category
    public var amount: Double
    public var date: Date
    public var summary: String
    public var status: TransactionStatus
    
    public init(
        id: UUID,
        user: User,
        participants: [User],
        category: Category,
        amount: Double,
        date: Date,
        summary: String,
        status: TransactionStatus
    ) {
        self.id = id
        self.user = user
        self.participants = participants
        self.category = category
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
}
