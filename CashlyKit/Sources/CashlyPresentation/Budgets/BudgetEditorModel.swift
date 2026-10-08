import CashlyDomain
import Observation

@MainActor @Observable
public final class BudgetEditorModel {
    public var draft: BudgetDraft
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories

    public init(draft: BudgetDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }

    public func loadOrRefresh() async {
        if status.isLoaded { await refresh() } else { await load() }
    }

    public func load() async {
        await status.load {
            let categories = try await ownCategories()
            let record = draft.isNew ? nil : try await repositories.budgets.budget(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            draft.apply(record, categories: categories)
        }
    }

    public func refresh() async {
        await status.refresh {
            let categories = try await ownCategories()
            try Task.checkCancellation()
            draft.refresh(categories: categories)
        }
    }

    public func save() async {
        await status.save { try await repositories.budgets.save(draft.makeBudget()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await repositories.budgets.delete(id: draft.id) }
    }

    private func ownCategories() async throws -> [CashlyDomain.Category] {
        let snapshot = try await repositories.dashboard.snapshot(month: draft.month)
        return snapshot.categories.filter { $0.user.id == snapshot.currentUser?.id }
    }
}
