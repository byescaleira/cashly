import CashlyDomain
import Foundation
import Observation

@MainActor @Observable
public final class TransactionEditorModel {
    public var draft: TransactionDraft
    public let status = EditorStatus()
    @ObservationIgnored private let repositories: Repositories

    public init(draft: TransactionDraft = .new(), repositories: Repositories) {
        self.draft = draft
        self.repositories = repositories
    }

    public var canSave: Bool { status.isLoaded && !status.isLocked && draft.canSave }

    public func loadOrRefresh() async {
        if status.isLoaded { await refresh() } else { await load() }
    }

    public func load() async {
        await status.load {
            let record = try await repositories.transactions.transaction(id: draft.id)
            try Task.checkCancellation()
            if !draft.isNew && record == nil { throw CashlyError.missingRecord }
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
