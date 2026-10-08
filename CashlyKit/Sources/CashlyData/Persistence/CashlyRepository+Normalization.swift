import CashlyDomain
import Foundation
import SwiftData

extension CashlyRepository {
    public func prepare() throws {
        try CashlyMetrics.measure("NormalizeLegacyStore") {
            let users = try uniqueIndex(getUsers())
            let categories = try modelContext.fetch(FetchDescriptor<CategoryEntity>())
            let categoryMap = Dictionary(
                categories.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            let budgetRows = try modelContext.fetch(
                FetchDescriptor<BudgetEntity>(
                    predicate: #Predicate<BudgetEntity> {
                        $0.amountMinorUnits == nil || $0.ownerID == ""
                            || $0.amountSource != $0.amount
                    }))
            for row in budgetRows {
                guard let category = categoryMap[row.category], users[category.user] != nil,
                    let value = try? Money(validating: row.amount), value.minorUnits > 0
                else { continue }
                if row.amountMinorUnits == nil || row.amountSource != row.amount {
                    row.amountMinorUnits = value.minorUnits
                    row.amountSource = row.amount
                }
                if row.ownerID.isEmpty { row.ownerID = category.user }
            }
            let allTags = try modelContext.fetch(FetchDescriptor<TagEntity>())
            var lastID: String?
            repeat {
                try Task.checkCancellation()
                let cursor = lastID ?? ""
                let hasCursor = lastID != nil
                var legacy = FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate<TransactionEntity> {
                        (!hasCursor || $0.id > cursor)
                            && ($0.categoryID == "" || $0.ownerID == "" || !$0.tagsMigrated
                                || $0.contentRevision == "")
                    }, sortBy: [SortDescriptor(\.id)])
                var values = FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate<TransactionEntity> {
                        (!hasCursor || $0.id > cursor)
                            && ($0.amountMinorUnits == nil || $0.amountSource != $0.amount)
                    }, sortBy: [SortDescriptor(\.id)])
                var dates = FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate<TransactionEntity> {
                        (!hasCursor || $0.id > cursor) && $0.dateSource != $0.date
                    }, sortBy: [SortDescriptor(\.id)])
                var installments = FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate {
                        (!hasCursor || $0.id > cursor) && $0.paymentsPlanSource != $0.paymentsPlan
                    }, sortBy: [SortDescriptor(\.id)])
                legacy.fetchLimit = 500
                values.fetchLimit = 500
                installments.fetchLimit = 500
                dates.fetchLimit = 500
                let candidates =
                    try modelContext.fetch(legacy) + modelContext.fetch(values)
                    + modelContext.fetch(installments) + modelContext.fetch(dates)
                let unique = Dictionary(
                    candidates.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                let rows = Array(unique.values.sorted { $0.id < $1.id }.prefix(500))
                guard !rows.isEmpty else { break }
                let ids = Set(rows.map(\.id))
                let related = try modelContext.fetch(
                    FetchDescriptor<ParticipantEntity>(
                        predicate: #Predicate { ids.contains($0.transaction) })
                )
                let byTransaction = Dictionary(grouping: related, by: \.transaction)
                let budgetIDs = Set(rows.map(\.budget))
                let referenced = try modelContext.fetch(
                    FetchDescriptor<BudgetEntity>(
                        predicate: #Predicate { budgetIDs.contains($0.id) }))
                let byBudget = Dictionary(
                    referenced.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                for row in rows {
                    let categoryID =
                        row.categoryID.isEmpty ? byBudget[row.budget]?.category : row.categoryID
                    guard let categoryID, let category = categoryMap[categoryID],
                        users[category.user] != nil
                    else { continue }
                    if row.ownerID.isEmpty { row.ownerID = category.user }
                    guard row.ownerID == category.user else { continue }
                    if row.categoryID.isEmpty { row.categoryID = category.id }
                    guard let value = try? Money(validating: row.amount), value.minorUnits > 0
                    else {
                        continue
                    }
                    if row.amountMinorUnits == nil || row.amountSource != row.amount {
                        row.amountMinorUnits = value.minorUnits
                        row.amountSource = row.amount
                    }
                    if row.dateSource != row.date { row.dateSource = row.date }
                    if row.paymentsPlanSource != row.paymentsPlan {
                        row.paymentsPlanSource = row.paymentsPlan
                    }
                    let month = row.date.yearMonth
                    let start = month / 100 * 12 + month % 100 - 1
                    let end = start + max(min(row.paymentsPlan ?? 1, 1200), 1) - 1
                    if row.startMonthIndex != start { row.startMonthIndex = start }
                    if row.endMonthIndex != end { row.endMonthIndex = end }
                    if !row.tagsMigrated {
                        row.tagIDs = allTags.filter {
                            $0.user == category.user
                                && row.summary.localizedCaseInsensitiveContains($0.name)
                        }.map(\.id).sorted()
                        row.tagsMigrated = true
                    }
                    let partyRows = byTransaction[row.id, default: []]
                    let partyMap = Dictionary(
                        partyRows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
                    do {
                        let participants = try row.participants.map { id -> Participant in
                            guard let party = partyMap[id] else { throw CashlyError.missingRecord }
                            return try mapParticipant(party, users: users)
                        }
                        let allocation = try TransactionAllocation.resolve(
                            total: value, participants: participants)
                        row.ownerMinorUnits = allocation.owner.minorUnits
                        for party in partyRows {
                            party.allocatedMinorUnits =
                                allocation.participants[party.id]?.minorUnits
                        }
                        row.contentRevision = UUID().uuidString
                    } catch { continue }
                }
                lastID = rows.last?.id
                if rows.count < 500 { break }
            } while lastID != nil
            try reconcileResolutions()
            if modelContext.hasChanges { try commit() }
        }
    }
}
