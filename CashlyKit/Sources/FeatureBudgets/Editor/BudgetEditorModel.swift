import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class BudgetEditorModel {
    public var draft: BudgetDraft
    public let status = EditorStatus()
    public private(set) var budgetedMonths: [String: [YearMonth: String]] = [:]
    @ObservationIgnored private let repositories: Repositories

    public init(draft: BudgetDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool {
        status.isLoaded && !status.isLocked && draft.canSave && !isMonthTaken
    }
    public var canRemove: Bool { !draft.isNew && !status.isBusy }

    public var month: YearMonth {
        get { draft.month }
        set { draft.date = newValue.startDate }
    }

    public var takenMonths: Set<YearMonth> {
        Set(budgetsByMonth.keys)
    }

    public var takenBudgetID: String? { budgetsByMonth[draft.month] }

    public var canEditTakenBudget: Bool { takenBudgetID != nil && !status.isLocked }

    public var isMonthTaken: Bool { takenBudgetID != nil }

    private var budgetsByMonth: [YearMonth: String] {
        draft.category.flatMap { budgetedMonths[$0.id] } ?? [:]
    }

    public var takenMonthTitle: String { String(appLocalized: "Already has a budget") }

    public var monthMessage: String? {
        guard let category = draft.category, !takenMonths.isEmpty else { return nil }
        let name = category.name.capitalized
        guard isMonthTaken else {
            guard takenMonths.count <= 3 else {
                return String(appLocalized: "Months with a dot already have a \(name) budget.")
            }
            let months = takenMonths.sorted().map {
                $0.startDate.formatted(.dateTime.month(.wide).year().locale(.app))
            }
            .formatted(.list(type: .and).locale(.app))
            return String(appLocalized: "\(name) already has a budget in \(months).")
        }
        let month = draft.date.formatted(.dateTime.month(.wide).year().locale(.app))
        return String(
            appLocalized:
                "\(name) already has a budget in \(month). Pick another month or edit that budget.")
    }

    public var isAmountLocked: Bool { draft.estimate != nil }

    public var estimateDescription: String? {
        guard let estimate = draft.estimate else { return nil }
        return CurrencyText.estimate(estimate) + " "
            + String(appLocalized: "The amount can't be changed here.")
    }

    public func canSuggestAmount(with intelligence: IntelligenceModel) -> Bool {
        !isAmountLocked && repositories.userID != nil && intelligence.hasModel(.budgetValue)
    }

    public func suggestAmount(with intelligence: IntelligenceModel) async {
        guard canSuggestAmount(with: intelligence), let category = draft.category else { return }
        let prediction = await intelligence.predict(
            .budget(month: draft.month, categoryID: category.id))
        if case .tabularRegression(let value) = prediction { draft.amount = value }
    }

    public func loadOrRefresh() async {
        if status.isLoaded { await refresh() } else { await load() }
    }

    public func load() async {
        await status.load {
            let catalog = try await ownCatalog()
            let record = draft.isNew ? nil : try await repositories.budgets.budget(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            draft.apply(record, categories: catalog.categories)
            budgetedMonths = catalog.months
        }
    }

    public func refresh() async {
        await status.refresh {
            let catalog = try await ownCatalog()
            try Task.checkCancellation()
            draft.refresh(categories: catalog.categories)
            budgetedMonths = catalog.months
        }
    }

    public func editTakenBudget() async {
        guard canEditTakenBudget, let id = takenBudgetID else { return }
        await status.refresh {
            let catalog = try await ownCatalog(excluding: id)
            guard let record = try await repositories.budgets.budget(id: id) else {
                throw CashlyError.missingRecord
            }
            try Task.checkCancellation()
            var next = BudgetDraft.edit(id: id)
            next.apply(record, categories: catalog.categories)
            draft = next
            budgetedMonths = catalog.months
        }
    }

    public func save() async {
        guard !isMonthTaken else { return }
        await status.save { try await repositories.budgets.save(draft.makeBudget()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await repositories.budgets.delete(id: draft.id) }
    }

    private func ownCatalog(excluding id: String? = nil) async throws -> (
        categories: [CashlyDomain.Category], months: [String: [YearMonth: String]]
    ) {
        let excluded = id ?? draft.id
        let snapshot = try await repositories.dashboard.snapshot(month: nil)
        let owner = snapshot.currentUser?.id
        let budgets = snapshot.budgets.filter { $0.category.user.id == owner && $0.id != excluded }
        return (
            snapshot.categories.filter { $0.user.id == owner },
            Dictionary(grouping: budgets, by: \.category.id).mapValues {
                Dictionary($0.map { ($0.month, $0.id) }, uniquingKeysWith: { first, _ in first })
            }
        )
    }
}
