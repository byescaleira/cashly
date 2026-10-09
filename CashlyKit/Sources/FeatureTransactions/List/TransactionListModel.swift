import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class TransactionListModel {
    public private(set) var items: [CashlyDomain.Transaction] = []
    public private(set) var isLoading = false
    public private(set) var isLoadingMore = false
    public var isSelecting = false
    public var selection: Set<CashlyDomain.Transaction> = []
    public var isConfirmingDelete = false
    public var error: CashlyError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private var nextCursor: TransactionCursor?
    @ObservationIgnored private var loadedKey: SessionLoadKey?
    @ObservationIgnored private var request = 0

    public init(session: SessionModel) {
        self.session = session
    }

    public var hasMore: Bool { nextCursor != nil }

    public var days: [TransactionDay] {
        let groups = Dictionary(grouping: items) {
            CashlyCalendar.current.startOfDay(for: date(of: $0))
        }
        return groups.keys.sorted(by: >).map {
            TransactionDay(date: $0, items: groups[$0, default: []])
        }
    }

    public var isAllSelected: Bool { !items.isEmpty && selection.count == items.count }

    public func date(of transaction: CashlyDomain.Transaction) -> Date {
        loadedKey?.query.month.flatMap { transaction.billingDate(in: $0) } ?? transaction.date
    }

    public func billing(of transaction: CashlyDomain.Transaction) -> Money {
        transaction.billingMoney(in: loadedKey?.query.month)
    }

    public func shareMessage(participants: Set<User>) -> String {
        TransactionShareMessage.make(
            transactions: selection, participants: participants, month: loadedKey?.query.month)
    }

    public func toggleSelectAll() {
        selection = isAllSelected ? [] : Set(items)
    }

    public func endSelection() {
        isSelecting = false
        selection = []
    }

    public func deleteSelection() async {
        await delete(selection)
        selection = []
    }

    public func load() async {
        request += 1
        let current = request
        let key = session.loadKey
        guard session.user != nil else {
            items = []
            selection = []
            nextCursor = nil
            loadedKey = key
            return
        }
        isLoading = true
        defer { if current == request { isLoading = false } }
        do {
            let page = try await session.repositories.dashboard.page(
                query: key.query, after: nil, limit: 50)
            try Task.checkCancellation()
            guard current == request, session.loadKey == key else { return }
            items = page.items
            nextCursor = page.nextCursor
            loadedKey = key
            let selected = Set(selection.map(\.id))
            selection = Set(items.filter { selected.contains($0.id) })
        } catch is CancellationError {} catch {
            if current == request && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }

    public func loadMore() async {
        guard !isLoading, !isLoadingMore, let cursor = nextCursor, let key = loadedKey else {
            return
        }
        let current = request
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await session.repositories.dashboard.page(
                query: key.query, after: cursor, limit: 50)
            try Task.checkCancellation()
            guard current == request, session.loadKey == key else { return }
            let present = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !present.contains($0.id) })
            nextCursor = page.nextCursor
        } catch is CancellationError {} catch {
            if current == request && !Task.isCancelled {
                self.error = error as? CashlyError ?? .onFetch
            }
        }
    }

    public func delete(_ transaction: CashlyDomain.Transaction) async {
        await delete([transaction])
    }

    public func delete(_ transactions: Set<CashlyDomain.Transaction>) async {
        do {
            try await session.repositories.transactions.delete(ids: Set(transactions.map(\.id)))
            session.reload()
        } catch { self.error = error as? CashlyError ?? .onRemove }
    }
}
