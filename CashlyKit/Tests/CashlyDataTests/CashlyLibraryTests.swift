import CashlyDomain
import Foundation
import Testing

@testable import CashlyData

struct CashlyLibraryTests {
    let library: CashlyLibrary
    let me = User(id: "me", name: "Rafael")
    let home = User(id: "home", name: "Home")

    init() async throws {
        library = try CashlyLibrary.inMemory()
        try await library.main.repositories(for: nil).users.save(me)
        try await library.shared.repositories(for: nil).users.save(home)
    }

    @Test func directoryListsPersonalThenSharedProfiles() async throws {
        let users = try await library.repositories(for: nil).users.users()
        #expect(users.map(\.id) == ["me", "home"])
        #expect(users.map(\.isShared) == [false, true])
        #expect(library.isShared("home"))
        #expect(!library.isShared("me"))
    }

    @Test func profilesRouteToTheirDatabase() async throws {
        _ = try await library.repositories(for: nil).users.users()
        let category = Category(id: "c", user: home, name: "House", color: "C2602A", icon: "house")
        try await library.repositories(for: "home").categories.save(category)
        #expect(
            try await library.shared.repositories(for: "home").categories.category(id: "c")
                != nil)
        #expect(
            try await library.main.repositories(for: "home").categories.category(id: "c")
                == nil)
        let profile = try await library.repositories(for: "home").users.user(id: "home")
        #expect(profile?.isShared == true)
    }

    @Test func sharedProfilesOnlyListThemselves() async throws {
        try await library.shared.repositories(for: nil).users.save(User(id: "trip", name: "Trip"))
        await library.prepare()
        let scoped = try await library.repositories(for: "home").users.users()
        #expect(scoped.map(\.id) == ["home"])
        let personal = try await library.repositories(for: "me").users.users()
        #expect(personal.map(\.id) == ["me"])
    }

    @Test func lookingUpASharedProfileRegistersIt() async throws {
        let found = try await library.repositories(for: nil).users.user(id: "home")
        #expect(found?.isShared == true)
        #expect(library.isShared("home"))
    }

    @Test func sharedProfilesAreNotDeletedThroughTheDirectory() async throws {
        _ = try await library.repositories(for: nil).users.users()
        await #expect(throws: CashlyError.onRemove) {
            try await library.repositories(for: nil).users.delete(id: "home")
        }
        await #expect(throws: CashlyError.onRemove) {
            try await library.repositories(for: "home").users.delete(id: "home")
        }
    }

    @Test func savingASharedProfileStaysInTheSharedDatabase() async throws {
        await library.prepare()
        var renamed = home
        renamed.name = "Our Home"
        try await library.repositories(for: "home").users.save(renamed)
        #expect(
            try await library.shared.repositories(for: nil).users.user(id: "home")?.name
                == "Our Home")
        #expect(try await library.main.repositories(for: nil).users.user(id: "home") == nil)
    }

    @Test func newProfilesGoWhereTheirFlagSays() async throws {
        let directory = library.repositories(for: nil).users
        try await directory.save(User(id: "ana", name: "Ana Souza"))
        try await directory.save(User(id: "trip", name: "Trip", isShared: true))
        #expect(try await library.main.repositories(for: nil).users.user(id: "ana") != nil)
        #expect(try await library.shared.repositories(for: nil).users.user(id: "trip") != nil)
        #expect(try await library.main.repositories(for: nil).users.user(id: "trip") == nil)
    }

    @Test func changesFromBothDatabasesReachTheFeed() async throws {
        var changes = library.changes.changes().makeAsyncIterator()
        try await Task.sleep(for: .milliseconds(50))
        let category = Category(id: "c", user: home, name: "House", color: "C2602A", icon: "house")
        try await library.shared.repositories(for: "home").categories.save(category)
        #expect(await changes.next() != nil)
    }
}
