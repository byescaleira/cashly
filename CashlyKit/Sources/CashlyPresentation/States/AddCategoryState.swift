//
//  AddCategoryState.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 01/09/25.
//

import CashlyDomain

public struct AddCategoryState: CashlyState {
    public var isLoading: Bool
    public var id: UUID
    public var name: String
    public var color: String
    public var icon: String
    public var error: CashlyError?
    
    public init(
        isLoading: Bool = true,
        id: UUID = .init(),
        name: String = "",
        color: String = "",
        icon: String = "",
        error: CashlyError? = nil
    ) {
        self.isLoading = isLoading
        self.id = id
        self.name = name
        self.color = color
        self.icon = icon
        self.error = error
    }
}
