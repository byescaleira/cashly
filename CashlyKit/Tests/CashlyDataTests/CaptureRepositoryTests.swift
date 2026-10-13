import CashlyData
import CashlyDomain
import Foundation
import Testing

struct CaptureRepositoryTests {
    private let date = Date(timeIntervalSince1970: 1_790_000_000)

    private func capture(_ db: TestDatabase, merchant: String, cents: Int64 = 3290) -> Capture {
        Capture(
            ownerID: db.owner.id, money: Money(minorUnits: cents), merchant: merchant, card: "Nu",
            date: date, source: .wallet, suggestedSummary: merchant)
    }

    @Test func storesAndListsByStatus() async throws {
        let db = try await TestDatabase()
        let stored = try await db.repositories.captures.save(capture(db, merchant: "IFD*IFOOD"))
        #expect(stored.merchant == "IFD*IFOOD")
        #expect(stored.card == "Nu")
        #expect(try await db.repositories.captures.capture(id: stored.id)?.money.minorUnits == 3290)
        var dismissed = stored
        dismissed.status = .dismissed
        _ = try await db.repositories.captures.save(dismissed)
        #expect(try await db.repositories.captures.captures(status: .pending).isEmpty)
        #expect(try await db.repositories.captures.captures(status: .dismissed).count == 1)
        #expect(try await db.repositories.captures.captures(status: nil).count == 1)
        #expect(try await db.friendRepositories.captures.captures(status: nil).isEmpty)
    }

    @Test func sameMinuteAmountAndMerchantIsOneCapture() async throws {
        let db = try await TestDatabase()
        let first = try await db.repositories.captures.save(capture(db, merchant: "IFD*IFOOD"))
        var twin = capture(db, merchant: "iFood 9")
        twin.date = date.addingTimeInterval(30)
        let second = try await db.repositories.captures.save(twin)
        #expect(second.id == first.id)
        var later = capture(db, merchant: "iFood")
        later.date = date.addingTimeInterval(60)
        #expect(try await db.repositories.captures.save(later).id != first.id)
        #expect(try await db.repositories.captures.captures(status: .pending).count == 2)
    }

    @Test func rejectsOtherOwnersAndEmptyAmounts() async throws {
        let db = try await TestDatabase()
        await #expect(throws: CashlyError.self) {
            _ = try await db.friendRepositories.captures.save(capture(db, merchant: "Uber"))
        }
        await #expect(throws: CashlyError.self) {
            _ = try await db.repositories.captures.save(capture(db, merchant: "Uber", cents: 0))
        }
    }

    @Test func remembersMerchantsPerOwner() async throws {
        let db = try await TestDatabase()
        let captures = db.repositories.captures
        #expect(try await captures.memory(key: "ifood") == nil)
        try await captures.remember(
            MerchantMemory(
                key: "ifood", ownerID: db.owner.id, categoryID: db.category.id,
                summary: "Delivery", tagIDs: ["t1"], count: 1))
        try await captures.remember(
            MerchantMemory(
                key: "ifood", ownerID: db.owner.id, categoryID: db.category.id,
                summary: "Jantar", count: 2))
        let memory = try await captures.memory(key: "ifood")
        #expect(memory?.summary == "Jantar")
        #expect(memory?.count == 2)
        #expect(memory?.tagIDs.isEmpty == true)
        #expect(try await db.friendRepositories.captures.memory(key: "ifood") == nil)
    }

    @Test func eraseAllRemovesCaptures() async throws {
        let db = try await TestDatabase()
        _ = try await db.repositories.captures.save(capture(db, merchant: "Uber"))
        _ = try await db.database.backup.eraseAll()
        try await db.database.repositories(for: nil).users.save(db.owner)
        #expect(try await db.repositories.captures.captures(status: nil).isEmpty)
    }
}
