//
//  TransactionEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import SwiftData

@Model
public class TransactionEntity {
    @Attribute(.unique) public var id: String
    public var participants: [String]
    public var budget: String
    public var amount: Double
    public var date: TimeInterval
    public var summary: String
    public var status: Int
    public var splitMode: Int?
    public var splitValue: Double?
    
    public var yearMonth: Int {
        date.yearMonth
    }
    
    public init(
        id: String,
        participants: [String],
        budget: String,
        amount: Double,
        date: TimeInterval,
        summary: String,
        status: Int,
        splitMode: Int? = nil,
        splitValue: Double? = nil
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
    }
}
