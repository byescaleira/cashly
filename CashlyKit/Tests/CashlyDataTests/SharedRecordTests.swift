import CashlyDomain
import Foundation
import Testing

@testable import CashlyData

struct SharedRecordTests {
    @Test func keysRoundTripThroughRecordNames() throws {
        let key = SharedRecord.Key(kind: .transaction, id: "A1.B2")
        #expect(key.name == "Transaction.A1.B2")
        #expect(SharedRecord.Key(name: key.name) == key)
        #expect(SharedRecord.Key(name: "Unknown.1") == nil)
        #expect(SharedRecord.Key(name: "Profile.") == nil)
        #expect(SharedRecord.Key(name: "Profile") == nil)
    }

    @Test func planSavesChangesAndDeletesWhatVanished() {
        let plan = SharedSyncPlan(
            current: ["a": "1", "b": "2", "c": "3"], confirmed: ["a": "1", "b": "0", "d": "4"])
        #expect(plan.saves == ["b", "c"])
        #expect(plan.deletes == ["d"])
        #expect(SharedSyncPlan(current: ["a": "1"], confirmed: ["a": "1"]).isEmpty)
    }

    @Test func zonesMapToProfiles() {
        let zone = SharedZone.id(for: "home", owner: "_owner")
        #expect(zone.zoneName == "profile.home")
        #expect(SharedZone.profileID(of: zone) == "home")
        #expect(SharedZone.profileID(of: SharedProfileSync.coreDataZone) == nil)
    }

    @Test func profileExportsEveryKindItOwns() async throws {
        let device = try await SharedDevice()
        try await device.seed()
        let records = try await device.database.store.sharedRecords(profileID: device.home.id)
        let kinds = Set(records.map(\.key.kind))
        #expect(kinds == Set(SharedRecord.Kind.allCases))
        let other = try await device.database.store.sharedRecords(profileID: device.trip.id)
        #expect(other.map(\.key.kind) == [.profile])
    }

    @Test func recordsRebuildTheSameProfileOnAnotherDevice() async throws {
        let first = try await SharedDevice()
        try await first.seed()
        let second = try await SharedDevice()
        let records = try await first.database.store.sharedRecords(profileID: first.home.id)
        try await second.database.store.applyShared(records.reversed(), deleting: [])
        let rebuilt = try await second.database.store.sharedRecords(profileID: first.home.id)
        #expect(
            Dictionary(uniqueKeysWithValues: rebuilt.map { ($0.name, $0.digest) })
                == Dictionary(uniqueKeysWithValues: records.map { ($0.name, $0.digest) }))
        let copy = second.database.repositories(for: first.home.id)
        let transaction = try await copy.transactions.transaction(id: "dinner")
        #expect(transaction?.money.minorUnits == 12_000)
        #expect(transaction?.participants.count == 1)
        #expect(try await copy.tags.tag(id: "tag")?.name == "Market")
    }

    @Test func incomingChangesReplaceAndDelete() async throws {
        let device = try await SharedDevice()
        try await device.seed()
        let store = device.database.store
        let renamed = try SharedRecord(
            kind: .profile, id: device.home.id,
            row: ["id": device.home.id, "name": "Our Home", "photo": ""])
        try await store.applyShared(
            [renamed], deleting: [SharedRecord.Key(kind: .tag, id: "tag")])
        let scoped = device.database.repositories(for: device.home.id)
        #expect(try await scoped.users.user(id: device.home.id)?.name == "Our Home")
        #expect(try await scoped.tags.tag(id: "tag") == nil)
    }

    @Test func confirmedParticipantsStayWhileTheirTransactionIsMissing() async throws {
        let first = try await SharedDevice()
        try await first.seed()
        let records = try await first.database.store.sharedRecords(profileID: first.home.id)
        let participant = try #require(records.first { $0.key.kind == .participant })
        let second = try await SharedDevice()
        try await second.database.store.applyShared([participant], deleting: [])
        let without = try await second.database.store.sharedRecords(profileID: first.home.id)
        #expect(!without.contains { $0.key.kind == .participant })
        let known = try await second.database.store.sharedRecords(
            profileID: first.home.id, known: [participant.name])
        #expect(known.contains { $0.name == participant.name })
    }

    @Test func purgeRemovesOnlyThatProfile() async throws {
        let device = try await SharedDevice()
        try await device.seed()
        try await device.database.store.purgeShared(profileID: device.home.id)
        #expect(try await device.database.store.sharedRecords(profileID: device.home.id).isEmpty)
        #expect(try await device.database.store.sharedProfileIDs() == [device.trip.id])
    }
}

struct SharedDevice {
    let database: CashlyDatabase
    let home = User(id: "home", name: "Home")
    let trip = User(id: "trip", name: "Trip")

    init() async throws {
        database = try CashlyDatabase.open(inMemory: true)
        let users = database.repositories(for: nil).users
        try await users.save(home)
        try await users.save(trip)
    }

    func seed() async throws {
        let scoped = database.repositories(for: home.id)
        let category = Category(id: "food", user: home, name: "Food", color: "C2602A", icon: "cart")
        try await scoped.categories.save(category)
        try await scoped.tags.save(
            Tag(id: "tag", user: home, name: "Market", color: "00FF00", icon: "tag"))
        try await scoped.budgets.save(
            Budget(
                id: "budget", money: Money(minorUnits: 50_000), category: category,
                month: try #require(YearMonth(rawValue: 202_610)), summary: "Food"))
        let participant = Participant(
            id: "split", user: trip, splitMode: .equal, splitValue: 2, status: .pendingToReceive,
            transaction: "dinner")
        try await scoped.transactions.save(
            Transaction(
                id: "dinner", participants: [participant], category: category,
                money: Money(minorUnits: 12_000), date: .now, summary: "Dinner",
                status: .settled, splitMode: .equal, splitValue: 60, paymentsPlan: nil,
                tagIDs: ["tag"]))
    }
}
