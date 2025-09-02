//
//  CommonScenario.swift
//  CashlyKit
//
//  Created by Rafael Escaleira on 30/08/25.
//

struct TestScenario<Input: Sendable, Expected: Sendable>: Sendable {
    let input: Input
    let expected: Expected
    let description: String
}
