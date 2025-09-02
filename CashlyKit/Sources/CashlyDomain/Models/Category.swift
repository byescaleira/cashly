//
//  Category.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

public struct Category: CashlyEntity, Sendable {
    public var id: UUID
    public var name: String
    public var color: String
    public var icon: String
    
    public init(
        id: UUID,
        name: String,
        color: String,
        icon: String
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
    }
}
