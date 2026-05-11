//
//  MockBudget.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 31/08/25.
//

import CashlyDomain
import CashlyResource
import PrismFoundation

extension Budget: PrismMock {
    public static var mock: Budget {
        mocks.randomElement()!
    }
    
    public static var mocks: [Budget] {
        let budgets: [Budget] = (try? CashlyResourceFile.budgets.decoded()) ?? []
        return budgets.sorted { $0.date > $1.date }
    }
}
