import CashlyDomain
import CryptoKit
import Foundation
import SwiftData

extension CashlyStore {
    public func catalog(userID: String, month: YearMonth? = nil, includesBudgets: Bool = true)
        throws -> CashlySnapshot
    {
        try ensureNormalization()
        let users = try getUsers()
        guard let user = users.first(where: { $0.id == userID }) else {
            throw CashlyError.missingRecord
        }
        let categoryRows = try modelContext.fetch(
            FetchDescriptor<CategoryEntity>(
                predicate: #Predicate { $0.user == userID },
                sortBy: [SortDescriptor(\.name), SortDescriptor(\.id)]))
        let categories = categoryRows.map {
            CashlyDomain.Category(
                id: $0.id, user: user, name: $0.name, color: $0.color, icon: $0.icon)
        }
        let categoryMap = try uniqueIndex(categories)
        let filteringMonth = month != nil
        let targetMonth = month?.rawValue ?? 0
        let budgetRows: [BudgetEntity] =
            try !includesBudgets
            ? []
            : modelContext.fetch(
                FetchDescriptor<BudgetEntity>(
                    predicate: #Predicate {
                        $0.ownerID == userID && $0.mergedIntoID == ""
                            && (!filteringMonth || $0.date == targetMonth)
                    },
                    sortBy: [
                        SortDescriptor(\.date, order: .reverse),
                        SortDescriptor(\.id, order: .reverse),
                    ])
            )
        var pending = try modelContext.fetchCount(
            FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.ownerID == "" }))
        let groups = Dictionary(grouping: budgetRows, by: { $0.category + "." + String($0.date) })
        let budgets = budgetRows.compactMap { row -> Budget? in
            guard let category = categoryMap[row.category],
                let budgetMonth = YearMonth(rawValue: row.date),
                let value = try? money(
                    minorUnits: row.amountMinorUnits, legacy: row.amount,
                    currencyCode: row.currencyCode)
            else {
                pending += 1
                return nil
            }
            let conflict = groups[row.category + "." + String(row.date), default: []].count > 1
            return Budget(
                id: row.id, money: value, category: category, month: budgetMonth,
                summary: row.summary,
                isConflicted: conflict || row.isConflicted)
        }
        let tags = try modelContext.fetch(
            FetchDescriptor<TagEntity>(
                predicate: #Predicate { $0.user == userID },
                sortBy: [SortDescriptor(\.name), SortDescriptor(\.id)])
        ).map { Tag(id: $0.id, user: user, name: $0.name, color: $0.color, icon: $0.icon) }
        var result = CashlySnapshot(
            users: users, currentUser: user, categories: categories, budgets: budgets, tags: tags)
        result.pendingReferences = pending
        return result
    }
    public func getCategory(id: String, userID: String) throws -> CashlyDomain.Category? {
        guard
            let row = try modelContext.fetch(
                FetchDescriptor<CategoryEntity>(
                    predicate: #Predicate { $0.id == id && $0.user == userID })
            ).first
        else { return nil }
        return try mapCategory(row)
    }
    public func getBudget(id: String, userID: String) throws -> Budget? {
        try ensureNormalization()
        guard
            let row = try modelContext.fetch(
                FetchDescriptor<BudgetEntity>(
                    predicate: #Predicate { $0.id == id && $0.ownerID == userID })
            ).first
        else { return nil }
        return try mapBudget(requireBudget(id: row.id, userID: userID), userID: userID)
    }
    public func getTag(id: String, userID: String) throws -> Tag? {
        guard
            let row = try modelContext.fetch(
                FetchDescriptor<TagEntity>(
                    predicate: #Predicate { $0.id == id && $0.user == userID })
            ).first
        else { return nil }
        return try mapTag(row)
    }
    public func getTransaction(id: String, userID: String) throws -> CashlyDomain.Transaction? {
        let catalog = try catalog(userID: userID, includesBudgets: false)
        var descriptor = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { $0.id == id && $0.ownerID == userID })
        descriptor.fetchLimit = 2
        let rows = try modelContext.fetch(descriptor)
        guard rows.count <= 1 else { throw CashlyError.onFetch }
        let result = try mapTransactions(rows, userID: userID, catalog: catalog)
        guard result.pending == 0 else {
            throw CashlyError.persistence(
                String(
                    appLocalized:
                        "This transaction's references are still incomplete. Wait for sync to finish."
                ))
        }
        return result.items.first
    }
    func descriptor(
        userID: String, query: TransactionQuery, after cursor: TransactionCursor?, limit: Int
    ) -> FetchDescriptor<TransactionEntity> {
        let categories = query.categoryIDs
        let kinds = Set(query.kinds.map(\.rawValue))
        let statuses = Set(query.statuses.map(\.rawValue))
        let month = query.month?.monthIndex ?? 0
        let filteringMonth = query.month != nil
        let before = cursor?.timestamp ?? 0
        let afterID = cursor?.id ?? ""
        let hasCursor = cursor != nil
        let scope = #Predicate<TransactionEntity> { $0.ownerID == userID }
        let classification = #Predicate<TransactionEntity> {
            (categories.isEmpty || categories.contains($0.categoryID))
                && (kinds.isEmpty || kinds.contains($0.kind))
                && (statuses.isEmpty || statuses.contains($0.status))
        }
        let period = #Predicate<TransactionEntity> {
            !filteringMonth || ($0.startMonthIndex <= month && $0.endMonthIndex >= month)
        }
        let position = #Predicate<TransactionEntity> {
            (!hasCursor || $0.date <= before)
                && (!hasCursor || $0.date != before || $0.id < afterID)
        }
        var result = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate {
                scope.evaluate($0) && classification.evaluate($0) && period.evaluate($0)
                    && position.evaluate($0)
            },
            sortBy: [
                SortDescriptor(\.date, order: .reverse), SortDescriptor(\.id, order: .reverse),
            ])
        result.fetchLimit = limit
        return result
    }
    func matches(_ record: CashlyDomain.Transaction, query: TransactionQuery) -> Bool {
        (query.matches(text: record.summary) || query.matches(text: record.category.name))
            && (query.categoryIDs.isEmpty || query.categoryIDs.contains(record.category.id))
            && (query.tagIDs.isEmpty || !record.tagIDs.isDisjoint(with: query.tagIDs))
            && (query.participantUserIDs.isEmpty
                || !Set(record.participants.map(\.user.id)).isDisjoint(
                    with: query.participantUserIDs))
    }
    public func page(
        userID: String, query: TransactionQuery, after cursor: TransactionCursor?, limit: Int
    ) throws -> TransactionPage {
        try CashlyMetrics.measure("TransactionPage") {
            let catalog = try catalog(userID: userID, month: query.month)
            let pageSize = min(max(limit, 1), 200)
            var items: [CashlyDomain.Transaction] = []
            var pending = 0
            var position = cursor
            var hasMore = false
            repeat {
                try Task.checkCancellation()
                let rows = try modelContext.fetch(
                    descriptor(userID: userID, query: query, after: position, limit: 200))
                guard !rows.isEmpty else {
                    hasMore = false
                    break
                }
                let mapped = try mapTransactions(rows, userID: userID, catalog: catalog)
                let records = Dictionary(
                    mapped.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                pending += mapped.pending
                for row in rows {
                    position = TransactionCursor(timestamp: row.date, id: row.id)
                    if let record = records[row.id], matches(record, query: query) {
                        items.append(record)
                    }
                    if items.count == pageSize {
                        hasMore = true
                        break
                    }
                }
                if items.count == pageSize { break }
                hasMore = rows.count == 200
            } while hasMore
            return TransactionPage(
                items: items, nextCursor: hasMore ? position : nil, pendingReferences: pending)
        }
    }
    public func loadDashboard(userID: String, query: TransactionQuery) throws -> DashboardState {
        let catalog = try catalog(userID: userID, month: query.month)
        let overview = try overview(userID: userID, query: query)
        let count = try modelContext.fetchCount(
            FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.ownerID == userID }))
        return DashboardState(
            catalog: catalog, overview: overview,
            datasetRevision: try datasetRevision(userID: userID), totalTransactionCount: count)
    }
    public func overview(userID: String, query: TransactionQuery) throws -> CashlyOverview {
        try CashlyMetrics.measure("DashboardOverview") {
            let catalog = try catalog(userID: userID, month: query.month)
            var accumulator = try OverviewAccumulator(
                budgets: catalog.budgets, month: query.month, categoryIDs: query.categoryIDs,
                pendingReferences: catalog.pendingReferences)
            var cursor: TransactionCursor?
            repeat {
                try Task.checkCancellation()
                let rows = try modelContext.fetch(
                    descriptor(userID: userID, query: query, after: cursor, limit: 500))
                guard !rows.isEmpty else { break }
                let mapped = try mapTransactions(rows, userID: userID, catalog: catalog)
                accumulator.addPendingReferences(mapped.pending)
                for record in mapped.items where matches(record, query: query) {
                    try accumulator.add(record)
                }
                cursor = rows.last.map { TransactionCursor(timestamp: $0.date, id: $0.id) }
                if rows.count < 500 { break }
            } while cursor != nil
            return try accumulator.result()
        }
    }
    public func trainingData(userID: String) throws -> TrainingDataset {
        let catalog = try catalog(userID: userID)
        guard catalog.pendingReferences == 0 else {
            throw CashlyError.intelligence(
                String(appLocalized: "Wait for sync to finish before training the models."))
        }
        var items: [CashlyDomain.Transaction] = []
        var cursor: TransactionCursor?
        repeat {
            try Task.checkCancellation()
            let rows = try modelContext.fetch(
                descriptor(userID: userID, query: .init(), after: cursor, limit: 500))
            guard !rows.isEmpty else { break }
            let mapped = try mapTransactions(rows, userID: userID, catalog: catalog)
            guard mapped.pending == 0 else {
                throw CashlyError.intelligence(
                    String(appLocalized: "Wait for sync to finish before training the models."))
            }
            items.append(contentsOf: mapped.items)
            cursor = rows.last.map { TransactionCursor(timestamp: $0.date, id: $0.id) }
            if rows.count < 500 { break }
        } while cursor != nil
        return TrainingDataset(
            transactions: items, tags: catalog.tags, revision: try datasetRevision(userID: userID))
    }
    public func datasetRevision(userID: String) throws -> String {
        try ensureNormalization()
        if let cached = datasetCache[userID] { return cached }
        var hasher = SHA256()
        var lastID: String?
        repeat {
            try Task.checkCancellation()
            let cursor = lastID ?? ""
            let hasCursor = lastID != nil
            var descriptor = FetchDescriptor<TransactionEntity>(
                predicate: #Predicate { $0.ownerID == userID && (!hasCursor || $0.id > cursor) },
                sortBy: [SortDescriptor(\.id)])
            descriptor.fetchLimit = 1000
            let rows = try modelContext.fetch(descriptor)
            let ids = Set(rows.map(\.id))
            let participants = try modelContext.fetch(
                FetchDescriptor<ParticipantEntity>(
                    predicate: #Predicate { ids.contains($0.transaction) },
                    sortBy: [SortDescriptor(\.transaction), SortDescriptor(\.id)]))
            let fields = rows.map { row in
                [
                    row.id, row.contentRevision, String(row.amountMinorUnits ?? -1),
                    String(row.date.bitPattern), row.summary, String(row.status),
                    String(row.paymentsPlan ?? 1), row.categoryID, String(row.kind), row.ownerID,
                ]

            }
            let shares = participants.map {
                [
                    $0.id, $0.transaction, $0.user, String($0.splitMode),
                    String($0.splitValue.bitPattern),
                    String($0.status),
                ]
            }
            let links = rows.map { [$0.id] + $0.participants.sorted() }
            let tagLinks = rows.map { [$0.id] + $0.tagIDs.sorted() }
            let payload = try JSONEncoder().encode([fields, shares, links, tagLinks])
            hasher.update(data: payload)
            lastID = rows.last?.id
            if rows.count < 1000 { break }
        } while lastID != nil
        let tags = try modelContext.fetch(
            FetchDescriptor<TagEntity>(
                predicate: #Predicate { $0.user == userID }, sortBy: [SortDescriptor(\.id)]))
        hasher.update(data: try JSONEncoder().encode(tags.map { [$0.id, $0.name] }))
        let revision = hasher.finalize().map { String(format: "%02x", $0) }.joined()
        datasetCache[userID] = revision
        return revision
    }
}
