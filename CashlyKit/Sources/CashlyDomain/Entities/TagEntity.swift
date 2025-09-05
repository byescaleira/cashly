//
//  TagEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 03/09/25.
//

import SwiftData

@Model
public class TagEntity {
    @Attribute(.unique) public var id: String
    @Attribute(.spotlight) public var name: String
    public var user: String
    public var color: String
    public var icon: String
    
    public init(
        id: String,
        user: String,
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
