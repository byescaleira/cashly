//
//  AddCategoryState.swift
//  CashlyKit
//

import Foundation
import CashlyDomain

public struct AddCategoryState: CashlyState {
    public var isLoading: Bool
    public var id: String
    public var user: User?
    public var name: String
    /// Hex string (e.g. "#FF8800"). UI converts via `Color(hex:)` at the
    /// boundary. keeps State `Sendable` for cross-isolation
    /// capture under PrismMiddleware.
    public var color: String
    public var icon: String
    public var isNew: Bool
    public var isSaved: Bool = false
    public var error: CashlyError?

    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        user != nil &&
        !icon.isEmpty
    }

    private init(
        isLoading: Bool = true,
        id: String = UUID().uuidString,
        user: User? = nil,
        name: String = "",
        color: String = "",
        icon: String = "",
        isNew: Bool = true,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.id = id
        self.user = user
        self.name = name
        self.color = color
        self.icon = icon
        self.isNew = isNew
        self.error = error
    }

    public static func new() -> AddCategoryState {
        AddCategoryState()
    }

    public static func edit(id: String) -> AddCategoryState {
        AddCategoryState(id: id, isNew: false)
    }
}
