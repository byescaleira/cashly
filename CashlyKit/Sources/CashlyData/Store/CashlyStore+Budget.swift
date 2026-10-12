import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func removeBudget(id: String, userID: String) throws {
        try ensureNormalization()
        guard
            try modelContext.fetch(
                FetchDescriptor<TransactionEntity>(
                    predicate: #Predicate { $0.budget == id && $0.categoryID == "" })
            ).isEmpty
        else { throw CashlyError.onRemove }
        let owned = try requireBudget(id: id, userID: userID)
        guard owned.id == id,
            try modelContext.fetchCount(
                FetchDescriptor<BudgetEntity>(
                    predicate: #Predicate { $0.ownerID == userID && $0.mergedIntoID == id })) == 0
        else { throw CashlyError.onRemove }
        let predicate: Predicate<BudgetEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<BudgetEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(entity)
        try commit(userID: userID)
    }

    public func save(_ budget: Budget, userID: String) throws {
        try ensureNormalization()
        try upsert(budget, userID: userID, allowsConflict: false)
        try commit(userID: userID)
    }

    func upsert(_ budget: Budget, userID: String, allowsConflict: Bool) throws {
        let id = budget.id
        let money = budget.money
        let category = budget.category
        let summary = budget.summary
        let date = budget.month.rawValue
        let categoryID = category.id
        _ = try requireCategory(id: category.id, userID: userID)
        guard category.user.id == userID else { throw CashlyError.onSave }
        let canonical = money
        guard canonical.minorUnits > 0,
            summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
            try modelContext.fetch(
                FetchDescriptor<CategoryEntity>(predicate: #Predicate { $0.id == categoryID })
            ).first != nil
        else { throw CashlyError.onSave }
        let duplicate = try modelContext.fetch(
            FetchDescriptor<BudgetEntity>(
                predicate: #Predicate {
                    $0.category == categoryID && $0.date == date && $0.id != id
                        && $0.mergedIntoID == ""
                }))
        guard allowsConflict || duplicate.isEmpty else {
            throw CashlyError.invalidInput(
                String(
                    appLocalized:
                        "A budget already exists for this category and month. Edit the existing budget."
                ))
        }
        let predicate: Predicate<BudgetEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<BudgetEntity>(predicate: predicate)
        let entity =
            try modelContext.fetch(descriptor).first
            ?? BudgetEntity(
                id: id,
                amount: canonical.doubleValue,
                category: category.id,
                date: date,
                summary: summary
            )
        entity.id = id
        guard entity.ownerID.isEmpty || entity.ownerID == userID else { throw CashlyError.onSave }
        entity.ownerID = userID
        entity.amount = canonical.doubleValue
        entity.amountMinorUnits = canonical.minorUnits
        entity.amountSource = entity.amount
        entity.currencyCode = Money.currencyCode
        entity.category = category.id
        entity.date = date
        entity.summary = summary
        modelContext.insert(entity)
    }

}
