//
//  Participant.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//


public struct Participant: CashlyEntity, Sendable {
    public var id: String
    public var user: User
    public var splitMode: TransactionSplitMode
    public var splitValue: Double
    public var status: TransactionStatus
    public var transaction: String
    
    public init(
        id: String,
        user: User,
        splitMode: TransactionSplitMode,
        splitValue: Double,
        status: TransactionStatus,
        transaction: String
    ) {
        self.id = id
        self.user = user
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.status = status
        self.transaction = transaction
    }
    
    public static var empty: Participant {
        Participant(
            id: "",
            user: .empty,
            splitMode: .equal,
            splitValue: .zero,
            status: .settled,
            transaction: ""
        )
    }
}
