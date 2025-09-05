//
//  AddCategoryState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain
import RyzeUI

public struct AddCategoryState: CashlyState {
    public var isLoading: Bool
    public var id: String
    public var user: User?
    public var name: String
    public var color: Color
    public var icon: String
    public var isNew: Bool
    public var error: CashlyError?
    
    public var canSave: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 &&
        user != nil &&
        !icon.isEmpty
    }
    
    public init(
        isLoading: Bool = true,
        id: String = UUID().uuidString,
        user: User? = nil,
        name: String = "",
        color: String = "",
        icon: String = "",
        isNew: Bool = false,
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.id = id
        self.user = user
        self.name = name
        self.color = Color(hex: color)
        self.icon = icon
        self.isNew = isNew
        self.error = error
    }
}
