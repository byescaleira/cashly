import CashlyData
import CashlyDomain
import FeatureCore
import Foundation
import Testing

struct CaptureActionsTests {
    private let owner = User(id: "owner", name: "Ana", photo: "1")
    private let today = Date(timeIntervalSince1970: 1_790_000_000)

    private func actions() async throws -> (CaptureActions, Repositories) {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        for (id, name) in [("delivery", "Delivery"), ("fun", "Lazer"), ("market", "Mercado")] {
            try await repositories.categories.save(
                CashlyDomain.Category(
                    id: id, user: owner, name: name, color: "C2602A", icon: "cart"))
        }
        try await repositories.tags.save(
            Tag(id: "night", user: owner, name: "Noite", color: "2A7069", icon: "moon"))
        let today = today
        return (
            CaptureActions(repositories: repositories, user: owner, now: { today }), repositories
        )
    }

    @Test func suggestsTheMostUsedCategoryWithoutMemory() async throws {
        let (actions, repositories) = try await actions()
        let intents = IntentActions(repositories: repositories, user: owner, now: { today })
        _ = try await intents.addExpense(
            amount: 10, categoryID: "fun", summary: "Cinema", date: nil)
        _ = try await intents.addExpense(amount: 20, categoryID: "fun", summary: "Show", date: nil)
        _ = try await intents.addExpense(
            amount: 30, categoryID: "market", summary: "Pão", date: nil)
        let result = try await actions.capture(amount: 32.9, merchant: "IFD*IFOOD", card: "Nu")
        #expect(result.isNew)
        #expect(result.capture.suggestedCategoryID == "fun")
        #expect(result.capture.suggestedSummary == "IFD*IFOOD")
        #expect(result.capture.date == today)
        #expect(result.capture.card == "Nu")
        #expect(try await actions.frequentCategories().map(\.id) == ["fun", "market", "delivery"])
        #expect(try await actions.pending().map(\.id) == [result.capture.id])
    }

    @Test func suggestsFromMerchantMemoryAndDedupes() async throws {
        let (actions, repositories) = try await actions()
        try await repositories.captures.remember(
            MerchantMemory(
                key: "ifood", ownerID: owner.id, categoryID: "delivery", summary: "Jantar",
                tagIDs: ["night", "gone"], count: 3))
        let first = try await actions.capture(amount: 32.9, merchant: "iFood *123")
        #expect(first.capture.suggestedCategoryID == "delivery")
        #expect(first.capture.suggestedSummary == "Jantar")
        let again = try await actions.capture(amount: 32.9, merchant: "IFD*IFOOD")
        #expect(!again.isNew)
        #expect(again.capture.id == first.capture.id)
        #expect(try await actions.pending().count == 1)
    }

    @Test func acceptingCreatesTheExpenseAndReinforcesMemory() async throws {
        let (actions, repositories) = try await actions()
        try await repositories.captures.remember(
            MerchantMemory(
                key: "ifood", ownerID: owner.id, categoryID: "delivery", summary: "Jantar",
                tagIDs: ["night", "gone"], count: 3))
        let captured = try await actions.capture(amount: 32.9, merchant: "iFood").capture
        let transaction = try await actions.accept(captureID: captured.id)
        #expect(transaction.category.id == "delivery")
        #expect(transaction.summary == "Jantar")
        #expect(transaction.money.minorUnits == 3290)
        #expect(transaction.status == .settled)
        #expect(transaction.tagIDs == ["night"])
        #expect(transaction.date == today)
        let stored = try await repositories.captures.capture(id: captured.id)
        #expect(stored?.status == .accepted)
        #expect(stored?.transactionID == transaction.id)
        #expect(try await repositories.captures.memory(key: "ifood")?.count == 4)
        #expect(try await actions.accept(captureID: captured.id).id == transaction.id)
        #expect(try await actions.pending().isEmpty)
    }

    @Test func acceptingWithAnotherCategoryLearnsIt() async throws {
        let (actions, repositories) = try await actions()
        let captured = try await actions.capture(amount: 15, merchant: "Padaria São João").capture
        #expect(captured.suggestedCategoryID == nil)
        let transaction = try await actions.accept(captureID: captured.id, categoryID: "market")
        #expect(transaction.category.id == "market")
        #expect(transaction.summary == "Padaria São João")
        let memory = try await repositories.captures.memory(key: "padaria sao joao")
        #expect(memory?.categoryID == "market")
        #expect(memory?.count == 1)
        let next = try await actions.capture(amount: 9, merchant: "PADARIA SAO JOAO LTDA").capture
        #expect(next.suggestedCategoryID == "market")
    }

    @Test func dismissingHidesTheCapture() async throws {
        let (actions, _) = try await actions()
        let captured = try await actions.capture(amount: 15, merchant: "Uber").capture
        #expect(try await actions.dismiss(captureID: captured.id).status == .dismissed)
        #expect(try await actions.pending().isEmpty)
        await #expect(throws: CashlyError.self) {
            _ = try await actions.capture(amount: 0, merchant: "Uber")
        }
        await #expect(throws: CashlyError.self) {
            _ = try await actions.capture(amount: 5, merchant: "  ")
        }
    }
}
