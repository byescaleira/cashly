//
//  CashlyPresentationFactoryTests.swift
//  CashlyKit
//
//  Verify the factory at the composition root builds every store
//  with the expected initial state baseline.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("CashlyPresentationFactory", .tags(.unit, .presentation, .local))
struct CashlyPresentationFactoryTests {

    // Inject the MockCashlyFactory (which conforms to both
    // CashlyDataFactoryProtocol and CashlyPresentationFactoryProtocol)
    // to avoid SwiftData on-disk store init.
    private let dataFactory: CashlyDataFactoryProtocol = MockCashlyFactory()

    @Test("makeAddCategoryStore returns a store at AddCategoryState.new() baseline")
    func makeAddCategoryStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeAddCategoryStore()
        #expect(store.state.isNew == true)
        #expect(store.state.isLoading == true)
    }

    @Test("makeAddBudgetStore returns a store at AddBudgetState.new() baseline")
    func makeAddBudgetStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeAddBudgetStore()
        #expect(store.state.amount == 0)
        #expect(store.state.category == nil)
    }

    @Test("makeAddTransactionStore returns a store at AddTransactionState.new() baseline")
    func makeAddTransactionStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeAddTransactionStore()
        #expect(store.state.budget == nil)
        #expect(store.state.installmentPlan == 1)
    }

    @Test("makeAddUserStore returns a store at AddUserState.new() baseline")
    func makeAddUserStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeAddUserStore()
        #expect(store.state.isNew == true)
        #expect(store.state.name.isEmpty)
    }

    @Test("makeAddTagStore returns a store at AddTagState.new() baseline")
    func makeAddTagStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeAddTagStore()
        #expect(store.state.name.isEmpty)
    }

    @Test("makeMainStore returns a store at MainState() baseline")
    func makeMainStore() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let store = factory.makeMainStore()
        #expect(store.state.isLoading == true)
        #expect(store.state.budgets.isEmpty)
    }

    @Test("two calls return independent store instances")
    func storesAreIndependent() {
        let factory = CashlyPresentationFactory(dataFactory: dataFactory)
        let a = factory.makeAddUserStore()
        let b = factory.makeAddUserStore()
        a.cashlyMutate(\.name, "Alice")
        #expect(a.state.name == "Alice")
        #expect(b.state.name.isEmpty)
    }
}
