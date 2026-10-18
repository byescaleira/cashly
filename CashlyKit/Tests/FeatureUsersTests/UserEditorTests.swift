import CashlyData
import CashlyDomain
import CloudKit
import FeatureCore
import FeatureUsers
import Foundation
import Testing

@MainActor
struct UserEditorTests {
    private func users(scope userID: String? = nil) throws -> any UserRepository {
        try CashlyDatabase.open(inMemory: true).repositories(for: userID).users
    }

    private func editor() async throws -> UserEditorModel {
        let editor = UserEditorModel(users: try users())
        await editor.load()
        editor.draft.name = "Ana Souza"
        return editor
    }

    private func illustration(in section: ProfileIllustration.Section) throws
        -> ProfileIllustration
    {
        try #require(section.illustrations.first)
    }

    @Test func newUserStartsWithInitialsInTheProfileColor() async throws {
        let users = try users()
        let editor = UserEditorModel(users: users)
        await editor.load()
        #expect(editor.style == .initials)
        #expect(editor.draft.photo == .suggested(for: editor.draft.id))
        editor.draft.name = "  Ana Souza  "
        #expect(editor.initials == "AS")
        await editor.save()
        #expect(editor.status.isSaved)
        #expect(editor.userToSelect == editor.draft.id)
        let saved = try await users.user(id: editor.draft.id)
        #expect(saved?.name == "Ana Souza")
        #expect(saved?.photo == .suggested(for: editor.draft.id))
    }

    @Test func editingRestoresTheChosenStyle() async throws {
        let users = try users()
        try await users.save(
            User(id: "ana", name: "Ana Souza", photo: .symbol("cat.fill", color: "B23A48")))
        let editor = UserEditorModel(draft: .edit(id: "ana"), users: users)
        await editor.load()
        #expect(editor.style == .symbol)
        #expect(editor.symbol == "cat.fill")
        #expect(editor.photoColor == "B23A48")
        #expect(editor.isSelected(.cat))
        #expect(editor.userToSelect == nil)
        #expect(editor.canRemove)
    }

    @Test func symbolUsesTheChosenColor() async throws {
        let editor = try await editor()
        editor.photoColor = "2E7D74"
        editor.select(.leaf)
        #expect(editor.draft.photo == .symbol("leaf.fill", color: "2E7D74"))
        #expect(editor.showsSymbols)
        #expect(editor.captionColor != nil)
        editor.photoColor = "B23A48"
        #expect(editor.draft.photo == .symbol("leaf.fill", color: "B23A48"))
        editor.select(.initials)
        #expect(editor.draft.photo == .initials(color: "B23A48"))
        #expect(!editor.showsSymbols)
    }

    @Test func freeIllustrationIsChosenAndSaved() async throws {
        let editor = try await editor()
        let cat = try illustration(in: .cats)
        var opened: [ShopItem] = []
        editor.choose(cat, in: ShopAccess(owned: []) { opened.append($0) })
        #expect(opened.isEmpty)
        #expect(editor.draft.photo == .illustration(cat.id))
        #expect(editor.style == .illustration)
        #expect(editor.isSelected(cat))
        #expect(!editor.showsColors)
        #expect(editor.photoCaption == PhotoStyle.illustration.title)
        #expect(editor.captionColor == nil)
        await editor.save()
        #expect(editor.status.isSaved)
    }

    @Test func lockedIllustrationOpensTheShopAndKeepsThePhoto() async throws {
        let editor = try await editor()
        let before = editor.draft.photo
        let whale = try illustration(in: .ocean)
        var opened: [ShopItem] = []
        let shop = ShopAccess(owned: []) { opened.append($0) }
        #expect(editor.access(to: .ocean, in: shop) == .locked(.avatarsOcean))
        editor.choose(whale, in: shop)
        #expect(opened == [.avatarsOcean])
        #expect(editor.draft.photo == before)
        editor.choose(whale, in: ShopAccess(owned: [.avatarsAll]) { opened.append($0) })
        #expect(editor.draft.photo == .illustration(whale.id))
        #expect(opened == [.avatarsOcean])
    }

    @Test func switchingStylesRemembersTheIllustration() async throws {
        let editor = try await editor()
        let capybara = try illustration(in: .forest)
        editor.choose(capybara, in: ShopAccess(owned: []) { _ in })
        editor.select(.initials)
        #expect(editor.draft.photo == .initials(color: editor.photoColor))
        editor.select(.illustration)
        #expect(editor.draft.photo == .illustration(capybara.id))
        #expect(editor.illustrationSections == ProfileIllustration.Section.allCases)
    }

    @Test func shortNameCannotBeSaved() async throws {
        let editor = UserEditorModel(users: try users())
        await editor.load()
        editor.draft.name = "Al"
        #expect(!editor.canSave)
        #expect(editor.displayName == "Al")
    }

    @Test func removingDeletesTheCurrentUser() async throws {
        let users = try users(scope: "bia")
        try await users.save(User(id: "bia", name: "Bia"))
        let editor = UserEditorModel(draft: .edit(id: "bia"), users: users)
        await editor.load()
        await editor.remove()
        #expect(try await users.user(id: "bia") == nil)
    }

    @Test func goldAvatarsNeedProAndGoBackToInitialsWhenItEnds() async throws {
        let database = try CashlyDatabase.open(inMemory: true)
        let editor = UserEditorModel(users: database.repositories(for: nil).users)
        await editor.load()
        editor.draft.name = "Ana Souza"
        let lion = try illustration(in: .gold)
        var proPresented = 0
        let free = ShopAccess(
            owned: [.avatarsAll], open: { _ in }, presentPro: { proPresented += 1 })
        editor.choose(lion, in: free)
        #expect(proPresented == 1)
        #expect(editor.draft.photo != .illustration(lion.id))
        editor.choose(lion, in: ShopAccess(owned: [], isPro: true, open: { _ in }))
        #expect(editor.draft.photo == .illustration(lion.id))
        #expect(editor.draft.photo.isProExclusive)
        await editor.save()
        let session = SessionModel(provider: database, preference: .disabled)
        await session.refreshUsers()
        await session.dropProPhotos()
        let saved = try await database.repositories(for: nil).users.user(id: editor.draft.id)
        #expect(saved?.photo == .suggested(for: editor.draft.id))
    }
}

@MainActor
struct SharedProfileEditorTests {
    @Test func newSharedProfilesGoThroughSharing() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        let service = EditorSharing()
        let sharing = SharingModel(service: service)
        await sharing.checkAccount()
        let owner = User(id: "me", name: "Rafael")
        let category = Category(id: "c", user: owner, name: "Food", color: "C2602A", icon: "cart")
        let editor = UserEditorModel(
            draft: .new(shared: true), users: users, sharing: sharing,
            sourceCategories: [category], sourceName: "Rafael")
        await editor.load()
        editor.draft.name = "Home"
        #expect(editor.createsShared)
        #expect(editor.canCopyCategories)
        #expect(editor.copyCategoriesTitle == "Copy Categories from Rafael")
        await editor.save()
        #expect(editor.status.isSaved)
        #expect(await service.copied == 1)
        #expect(try await users.user(id: editor.draft.id) == nil)
        #expect(sharing.inviting?.name == "Home")
    }

    @Test func copyingCategoriesCanBeTurnedOff() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        let service = EditorSharing()
        let sharing = SharingModel(service: service)
        await sharing.checkAccount()
        let owner = User(id: "me", name: "Rafael")
        let category = Category(id: "c", user: owner, name: "Food", color: "C2602A", icon: "cart")
        let editor = UserEditorModel(
            draft: .new(shared: true), users: users, sharing: sharing,
            sourceCategories: [category])
        await editor.load()
        editor.draft.name = "Home"
        editor.draft.copiesCategories = false
        await editor.save()
        #expect(await service.copied == 0)
    }

    @Test func sharedProfilesAreNotRemovedFromTheEditor() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        try await users.save(User(id: "home", name: "Home", isShared: true))
        let editor = UserEditorModel(draft: .edit(id: "home"), users: SharedMarking(base: users))
        await editor.load()
        #expect(editor.showsSharing)
        #expect(!editor.canRemove)
        #expect(!editor.createsShared)
    }

    @Test func sharedCreationWaitsForICloud() async throws {
        let users = try CashlyDatabase.open(inMemory: true).repositories(for: nil).users
        let editor = UserEditorModel(
            draft: .new(shared: true), users: users, sharing: SharingModel())
        await editor.load()
        editor.draft.name = "Home"
        #expect(!editor.canSave)
    }
}

private struct SharedMarking: UserRepository {
    let base: any UserRepository
    func users() async throws -> [User] { try await base.users() }
    func user(id: String) async throws -> User? {
        try await base.user(id: id).map {
            User(id: $0.id, name: $0.name, photo: $0.photo, isShared: true)
        }
    }
    func save(_ user: User) async throws { try await base.save(user) }
    func delete(id: String) async throws { try await base.delete(id: id) }
}

private actor EditorSharing: ProfileSharing {
    var copied: Int?
    nonisolated var container: CKContainer { CKContainer(identifier: "iCloud.cashly") }
    func accountAvailable() async -> Bool { true }
    func isOwner(of profileID: String) async -> Bool { true }
    func createProfile(_ user: User, copying categories: [CashlyDomain.Category]) async throws {
        copied = categories.count
    }
    func share(profileID: String, title: String) async throws -> CKShare {
        throw CashlyError.onSave
    }
    func details(profileID: String) async throws -> SharedProfileDetails {
        SharedProfileDetails(profileID: profileID, isOwner: true, isShared: false, members: [])
    }
    func removeMember(_ memberID: String, profileID: String) async throws {}
    func stopSharing(profileID: String) async throws {}
    func leave(profileID: String) async throws {}
    func deleteForEveryone(profileID: String) async throws {}
    func accept(_ metadata: CKShare.Metadata) async throws -> String { "" }
    func refresh() async {}
    func status() async -> SharingSyncStatus { SharingSyncStatus() }
}
