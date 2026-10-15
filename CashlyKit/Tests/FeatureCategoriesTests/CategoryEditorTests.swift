import CashlyData
import CashlyDomain
import FeatureCategories
import FeatureCore
import Testing

@MainActor
struct CategoryEditorTests {
    private let owner = User(id: "owner", name: "Perfil")
    private var market: CashlyDomain.Category {
        Category(id: "market", user: owner, name: "Mercado", color: "0099FF", icon: "cart.fill")
    }

    private func repositories() async throws -> Repositories {
        let database = try CashlyDatabase.open(inMemory: true)
        try await database.repositories(for: nil).users.save(owner)
        let repositories = database.repositories(for: owner.id)
        try await repositories.categories.save(market)
        return repositories
    }

    @Test func invalidDraftIsNotSaved() async throws {
        let editor = CategoryEditorModel(repositories: try await repositories())
        await editor.load()
        editor.draft.name = "AB"
        #expect(!editor.canSave)
        await editor.save()
        #expect(!editor.status.isSaved)
        #expect(editor.status.error == .onSave)
    }

    @Test func editingStoresHexColorAndSelectsIconCategory() async throws {
        let repositories = try await repositories()
        let editor = CategoryEditorModel(draft: .edit(id: market.id), repositories: repositories)
        await editor.load()
        #expect(editor.draft.color == "0099FF")
        #expect(SymbolCategory.containing(editor.draft.icon) == .groceries)
        #expect(editor.canRemove)
        editor.draft.color = "FF0000"
        await editor.save()
        #expect(try await repositories.categories.category(id: market.id)?.color == "FF0000")
    }

    @Test func newCategoryIsCreated() async throws {
        let repositories = try await repositories()
        let editor = CategoryEditorModel(repositories: repositories)
        await editor.load()
        editor.draft.name = " Lazer "
        await editor.save()
        let saved = try await repositories.categories.category(id: editor.draft.id)
        #expect(saved?.name == "Lazer")
        #expect(saved?.user == owner)
    }
}
