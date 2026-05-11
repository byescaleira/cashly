//
//  StateFactoryTests.swift
//  CashlyKit
//
//  Verify the static factory contracts (`.new()` / `.edit(id:)`) on
//  every Add*State.
//

import Foundation
import Testing
import CashlyDomain
@testable import CashlyPresentation

@MainActor
@Suite("Add*State factories", .tags(.unit, .presentation, .local))
struct StateFactoryTests {

    // MARK: - AddUserState

    @Test("AddUserState.new() bootstraps with isNew=true and isLoading=true")
    func userNew() {
        let s = AddUserState.new()
        #expect(s.isNew == true)
        #expect(s.isLoading == true)
        #expect(s.isSaved == false)
        #expect(s.error == nil)
        #expect(!s.id.isEmpty)
        #expect(s.name.isEmpty)
        #expect(s.photo == nil)
    }

    @Test("AddUserState.edit(id:) carries id and sets isNew=false")
    func userEdit() {
        let s = AddUserState.edit(id: "user-42")
        #expect(s.id == "user-42")
        #expect(s.isNew == false)
    }

    // MARK: - AddBudgetState

    @Test("AddBudgetState.new() bootstraps as new+loading")
    func budgetNew() {
        let s = AddBudgetState.new()
        #expect(s.isNew == true)
        #expect(s.isLoading == true)
        #expect(s.amount == 0)
        #expect(s.category == nil)
        #expect(s.summary.isEmpty)
    }

    @Test("AddBudgetState.new(category:date:) prefills category and date")
    func budgetNewWithCategory() {
        let user = User(id: "u", name: "A", photo: "p")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let s = AddBudgetState.new(category: category, date: date)
        #expect(s.category == category)
        #expect(s.date == date)
    }

    @Test("AddBudgetState.edit(id:) carries id and is not new")
    func budgetEdit() {
        let s = AddBudgetState.edit(id: "budget-1")
        #expect(s.id == "budget-1")
        #expect(s.isNew == false)
    }

    // MARK: - AddCategoryState

    @Test("AddCategoryState.new()")
    func categoryNew() {
        let s = AddCategoryState.new()
        #expect(s.isNew == true)
        #expect(s.isLoading == true)
        #expect(s.name.isEmpty)
        #expect(s.user == nil)
    }

    @Test("AddCategoryState.edit(id:)")
    func categoryEdit() {
        let s = AddCategoryState.edit(id: "cat-1")
        #expect(s.id == "cat-1")
        #expect(s.isNew == false)
    }

    // MARK: - AddTagState

    @Test("AddTagState.new() and .edit(id:)")
    func tagFactories() {
        let new = AddTagState.new()
        #expect(new.name.isEmpty)
        #expect(new.user == nil)

        let edit = AddTagState.edit(id: "tag-1")
        #expect(edit.id == "tag-1")
        #expect(edit.isNew == false)
    }

    // MARK: - AddTransactionState

    @Test("AddTransactionState.new()")
    func transactionNew() {
        let s = AddTransactionState.new()
        #expect(s.isNew == true)
        #expect(s.isLoading == true)
        #expect(s.amount == 0)
        #expect(s.budget == nil)
        #expect(s.summary.isEmpty)
        #expect(s.participants.isEmpty)
        #expect(s.tags.isEmpty)
        #expect(s.installmentIsOn == false)
        #expect(s.installmentPlan == 1)
        #expect(s.status == .settled)
    }

    @Test("AddTransactionState.new(budget:date:) prefills budget + date")
    func transactionNewWithBudget() {
        let user = User(id: "u", name: "A", photo: "p")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "B")
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let s = AddTransactionState.new(budget: budget, date: date)
        #expect(s.budget == budget)
        #expect(s.date == date)
    }

    @Test("AddTransactionState.edit(id:)")
    func transactionEdit() {
        let s = AddTransactionState.edit(id: "tx-edit")
        #expect(s.id == "tx-edit")
        #expect(s.isNew == false)
    }

    // MARK: - MainState

    @Test("MainState default init has every router empty + loading")
    func mainStateDefault() {
        let s = MainState()
        #expect(s.isLoading == true)
        #expect(s.budgets.isEmpty)
        #expect(s.categories.isEmpty)
        #expect(s.transactions.isEmpty)
        #expect(s.tags.isEmpty)
        #expect(s.users.isEmpty)
        #expect(s.user == nil)
        #expect(s.predictedTransactionsAmount == 0)
        #expect(s.intelligenceRouter.navigationPath.isEmpty)
        #expect(s.categoryRouter.navigationPath.isEmpty)
        #expect(s.homeRouter.navigationPath.isEmpty)
        #expect(s.transactionRouter.navigationPath.isEmpty)
    }
}
