//
//  CategoryEntity.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

import SwiftData

@Model
public class CategoryEntity {
    public var id: String = ""
    public var name: String = ""
    public var user: String = ""
    public var color: String = ""
    public var icon: String = ""
    /// K8: user-controlled display order, ascending. Defaults to 0
    /// so pre-K8 rows materialize together at the top until the
    /// user reorders them.
    public var order: Int = 0

    public init(
        id: String,
        user: String,
        name: String,
        color: String,
        icon: String,
        order: Int = 0
    ) {
        self.id = id
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
        self.order = order
    }
}
