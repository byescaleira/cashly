//
//  TransactionEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import SwiftData

@Model
public class TransactionEntity {
    @Attribute(.unique) public var id: UUID
    public var user: UUID
    public var participants: [UUID]
    public var category: UUID
    public var amount: Double
    public var date: TimeInterval
    public var summary: String
    public var status: Int
    
    public init(
        id: UUID,
        user: UUID,
        participants: [UUID],
        category: UUID,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int
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
