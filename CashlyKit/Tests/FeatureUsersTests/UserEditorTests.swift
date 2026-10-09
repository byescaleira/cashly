import CashlyData
import CashlyDomain
import FeatureUsers
import Testing

@MainActor
struct UserEditorTests {
    private func users(scope userID: String? = nil) throws -> any UserRepository {
        try CashlyDatabase.open(inMemory: true).repositories(for: userID).users
    }

    @Test func newUserIsSavedAndSelected() async throws {
        let users = try users()
        let editor = UserEditorModel(users: users)
        await editor.load()
        #expect(editor.draft.photo == "1")
        editor.draft.name = "  Ana Souza  "
        await editor.save()
        #expect(editor.status.isSaved)
        #expect(editor.userToSelect == editor.draft.id)
        let saved = try await users.user(id: editor.draft.id)
        #expect(saved?.name == "Ana Souza")
    }

    @Test func editingKeepsSelectionAndPicksAvatarStyle() async throws {
        let users = try users()
        try await users.save(User(id: "ana", name: "Ana", photo: "60"))
        let editor = UserEditorModel(draft: .edit(id: "ana"), users: users)
        await editor.load()
        #expect(editor.avatarStyle == .feminine)
        #expect(editor.userToSelect == nil)
        #expect(editor.canRemove)
    }

    @Test func shuffleStaysInsideTheStyle() async throws {
        let editor = UserEditorModel(users: try users())
        await editor.load()
        editor.avatarStyle = .feminine
        for _ in 0..<20 {
            editor.shufflePhoto()
            #expect(AvatarStyle.feminine.photos.contains(editor.draft.photo ?? ""))
        }
    }

    @Test func shortNameCannotBeSaved() async throws {
        let editor = UserEditorModel(users: try users())
        await editor.load()
        editor.draft.name = "Al"
        #expect(!editor.canSave)
    }

    @Test func removingDeletesTheCurrentUser() async throws {
        let users = try users(scope: "bia")
        try await users.save(User(id: "bia", name: "Bia", photo: "2"))
        let editor = UserEditorModel(draft: .edit(id: "bia"), users: users)
        await editor.load()
        await editor.remove()
        #expect(try await users.user(id: "bia") == nil)
    }
}
