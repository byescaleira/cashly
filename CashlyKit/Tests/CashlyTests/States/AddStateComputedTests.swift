//
//  AddStateComputedTests.swift
//  CashlyKit
//
//  canSave + derived helpers for each Add*State.
//

import Foundation
import Testing
import CashlyDomain
import CashlyMock
@testable import CashlyPresentation

@MainActor
@Suite("Add*State.canSave", .tags(.unit, .presentation, .local))
struct AddStateComputedTests {

    // MARK: - AddUserState

    @Test("AddUserState.canSave requires name ≥ 3 and valid URL photo")
    func userCanSave() {
        var state = AddUserState.new()
        state.name = "ab"
        state.photo = "https://x/a.png"
        #expect(state.canSave == false)

        state.name = "Alice"
        state.photo = nil
        #expect(state.canSave == false)

        state.name = "Alice"
        state.photo = "https://x/a.png"
        #expect(state.canSave == true)
    }

    @Test("AddUserState.photos returns 50 ids per gender")
    func userPhotosGender() {
        let state = AddUserState.new()
        let male = state.photos(for: 0)
        let female = state.photos(for: 1)
        #expect(male.count == 50)
        #expect(female.count == 50)
        #expect(male.first == "1")
        #expect(male.last == "50")
        #expect(female.first == "51")
        #expect(female.last == "100")
    }

    // MARK: - AddCategoryState

    @Test("AddCategoryState.canSave requires name ≥ 3 + user + non-empty icon")
    func categoryCanSave() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        var state = AddCategoryState.new()
        state.name = "Food"
        state.user = user
        state.icon = "fork.knife"
        #expect(state.canSave == true)

        state.name = "ab"
        #expect(state.canSave == false)

        state.name = "Food"
        state.user = nil
        #expect(state.canSave == false)

        state.user = user
        state.icon = ""
        #expect(state.canSave == false)
    }

    // MARK: - AddTagState

    @Test("AddTagState.canSave mirrors AddCategoryState rules")
    func tagCanSave() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        var state = AddTagState.new()
        state.name = "Coffee"
        state.user = user
        state.icon = "cup.and.saucer"
        #expect(state.canSave == true)

        state.user = nil
        #expect(state.canSave == false)
    }

    // MARK: - AddBudgetState

    @Test("AddBudgetState.canSave requires amount > 0 + category + summary length > 3")
    func budgetCanSave() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        var state = AddBudgetState.new()
        state.category = category
        state.amount = 100
        state.summary = "Valid"
        #expect(state.canSave == true)

        state.amount = 0
        #expect(state.canSave == false)

        state.amount = 100
        state.category = nil
        #expect(state.canSave == false)

        state.category = category
        state.summary = "ab"
        #expect(state.canSave == false)
    }

    @Test("AddBudgetState.user is category.user")
    func budgetUserDerivedFromCategory() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        var state = AddBudgetState.new()
        #expect(state.user == nil)
        state.category = category
        #expect(state.user == user)
    }

    @Test("AddBudgetState.yearMonth packs date.timeIntervalSince1970")
    func budgetYearMonth() {
        var state = AddBudgetState.new()
        state.date = Date(timeIntervalSince1970: 0) // 1970-01
        #expect(state.yearMonth == 197001)
    }

    // MARK: - AddTransactionState

    @Test("AddTransactionState.canSave needs user + category + budget + amount + summary")
    func transactionCanSave() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let category = CashlyDomain.Category(id: "c", user: user, name: "C", color: "#000", icon: "x")
        let budget = Budget(id: "b", amount: 100, category: category, date: 202604, summary: "s")

        var state = AddTransactionState.new()
        state.budget = budget
        state.amount = 50
        state.summary = "Dinner here"
        #expect(state.canSave == true)

        state.summary = "ab"
        #expect(state.canSave == false)

        state.summary = "Dinner here"
        state.amount = 0
        #expect(state.canSave == false)

        state.amount = 50
        state.budget = nil
        #expect(state.canSave == false)
    }

    @Test("AddTransactionState.categories projects budget.category")
    func transactionCategoriesProjection() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let cat1 = CashlyDomain.Category(id: "c1", user: user, name: "C1", color: "#000", icon: "x")
        let cat2 = CashlyDomain.Category(id: "c2", user: user, name: "C2", color: "#000", icon: "y")
        let b1 = Budget(id: "b1", amount: 1, category: cat1, date: 202604, summary: "s")
        let b2 = Budget(id: "b2", amount: 1, category: cat2, date: 202604, summary: "s")
        var state = AddTransactionState.new()
        state.budgets = [b1, b2]
        let cats = state.categories
        #expect(cats.contains(cat1))
        #expect(cats.contains(cat2))
    }

    @Test("AddTransactionState.summaryTags filters tags whose name appears in summary")
    func transactionSummaryTagsFilter() {
        let user = User(id: "u", name: "A", photo: "https://x/a.png")
        let tagCoffee = Tag(id: "t1", user: user, name: "Coffee", color: "#000", icon: "x")
        let tagDinner = Tag(id: "t2", user: user, name: "Dinner", color: "#000", icon: "y")
        let tagOther = Tag(id: "t3", user: user, name: "Travel", color: "#000", icon: "z")

        var state = AddTransactionState.new()
        state.tags = [tagCoffee, tagDinner, tagOther]
        state.summary = "Morning coffee with Sarah"

        let matched = state.summaryTags
        #expect(matched.contains(tagCoffee))
        #expect(matched.contains(tagDinner) == false)
        #expect(matched.contains(tagOther) == false)
    }
}
