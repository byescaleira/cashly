import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class TransactionEditorModel {
    public var draft: TransactionDraft
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories
    @ObservationIgnored private var original: CashlyDomain.Transaction?
    private var predictsCategory: Bool?

    public init(draft: TransactionDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }
    public var canRemove: Bool { !draft.isNew && !status.isBusy }
    public var isPredictingCategory: Bool { predictsCategory ?? draft.isNew }

    public var chosenCategory: CashlyDomain.Category? {
        get { draft.category }
        set {
            predictsCategory = false
            draft.category = newValue
        }
    }

    public var participantUsers: Set<User> {
        get { Set(draft.participants.map(\.user)) }
        set { selectParticipants(newValue) }
    }

    public var splitStatus: TransactionStatus {
        draft.participants.first { $0.status != .settled }?.status ?? .settled
    }

    public var installmentDescription: String? {
        guard draft.installmentIsOn, let money = try? Money(validating: draft.amount),
            money.minorUnits > 0
        else { return nil }
        let plan = draft.installmentPlan
        let first = money.installment(at: 0, count: plan)
        let last = money.installment(at: plan - 1, count: plan)
        return first == last
            ? "\(plan)x de \(first.formatted)"
            : "\(plan)x de \(last.formatted) a \(first.formatted)"
    }

    public func budgetImpact(in month: YearMonth?) -> Double {
        func contribution(_ transaction: CashlyDomain.Transaction?) -> Money {
            guard let transaction, transaction.kind == .expense,
                transaction.category.id == draft.category?.id
            else { return .zero }
            return transaction.billingMoney(in: month)
        }
        return contribution(draft.preview).doubleValue - contribution(original).doubleValue
    }

    public func budgetMessage(in finance: FinanceModel, month: YearMonth?) -> String? {
        guard let category = draft.category else { return nil }
        let remaining =
            finance.categoryRemainingAmount(category: category) - budgetImpact(in: month)
        let name = category.name.capitalized
        return remaining < .zero
            ? "Você passou do orçamento de \(name) em \((-remaining).formatted(.appCurrency))."
            : "Faltam \(remaining.formatted(.appCurrency)) para atingir o orçamento de \(name)."
    }

    public func conflictedBudget(in finance: FinanceModel) -> Budget? {
        finance.budgets.first {
            $0.category.id == draft.category?.id && $0.month == YearMonth(draft.date)
                && $0.isConflicted
        }
    }

    public func canEnablePrediction(with intelligence: IntelligenceModel) -> Bool {
        repositories.userID != nil && intelligence.hasModel(.categoryName) && !isPredictingCategory
    }

    public func enablePrediction() {
        predictsCategory = true
    }

    public func predictCategory(with intelligence: IntelligenceModel) async {
        guard isPredictingCategory, draft.kind == .expense, !draft.summary.isEmpty,
            repositories.userID != nil, intelligence.hasModel(.categoryName)
        else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        let prediction = await intelligence.predict(.text(draft.summary))
        guard !Task.isCancelled, case .textClassification(let id) = prediction,
            let category = draft.categories.first(where: { $0.id == id })
        else { return }
        draft.category = category
    }

    public func isTagSelected(_ tag: Tag) -> Bool {
        draft.selectedTagIDs.contains(tag.id)
    }

    public func setTag(_ tag: Tag, selected: Bool) {
        if selected {
            draft.selectedTagIDs.insert(tag.id)
        } else {
            draft.selectedTagIDs.remove(tag.id)
        }
    }

    public func removeParticipant(id: String) {
        selectParticipants(Set(draft.participants.filter { $0.id != id }.map(\.user)))
    }

    public func loadOrRefresh() async {
        if status.isLoaded { await refresh() } else { await load() }
    }

    public func load() async {
        await status.load {
            let record = try await repositories.transactions.transaction(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            original = record
            draft.apply(record)
            try await applyOptions()
        }
    }

    public func refresh() async {
        await status.refresh { try await applyOptions() }
    }

    public func save() async {
        await status.save { try await repositories.transactions.save(draft.makeTransaction()) }
    }

    public func remove() async {
        guard !draft.isNew else { return }
        await status.remove { try await repositories.transactions.delete(id: draft.id) }
    }

    private func applyOptions() async throws {
        let snapshot = try await repositories.dashboard.snapshot(month: YearMonth(draft.date))
        let owner = snapshot.currentUser?.id
        try Task.checkCancellation()
        try draft.applyOptions(
            categories: snapshot.categories.filter { $0.user.id == owner },
            tags: snapshot.tags.filter { $0.user.id == owner })
    }

    public func selectParticipants(_ users: Set<User>) {
        guard draft.kind == .expense else {
            draft.participants = []
            draft.splitMode = nil
            draft.splitValue = nil
            return
        }
        let previous = Dictionary(
            draft.participants.map { ($0.user.id, $0) }, uniquingKeysWith: { first, _ in first })
        draft.splitMode = users.isEmpty ? nil : (draft.splitMode ?? .equal)
        draft.participants = users.sorted { $0.name < $1.name }.map { user in
            previous[user.id]
                ?? Participant(
                    id: UUID().uuidString, user: user,
                    splitMode: draft.splitMode ?? .equal, splitValue: 0, status: .settled,
                    transaction: draft.id)
        }
        if draft.splitMode == .equal { changeSplitMode() } else { updateShares() }
    }

    public func changeSplitMode() {
        let mode = draft.splitMode ?? .equal
        let count = Double(draft.participants.count + 1)
        for index in draft.participants.indices {
            let changed = draft.participants[index].splitMode != mode
            draft.participants[index].splitMode = mode
            switch mode {
            case .equal: draft.participants[index].splitValue = count
            case .percentage: if changed { draft.participants[index].splitValue = 1 / count }
            case .fixedAmount, .payerBased: if changed { draft.participants[index].splitValue = 0 }
            }
        }
        updateShares()
    }

    public func updateShares() {
        guard !draft.participants.isEmpty else {
            draft.splitMode = nil
            draft.splitValue = nil
            return
        }
        guard let total = try? Money(validating: draft.amount),
            let allocation = try? TransactionAllocation.resolve(
                total: total, participants: draft.participants)
        else {
            draft.splitValue = -1
            return
        }
        draft.splitValue = allocation.owner.doubleValue
        for index in draft.participants.indices {
            draft.participants[index].allocatedMoney =
                allocation.participants[draft.participants[index].id]
        }
    }
}
