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
        editor.photoColor = "B23A48"
        #expect(editor.draft.photo == .symbol("leaf.fill", color: "B23A48"))
        editor.select(.initials)
        #expect(editor.draft.photo == .initials(color: "B23A48"))
        #expect(!editor.showsSymbols)
    }

    @Test func choosingMemojiOpensThePickerUntilSomethingArrives() async throws {
        let editor = try await editor()
        editor.select(.memoji)
        #expect(editor.isPickingMemoji)
        #expect(editor.showsMemoji)
        #expect(editor.highlightedStyle == .memoji)
        #expect(editor.style == .initials)
        editor.capture(NSAttributedString(string: "abc"))
        #expect(editor.isPickingMemoji)
        #expect(PhotoStyle(editor.draft.photo) == .initials)
    }

    @Test func emojiFromTheKeyboardBecomesThePhoto() async throws {
        let editor = try await editor()
        editor.photoColor = "DDB040"
        editor.select(.memoji)
        editor.capture(NSAttributedString(string: "🌻"))
        #expect(editor.draft.photo == .emoji("🌻", color: "DDB040"))
        #expect(editor.style == .memoji)
        #expect(!editor.isPickingMemoji)
        #expect(editor.showsColors)
        editor.select(.symbol)
        editor.select(.memoji)
        #expect(editor.draft.photo == .emoji("🌻", color: "DDB040"))
        #expect(!editor.isPickingMemoji)
        await editor.save()
        #expect(editor.status.isSaved)
    }

    @Test func savedMemojiHidesTheColors() async throws {
        let users = try users()
        try await users.save(User(id: "ana", name: "Ana Souza", photo: .memoji(Data([1, 2, 3]))))
        let editor = UserEditorModel(draft: .edit(id: "ana"), users: users)
        await editor.load()
        #expect(editor.style == .memoji)
        #expect(editor.hasMemoji)
        #expect(!editor.showsColors)
        #expect(editor.photoCaption == "Memoji")
        editor.select(.memoji)
        #expect(editor.isPickingMemoji)
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
