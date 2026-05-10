//
//  MockBudget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import CashlyDomain
import CashlyResource
import RyzeFoundation

extension Budget: RyzeMock {
    public static var mock: Budget {
        mocks.randomElement()!
    }
    
    public static var mocks: [Budget] {
        let budgets: [Budget] = CashlyResourceFile.budgets.decoded()
        return budgets.sorted { $0.date > $1.date }
    }
}
