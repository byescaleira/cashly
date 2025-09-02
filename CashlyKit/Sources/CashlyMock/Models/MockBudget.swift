//
//  MockBudget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import CashlyDomain
import RyzeFoundation
import RyzeUI

extension Budget: RyzeMock {
    public static var mock: Budget {
        Budget(
            id: .init(),
            amount: .random(in: 100 ... 1_000),
            category: .mock,
            date: .now,
            summary: .ryzePreviewDescription
        )
    }
}
