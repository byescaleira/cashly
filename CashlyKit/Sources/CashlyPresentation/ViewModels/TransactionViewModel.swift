import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class TransactionViewModel {
    public var draft: TransactionDraft
    public private(set) var isLoading = false
    public private(set) var isSaved = false
    public var error: CashlyError?
    public var canSave: Bool { hasLoaded && draft.canSave && !isLoading && !isSaved }
    @ObservationIgnored private var hasLoaded = false
    @ObservationIgnored private var isFetching = false
    @ObservationIgnored private var loadRevision = 0
    @ObservationIgnored private let snapshotUseCase: any SnapshotUseCase
    @ObservationIgnored private let transactionUseCase: any TransactionUseCase

    public init(draft: TransactionDraft = .new(), dataFactory: any CashlyDataFactoryProtocol) {
        self.draft = draft
        self.snapshotUseCase = dataFactory.makeSnapshotUseCase()
        self.transactionUseCase = dataFactory.makeTransactionUseCase()
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
            let record = try await transactionUseCase.getTransaction(id: draft.id)
            try Task.checkCancellation()
            guard request == loadRevision else { return }
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
            if let record {
                draft.participants = record.participants
                draft.category = record.category
                draft.kind = record.kind
                draft.amount = record.money.doubleValue
                draft.date = record.date
                draft.summary = record.summary
                draft.status = record.status
                draft.selectedTagIDs = record.tagIDs
                draft.splitMode = record.splitMode
                draft.splitValue = record.splitValue
                draft.installmentIsOn = record.paymentsPlan != nil
                draft.installmentPlan = max(record.paymentsPlan ?? 1, 1)
            }
            try await loadOptions(request: request)
            try Task.checkCancellation()
            guard request == loadRevision else { return }
            hasLoaded = true
        } catch is CancellationError {} catch {
            if request == loadRevision && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }

    public func save() async {
        guard !isLoading && !isSaved else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            guard hasLoaded && draft.canSave, let category = draft.category else {
                throw CashlyError.onSave
            }
            try await transactionUseCase.addTransaction(
                id: draft.id,
                participants: Array(draft.participants),
                categoryID: category.id,
                kind: draft.kind,
                money: try Money(validating: draft.amount),
                date: draft.date,
                summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines),
                status: draft.status,
                splitMode: draft.splitMode,
                splitValue: draft.splitValue,
                paymentsPlan: draft.installmentIsOn ? draft.installmentPlan : nil,
                tagIDs: draft.selectedTagIDs
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
            guard let transaction = try await transactionUseCase.getTransaction(id: draft.id) else {
                self.error = .onRemove
                return
            }

            try await transactionUseCase.removeTransaction(id: transaction.id)
            isSaved = true
        } catch {
            self.error = error as? CashlyError ?? .onRemove
        }
    }

    public func refreshOptions() async {
        guard hasLoaded, !isLoading, !isSaved else { return }
        do { try await loadOptions() } catch is CancellationError {} catch {
            if !Task.isCancelled { self.error = error as? CashlyError ?? .onFetch }
        }
    }
    private func loadOptions(request: Int? = nil) async throws {
        let snapshot = try await snapshotUseCase.snapshot(month: YearMonth(draft.date))
        let user = snapshot.currentUser
        let categories = snapshot.categories.filter { $0.user.id == user?.id }
        let tags = snapshot.tags.filter { $0.user.id == user?.id }
        try Task.checkCancellation()
        guard request == nil || request == loadRevision else { throw CancellationError() }
        guard draft.selectedTagIDs.isSubset(of: Set(tags.map(\.id))) else {
            throw CashlyError.persistence(
                "Uma tag selecionada está indisponível. Aguarde a sincronização ou remova a seleção."
            )
        }
        var category = draft.category
        if let selected = category {
            guard let latest = categories.first(where: { $0.id == selected.id }) else {
                throw CashlyError.missingRecord
            }
            category = latest
        } else if draft.isNew {
            category = categories.first
        }
        draft.categories = categories
        draft.tags = tags
        draft.category = category
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
