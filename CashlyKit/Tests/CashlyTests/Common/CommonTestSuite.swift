//
//  CommonTestSuite.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 30/08/25.
//

import Testing
import CashlyDomain
import CashlyMock

@Suite
struct CommonTestSuite {
    let budgetUseCase: BudgetUseCase
    let categoryUseCase: CategoryUseCase
    
    init() {
        let factory = MockCashlyFactory()
        budgetUseCase = factory.makeBudgetUseCase()
        categoryUseCase = factory.makeCategoryUseCase()
    }
    
    func assertEqual<T: Equatable>(
        _ actual: T,
        _ expected: T,
        message: String? = nil
    ) {
        #expect(
            actual == expected,
            .init(stringLiteral: message ?? "Expected \(expected) but got \(actual)")
        )
    }
}
