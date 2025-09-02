//
//  MockCategory.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import CashlyDomain
import RyzeFoundation

extension CashlyDomain.Category: RyzeMock {
    public static var mock: CashlyDomain.Category {
        Category(
            id: UUID(),
            name: "Mock Category",
            color: "#9C9C9C",
            icon: "iphone"
        )
    }
}
