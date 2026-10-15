import CashlyData
import CashlyDomain
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
}
