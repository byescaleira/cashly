//
//  Category.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 29/08/25.
//

/// Spending category owned by a user (e.g. "Food", "Travel").
///
/// `color` is a hex string (`#RRGGBB`); the UI converts via
/// ``CashlyDesignSystem/SwiftUICore/Color/init(hex:)`` at the boundary.
/// `icon` is an SF Symbol name.
public struct Category: CashlyEntity, Sendable {
    public var id: String
    public var user: User
    public var name: String
    /// Hex string (`#RRGGBB`). Resolved at the UI layer.
    public var color: String
    /// SF Symbol name.
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
