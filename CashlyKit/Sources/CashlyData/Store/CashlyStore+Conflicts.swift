import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func resolveBudgetConflict(keeping budgetID: String, userID: String) throws {
        try ensureNormalization()
        let kept = try requireBudget(id: budgetID, userID: userID)
        let categoryID = kept.category
        let month = kept.date
        let candidates = try modelContext.fetch(
            FetchDescriptor<BudgetEntity>(
                predicate: #Predicate {
                    $0.ownerID == userID && $0.category == categoryID && $0.date == month
                }))
        guard candidates.filter({ $0.mergedIntoID.isEmpty }).count > 1 else { return }
        let token = UUID().uuidString
        let timestamp = Date.now.timeIntervalSince1970
        do {
            for row in candidates {
                row.resolutionToken = token
                row.resolutionTimestamp = timestamp
                row.resolvedTargetID = kept.id
                row.mergedIntoID = row.id == kept.id ? "" : kept.id
                row.isConflicted = false
            }
            try commit(userID: userID)
        } catch {
            modelContext.rollback()
            throw error
        }
    }
    func reconcileResolutions() throws {
        let rows = try modelContext.fetch(
            FetchDescriptor<BudgetEntity>(predicate: #Predicate { $0.resolutionToken != "" }))
        let groups = Dictionary(
            grouping: rows, by: { $0.ownerID + ":" + $0.category + ":" + String($0.date) })
        for values in groups.values {
            guard
                let winner = values.max(by: { a, b in
                    a.resolutionTimestamp == b.resolutionTimestamp
                        ? a.resolutionToken < b.resolutionToken
                        : a.resolutionTimestamp < b.resolutionTimestamp
                }), values.contains(where: { $0.id == winner.resolvedTargetID })
            else { continue }
            let target = winner.resolvedTargetID
            let token = winner.resolutionToken
            let timestamp = winner.resolutionTimestamp
            for row in values {
                let alias = row.id == target ? "" : target
                if row.mergedIntoID != alias { row.mergedIntoID = alias }
                if row.resolvedTargetID != target { row.resolvedTargetID = target }
                if row.resolutionToken != token { row.resolutionToken = token }
                if row.resolutionTimestamp != timestamp { row.resolutionTimestamp = timestamp }
            }
        }
    }

}
