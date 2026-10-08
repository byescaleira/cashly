import CashlyDomain
import Foundation
import SwiftData

extension CashlyRepository {
    func money(minorUnits: Int64?, legacy: Double, currencyCode: String = Money.currencyCode) throws
        -> Money
    {
        guard currencyCode == Money.currencyCode else {
            throw CashlyError.persistence(
                "Este registro usa uma moeda ainda não suportada pelo Cashly.")
        }
        let value = try minorUnits.map(Money.init(minorUnits:)) ?? Money(validating: legacy)
        guard value.minorUnits >= 0 else { throw CashlyError.onFetch }
        return value
    }
    func mapCategory(_ row: CategoryEntity) throws -> CashlyDomain.Category {
        guard let user = try getUser(id: row.user) else { throw CashlyError.missingRecord }
        return CashlyDomain.Category(
            id: row.id, user: user, name: row.name, color: row.color, icon: row.icon)
    }
    func mapBudget(_ row: BudgetEntity, userID: String) throws -> Budget {
        let category = try mapCategory(requireCategory(id: row.category, userID: userID))
        let categoryID = row.category
        let month = row.date
        var descriptor = FetchDescriptor<BudgetEntity>(
            predicate: #Predicate {
                $0.ownerID == userID && $0.category == categoryID && $0.date == month
                    && $0.mergedIntoID == ""
            })
        descriptor.fetchLimit = 2
        let conflicted = try modelContext.fetch(descriptor).count > 1
        guard let budgetMonth = YearMonth(rawValue: row.date) else {
            throw CashlyError.missingRecord
        }
        return Budget(
            id: row.id,
            money: try money(
                minorUnits: row.amountMinorUnits, legacy: row.amount, currencyCode: row.currencyCode
            ),
            category: category, month: budgetMonth, summary: row.summary,
            isConflicted: row.isConflicted || conflicted)
    }
    func mapTag(_ row: TagEntity) throws -> Tag {
        guard let user = try getUser(id: row.user) else { throw CashlyError.missingRecord }
        return Tag(id: row.id, user: user, name: row.name, color: row.color, icon: row.icon)
    }
    func mapParticipant(_ row: ParticipantEntity, users: [String: User]) throws -> Participant {
        guard let user = users[row.user], let mode = TransactionSplitMode(rawValue: row.splitMode),
            let status = TransactionStatus(rawValue: row.status)
        else { throw CashlyError.missingRecord }
        return Participant(
            id: row.id, user: user, splitMode: mode, splitValue: row.splitValue, status: status,
            transaction: row.transaction,
            allocatedMoney: row.allocatedMinorUnits.map(Money.init(minorUnits:)))
    }
    func mapTransactions(_ rows: [TransactionEntity], userID: String, catalog: CashlySnapshot)
        throws
        -> (items: [CashlyDomain.Transaction], pending: Int)
    {
        guard !rows.isEmpty else { return ([], 0) }
        let recordIDs = Set(rows.map(\.id))
        var identityQuery = FetchDescriptor<TransactionEntity>(
            predicate: #Predicate { recordIDs.contains($0.id) && $0.ownerID == userID })
        identityQuery.propertiesToFetch = [\.id]
        let identities = try modelContext.fetch(identityQuery)
        guard identities.count == recordIDs.count else {
            throw CashlyError.persistence(
                "Existem transações com IDs conflitantes no armazenamento. Os registros foram preservados."
            )
        }
        let users = try uniqueIndex(catalog.users)
        let categories = try uniqueIndex(catalog.categories)
        let ids = Set(rows.map(\.id))
        let participantRows = try modelContext.fetch(
            FetchDescriptor<ParticipantEntity>(
                predicate: #Predicate { ids.contains($0.transaction) }))
        var participants: [String: Participant] = [:]
        var badParticipantIDs: Set<String> = []
        for row in participantRows {
            if participants[row.id] != nil {
                badParticipantIDs.insert(row.id)
                continue
            }
            do { participants[row.id] = try mapParticipant(row, users: users) } catch {
                badParticipantIDs.insert(row.id)
            }
        }
        let tagIDs = Set(catalog.tags.map(\.id))
        var items: [CashlyDomain.Transaction] = []
        var pending = 0
        for row in rows {
            do {
                guard let category = categories[row.categoryID], category.user.id == row.ownerID,
                    let kind = TransactionKind(rawValue: row.kind),
                    let status = TransactionStatus(rawValue: row.status),
                    Set(row.participants).count == row.participants.count,
                    kind != .income || row.participants.isEmpty,
                    Set(row.tagIDs).isSubset(of: tagIDs)
                else { throw CashlyError.missingRecord }
                var related = try row.participants.map { id -> Participant in
                    guard !badParticipantIDs.contains(id), let value = participants[id],
                        value.transaction == row.id
                    else { throw CashlyError.missingRecord }
                    return value
                }
                let value = try money(
                    minorUnits: row.amountMinorUnits, legacy: row.amount,
                    currencyCode: row.currencyCode)
                let allocation = try TransactionAllocation.resolve(
                    total: value, participants: related)
                for index in related.indices {
                    related[index].allocatedMoney = allocation.participants[related[index].id]
                }
                items.append(
                    CashlyDomain.Transaction(
                        id: row.id, participants: related, category: category, money: value,
                        date: Date(timeIntervalSince1970: row.date),
                        summary: row.summary, status: status,
                        splitMode: row.splitMode.flatMap(TransactionSplitMode.init),
                        splitValue: allocation.owner.doubleValue, paymentsPlan: row.paymentsPlan,
                        ownerMoney: allocation.owner, tagIDs: Set(row.tagIDs), kind: kind))
            } catch { pending += 1 }
        }
        return (items, pending)
    }
    func uniqueIndex<Entity: Identifiable>(_ values: [Entity]) throws -> [String: Entity]
    where Entity.ID == String {
        var output: [String: Entity] = [:]
        for value in values {
            guard output.updateValue(value, forKey: value.id) == nil else {
                throw CashlyError.persistence(
                    "Existem IDs conflitantes no armazenamento. Atualize a sincronização antes de continuar."
                )
            }
        }
        return output
    }
}
