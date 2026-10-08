import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class BudgetViewModel {
    public var draft: BudgetDraft
    public private(set) var isLoading = false
    public private(set) var isSaved = false
    public var error: CashlyError?
    public var canSave: Bool { hasLoaded && draft.canSave && !isLoading && !isSaved }
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var isFetching = false
    @ObservationIgnored private var loadRevision = 0
    @ObservationIgnored private let budgetUseCase: any BudgetUseCase
    @ObservationIgnored private let snapshotUseCase: any SnapshotUseCase

    public init(draft: BudgetDraft = .new(), dataFactory: any CashlyDataFactoryProtocol) {
        self.draft = draft
        self.budgetUseCase = dataFactory.makeBudgetUseCase()
        self.snapshotUseCase = dataFactory.makeSnapshotUseCase()
    }

    public func loadOrRefreshOptions() async {
        if hasLoaded {
            await refreshOptions()
        } else {
            await load()
        }
    }

    public func load() async {
        guard !hasLoaded, !isSaved, !isLoading || isFetching else { return }
        loadRevision += 1
        let request = loadRevision
        isFetching = true
        isLoading = true
        error = nil
        defer {
            if request == loadRevision {
                isFetching = false
                isLoading = false
            }
        }
        do {
            let snapshot = try await snapshotUseCase.snapshot(month: 0)
            let record = draft.isNew ? nil : try await budgetUseCase.getBudget(id: draft.id)
            try Task.checkCancellation()
            guard request == loadRevision else { return }
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            draft.categories = snapshot.categories.filter { $0.user.id == snapshot.currentUser?.id }
            if let record {
                draft.id = record.id
                draft.amount = record.amount
                draft.category = record.category
                draft.date = Date.from(yearMonth: record.date) ?? draft.date
                draft.summary = record.summary
            } else {
                draft.category = draft.category ?? draft.categories.first
            }
            try Task.checkCancellation()
            hasLoaded = true
        } catch is CancellationError {} catch {
            if request == loadRevision && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }

    public func refreshOptions() async {
        guard hasLoaded, !isLoading, !isSaved else { return }
        do {
            let snapshot = try await snapshotUseCase.snapshot(month: 0)
            try Task.checkCancellation()
            draft.categories = snapshot.categories.filter { $0.user.id == snapshot.currentUser?.id }
            draft.category =
                draft.categories.first { $0.id == draft.category?.id } ?? draft.categories.first
        } catch is CancellationError {} catch {
            if !Task.isCancelled { self.error = error as? CashlyError ?? .onFetch }
        }
    }

    public func save() async {
        guard !isLoading && !isSaved else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            guard hasLoaded && draft.canSave else { throw CashlyError.onSave }
            guard let category = draft.category,
                draft.amount > .zero,
                draft.summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3
            else {
                self.error = .onSave
                return
            }
            try await budgetUseCase.addBudget(
                id: draft.id,
                amount: draft.amount,
                category: category,
                date: draft.date.timeIntervalSince1970.yearMonth,
                summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onSave
        }
    }

    public func remove() async {
        guard hasLoaded && !draft.isNew && !isLoading && !isSaved else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await budgetUseCase.removeBudget(id: draft.id)
            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onRemove
        }
    }
}
