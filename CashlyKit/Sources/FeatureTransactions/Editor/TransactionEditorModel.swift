import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class TransactionEditorModel {
    public var draft: TransactionDraft
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories
    @ObservationIgnored private let capture: Capture?
    @ObservationIgnored let rates: any ExchangeRateProviding
    public internal(set) var paidCurrencies: [String] = CurrencySetting.supported
    public internal(set) var isFetchingRate = false
    public internal(set) var rateFailed = false
    @ObservationIgnored private var original: CashlyDomain.Transaction?
    private var predictsCategory: Bool?
    public var isPro = false
    @ObservationIgnored private var keptTagIDs: Set<String>?
    @ObservationIgnored private var dismissedTagIDs: Set<String> = []

    public init(
        draft: TransactionDraft = .new(), repositories: Repositories, capture: Capture? = nil,
        rates: any ExchangeRateProviding = UnavailableExchangeRates()
    ) {
        self.draft = draft
        self.repositories = repositories
        self.capture = capture
        self.rates = rates
    }

    public var canSave: Bool {
        status.isLoaded && !status.isLocked && !isFetchingRate && draft.canSave
    }
    public var canRemove: Bool { !draft.isNew && !status.isBusy }
    public var isPredictingCategory: Bool { isPro && (predictsCategory ?? draft.isNew) }

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

    public var kind: TransactionKind {
        get { draft.kind }
        set {
            guard newValue != draft.kind else { return }
            draft.kind = newValue
            if draft.status == .pendingToPay || draft.status == .pendingToReceive {
                draft.status = newValue == .income ? .pendingToReceive : .pendingToPay
            }
            if newValue == .income { selectParticipants([]) }
        }
    }

    var keptExchange: TransactionExchange? {
        guard let original, original.estimate == nil, let exchange = original.exchange,
            exchange.currencyCode == draft.paidCurrency,
            ExchangeTable.day(for: original.date) == ExchangeTable.day(for: draft.date)
        else { return nil }
        return exchange
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
            ? String(appLocalized: "\(plan)× \(first.formatted)")
            : String(appLocalized: "\(plan)× from \(last.formatted) to \(first.formatted)")
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
            ? String(
                appLocalized:
                    "You went over the \(name) budget by \((-remaining).formatted(.appCurrency)).")
            : String(
                appLocalized:
                    "\(remaining.formatted(.appCurrency)) left before reaching the \(name) budget.")
    }

    public func conflictedBudget(in finance: FinanceModel) -> Budget? {
        finance.budgets.first {
            $0.category.id == draft.category?.id && $0.month == YearMonth(draft.date)
                && $0.isConflicted
        }
    }

    public func canEnablePrediction(with intelligence: IntelligenceModel) -> Bool {
        repositories.userID != nil && intelligence.canSuggestCategory && !isPredictingCategory
    }

    public func enablePrediction() {
        predictsCategory = true
    }

    public func predictCategory(with intelligence: IntelligenceModel) async {
        guard isPredictingCategory, draft.kind == .expense, !draft.summary.isEmpty,
            repositories.userID != nil, intelligence.canSuggestCategory
        else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled, let id = intelligence.category(for: draft.summary),
            let category = draft.categories.first(where: { $0.id == id })
        else { return }
        draft.category = category
    }

    public func matchTags() {
        let kept = keptTagIDs ?? draft.selectedTagIDs
        keptTagIDs = kept
        let matched = draft.matchedTagIDs
        dismissedTagIDs.formIntersection(matched.union(kept))
        draft.selectedTagIDs = kept.union(matched).subtracting(dismissedTagIDs)
    }

    public func dismissTag(_ tag: Tag) {
        dismissedTagIDs.insert(tag.id)
        draft.selectedTagIDs.remove(tag.id)
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
        guard status.isSaved else { return }
        await CashlyTips.record(CashlyTips.transactionSaved)
        if let capture, let user = draft.user, let transaction = draft.preview {
            try? await CaptureActions(repositories: repositories, user: user)
                .link(captureID: capture.id, to: transaction)
        }
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
