//
//  Tag.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

public struct Tag: CashlyEntity, Sendable {
    public var id: String
    public var user: User
    public var name: String
    public var color: String
    public var icon: String
    
    public init(
        id: String,
        user: User,
        name: String,
        color: String,
        icon: String
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
    }
}
