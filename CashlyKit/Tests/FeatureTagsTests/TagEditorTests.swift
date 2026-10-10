import CashlyData
import CashlyDomain
import FeatureCore
import FeatureTags
import Testing

@MainActor
struct TagEditorTests {
    private let owner = User(id: "owner", name: "Perfil", photo: "1")

    private func repositories() async throws -> Repositories {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        return database.repositories(for: owner.id)
    }

    @Test func createsTagWithTrimmedName() async throws {
        let repositories = try await repositories()
        let editor = TagEditorModel(repositories: repositories)
        await editor.load()
        editor.draft.name = "  Viagem  "
        editor.draft.icon = "airplane"
        #expect(editor.canSave)
        await editor.save()
        #expect(editor.status.isSaved)
        let saved = try await repositories.tags.tag(id: editor.draft.id)
        #expect(saved?.name == "Viagem")
        #expect(saved?.user == owner)
        #expect(RetroColor(hex: saved?.color ?? "") == .default)
    }

    @Test func shortNameCannotBeSaved() async throws {
        let editor = TagEditorModel(repositories: try await repositories())
        await editor.load()
        editor.draft.name = "AB"
        #expect(!editor.canSave)
        await editor.save()
        #expect(!editor.status.isSaved)
    }

    @Test func editingSelectsTheIconCategory() async throws {
        let repositories = try await repositories()
        try await repositories.tags.save(
            Tag(id: "market", user: owner, name: "Mercado", color: "00FF00", icon: "cart.fill"))
        let editor = TagEditorModel(draft: .edit(id: "market"), repositories: repositories)
        await editor.load()
        #expect(editor.draft.name == "Mercado")
        #expect(editor.symbolCategory == .groceries)
        #expect(editor.canRemove)
    }

    @Test func removingDeletesTheTag() async throws {
        let repositories = try await repositories()
        try await repositories.tags.save(
            Tag(id: "trip", user: owner, name: "Viagem", color: "0000FF", icon: "airplane"))
        let editor = TagEditorModel(draft: .edit(id: "trip"), repositories: repositories)
        await editor.load()
        await editor.remove()
        #expect(try await repositories.tags.tag(id: "trip") == nil)
    }

    @Test func editingMissingRecordReportsError() async throws {
        let editor = TagEditorModel(
            draft: .edit(id: "missing"), repositories: try await repositories())
        await editor.load()
        #expect(!editor.status.isLoaded)
        #expect(editor.status.error == .missingRecord)
    }
}
