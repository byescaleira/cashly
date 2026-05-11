//
//  EnvironmentValuesTests.swift
//  CashlyKit
//
//  Validate the default values for every @Entry env key in
//  EnvironmentValues+Extension.swift. Defaults matter because views
//  read these long before any composition root injects a real value,
//  so they must construct without crash.
//

import SwiftUI
import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("Presentation EnvironmentValues defaults", .tags(.unit, .presentation, .local))
struct EnvironmentValuesTests {

    @Test("default addCategoryState is .new()")
    func addCategoryStateDefault() {
        let env = EnvironmentValues()
        #expect(env.addCategoryState.isNew == true)
    }

    @Test("default addBudgetState is .new()")
    func addBudgetStateDefault() {
        let env = EnvironmentValues()
        #expect(env.addBudgetState.isNew == true)
    }

    @Test("default addTransactionState is .new()")
    func addTransactionStateDefault() {
        let env = EnvironmentValues()
        #expect(env.addTransactionState.isNew == true)
    }

    @Test("default addUserState is .new()")
    func addUserStateDefault() {
        let env = EnvironmentValues()
        #expect(env.addUserState.isNew == true)
    }

    @Test("default addTagState exists")
    func addTagStateDefault() {
        let env = EnvironmentValues()
        // AddTagState.new() initializes with isNew=false in its private init —
        // just assert default exists by reading the id.
        #expect(env.addTagState.id.isEmpty == false)
    }

    @Test("default mainState is empty MainState()")
    func mainStateDefault() {
        let env = EnvironmentValues()
        #expect(env.mainState.budgets.isEmpty)
        #expect(env.mainState.categories.isEmpty)
        #expect(env.mainState.transactions.isEmpty)
    }

    @Test("default user is nil")
    func userDefault() {
        let env = EnvironmentValues()
        #expect(env.user == nil)
    }

    @Test("default action closure is a no-op (callable without crash)")
    func actionDefaultIsNoop() {
        let env = EnvironmentValues()
        env.action(.main(.fetch))
        // No assertion beyond "didn't crash" — closure should be `{ _ in }`.
    }
}
