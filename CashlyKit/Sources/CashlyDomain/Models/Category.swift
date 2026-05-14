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
    /// K8: user-controlled display order. Lower values render
    /// first. Defaults to 0 — ties break by name alphabetically so
    /// pre-K8 rows keep their old ordering.
    public var order: Int

    public init(
        id: String,
        user: User,
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

extension Category: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, user, name, color, icon, order
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(String.self, forKey: .id)
        self.user = try c.decode(User.self, forKey: .user)
        self.name = try c.decode(String.self, forKey: .name)
        self.color = try c.decode(String.self, forKey: .color)
        self.icon = try c.decode(String.self, forKey: .icon)
        self.order = try c.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}
