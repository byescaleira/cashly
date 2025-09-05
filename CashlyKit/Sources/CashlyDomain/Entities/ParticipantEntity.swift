//
//  ParticipantEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 05/09/25.
//

import SwiftData

@Model
public class ParticipantEntity {
    @Attribute(.unique) public var id: String
    public var user: String
    public var name: String
    public var photo: String
    public var splitMode: Int
    public var splitValue: Double
    public var status: Int
    public var transaction: String
    
    public init(
        id: String,
        user: String,
        name: String,
        photo: String,
        splitMode: Int,
        splitValue: Double,
        status: Int,
        transaction: String
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.photo = photo
        self.splitMode = splitMode
        self.splitValue = splitValue
        self.status = status
        self.transaction = transaction
    }
}
