import CashlyDomain
import Foundation
import Testing

struct WidgetSnapshotFocusTests {
    private func line(_ id: String, planned: Int64, spent: Int64) -> WidgetSnapshot.BudgetLine {
        WidgetSnapshot.BudgetLine(
            id: "budget-\(id)", categoryID: id, categoryName: id.capitalized, color: "C2602A",
            icon: "cart", plannedMinorUnits: planned, spentMinorUnits: spent)
    }

    private func makeSnapshot(focus: String? = nil, name: String? = nil) throws -> WidgetSnapshot {
        WidgetSnapshot(
            userID: "owner", userName: "Ana", month: try #require(YearMonth(year: 2026, month: 10)),
            currencyCode: "BRL", plannedMinorUnits: 300, spentMinorUnits: 200,
            incomeMinorUnits: 0, focusCategoryID: focus, focusCategoryName: name,
            budgets: [
                line("food", planned: 100, spent: 50),
                line("fun", planned: 100, spent: 120),
                line("home", planned: 100, spent: 30),
                line("empty", planned: 0, spent: 10),
            ])
    }

    @Test func automaticFollowsTheBudgetClosestToItsLimit() throws {
        let snapshot = try makeSnapshot()
        #expect(snapshot.isFocusAutomatic)
        #expect(snapshot.focusLine?.categoryID == "fun")
    }

    @Test func automaticBreaksTiesWithTheBiggerPlan() throws {
        let snapshot = WidgetSnapshot(
            userID: "owner", userName: "Ana", month: YearMonth(.now), currencyCode: "BRL",
            plannedMinorUnits: 0, spentMinorUnits: 0, incomeMinorUnits: 0,
            budgets: [
                line("small", planned: 100, spent: 50), line("big", planned: 400, spent: 200),
            ])
        #expect(snapshot.focusLine?.categoryID == "big")
    }

    @Test func chosenCategoryWinsOverAutomatic() throws {
        let snapshot = try makeSnapshot(focus: "home", name: "Home")
        #expect(snapshot.focusLine?.categoryID == "home")
    }

    @Test func chosenCategoryWithoutBudgetHasNoLineButKeepsTheName() throws {
        let snapshot = try makeSnapshot(focus: "travel", name: "Travel")
        #expect(snapshot.focusLine == nil)
        #expect(snapshot.focusCategoryName == "Travel")
    }

    @Test func focusingSwapsTheChoiceAndItsName() throws {
        let snapshot = try makeSnapshot(focus: "travel", name: "Travel")
        let food = snapshot.focusing(categoryID: "food")
        #expect(food.focusCategoryID == "food")
        #expect(food.focusCategoryName == "Food")
        #expect(food.focusLine?.categoryID == "food")
        #expect(food.focusing(categoryID: nil).isFocusAutomatic)
        #expect(snapshot.focusing(categoryID: "travel") == snapshot)
    }

    @Test func overviewKeepsCategoryIDsAndTheFocus() throws {
        let owner = User(id: "owner", name: "Ana", photo: "1")
        let month = try #require(YearMonth(year: 2026, month: 10))
        let food = CashlyDomain.Category(
            id: "food", user: owner, name: "Mercado", color: "5F7A2E", icon: "cart")
        let travel = CashlyDomain.Category(
            id: "travel", user: owner, name: "Viagem", color: "3D5F86", icon: "airplane")
        var overview = CashlyOverview()
        overview.budgets = [
            Budget(
                id: "b1", money: Money(minorUnits: 500), category: food, month: month,
                summary: "", isConflicted: false)
        ]
        let snapshot = WidgetSnapshot(
            user: owner, month: month, overview: overview, currencyCode: "BRL", focus: travel)
        #expect(snapshot.budgets.first?.categoryID == "food")
        #expect(snapshot.focusCategoryID == "travel")
        #expect(snapshot.focusCategoryName == "Viagem")
        #expect(snapshot.focusLine == nil)
    }

    @Test func snapshotsWrittenBeforeTheFocusIDStillDecode() throws {
        let json = """
            {"userID":"owner","userName":"Ana","year":2026,"month":10,"currencyCode":"BRL",
            "plannedMinorUnits":100,"spentMinorUnits":40,"incomeMinorUnits":0,"transactionCount":2,
            "focusCategory":"Mercado","budgets":[{"id":"b1","categoryName":"Mercado","color":"5F7A2E",
            "icon":"cart","plannedMinorUnits":100,"spentMinorUnits":40}],"bills":[],
            "generatedAt":"2026-10-14T12:00:00Z"}
            """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(WidgetSnapshot.self, from: Data(json.utf8))
        #expect(snapshot.isFocusAutomatic)
        #expect(snapshot.budgets.first?.categoryID == nil)
        #expect(snapshot.focusLine?.id == "b1")
    }
}
