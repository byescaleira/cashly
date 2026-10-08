import CashlyDomain
import Foundation
import SwiftData

extension CashlyRepository {
    public func removeTransaction(id: String, userID: String) throws {
        _ = try requireTransaction(id: id, userID: userID)
        let predicate: Predicate<TransactionEntity> = #Predicate {
            $0.id == id
        }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        guard let entity = try modelContext.fetch(descriptor).first else { return }
        let participantRows = try modelContext.fetch(
            FetchDescriptor<ParticipantEntity>(predicate: #Predicate { $0.transaction == id }))
        for row in participantRows { modelContext.delete(row) }
        modelContext.delete(entity)
        try commit(userID: userID)
    }

    public func removeTransactions(ids: Set<String>, userID: String) throws {
        let rows = try modelContext.fetch(
            FetchDescriptor<TransactionEntity>(
                predicate: #Predicate { ids.contains($0.id) && $0.ownerID == userID }))
        guard rows.count == ids.count else { throw CashlyError.onRemove }
        let participants = try modelContext.fetch(
            FetchDescriptor<ParticipantEntity>(
                predicate: #Predicate { ids.contains($0.transaction) }))
        for row in rows { modelContext.delete(row) }
        for row in participants { modelContext.delete(row) }
        try commit(userID: userID)
    }
    public func removeTransactions(userID: String) throws {
        let rows = try modelContext.fetch(
            FetchDescriptor<TransactionEntity>(predicate: #Predicate { $0.ownerID == userID }))
        let ids = Set(rows.map(\.id))
        let participants = try modelContext.fetch(
            FetchDescriptor<ParticipantEntity>(
                predicate: #Predicate { ids.contains($0.transaction) }))
        for row in rows { modelContext.delete(row) }
        for row in participants { modelContext.delete(row) }
        try commit(userID: userID)
    }

    public func addTransaction(
        id: String,
        participants: [Participant],
        categoryID: String,
        kind: TransactionKind,
        money: Money,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        tagIDs: Set<String>,
        userID: String
    ) throws {
        do {
            try upsertTransaction(
                id: id, participants: participants, categoryID: categoryID, kind: kind,
                money: money,
                date: date, summary: summary, status: status, splitMode: splitMode,
                splitValue: splitValue,
                paymentsPlan: paymentsPlan, tagIDs: tagIDs, userID: userID)
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    private func upsertTransaction(
        id: String,
        participants: [Participant],
        categoryID: String,
        kind: TransactionKind,
        money: Money,
        date: TimeInterval,
        summary: String,
        status: TransactionStatus,
        splitMode: TransactionSplitMode?,
        splitValue: Double?,
        paymentsPlan: Int?,
        tagIDs: Set<String>,
        userID: String
    ) throws {
        try ensureNormalization()
        let canonical = money
        let allocation = try TransactionAllocation.resolve(
            total: canonical, participants: participants)
        let storedCategory = try requireCategory(id: categoryID, userID: userID)
        for tagID in tagIDs { _ = try requireTag(id: tagID, userID: userID) }
        guard storedCategory.user == userID,
            canonical.minorUnits > 0, date.isFinite,
            summary.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3,
            paymentsPlan == nil || (1...1200).contains(paymentsPlan ?? 0),
            kind != .income || participants.isEmpty
        else { throw CashlyError.onSave }
        guard
            participants.allSatisfy({
                $0.transaction == id && $0.splitValue.isFinite && $0.splitValue >= 0
            }),
            Set(participants.map(\.user.id)).count == participants.count,
            Set(participants.map(\.id)).count == participants.count,
            !participants.contains(where: { $0.user.id == userID })
        else { throw CashlyError.onSave }
        if !participants.isEmpty {
            guard let splitValue, try Money(validating: splitValue) == allocation.owner else {
                throw CashlyError.onSave
            }
        }
        let previous = try modelContext.fetch(
            FetchDescriptor<ParticipantEntity>(predicate: #Predicate { $0.transaction == id }))
        let retained = Set(participants.map(\.id))
        for row in previous where !retained.contains(row.id) { modelContext.delete(row) }
        for participant in participants {
            guard try getUser(id: participant.user.id) != nil else {
                modelContext.rollback()
                throw CashlyError.missingRecord
            }
            let participantID = participant.id
            let row =
                try modelContext.fetch(
                    FetchDescriptor<ParticipantEntity>(
                        predicate: #Predicate { $0.id == participantID })
                ).first
                ?? ParticipantEntity(
                    id: participant.id, user: participant.user.id, name: participant.user.name,
                    photo: participant.user.photo, splitMode: participant.splitMode.rawValue,
                    splitValue: participant.splitValue, status: participant.status.rawValue,
                    transaction: id)
            guard row.transaction == id else { throw CashlyError.onSave }
            row.user = participant.user.id
            row.name = participant.user.name
            row.photo = participant.user.photo
            row.splitMode = participant.splitMode.rawValue
            row.splitValue = participant.splitValue
            row.allocatedMinorUnits = allocation.participants[participant.id]?.minorUnits
            row.status = participant.status.rawValue
            row.transaction = id
            modelContext.insert(row)
        }
        let predicate: Predicate<TransactionEntity> = #Predicate { $0.id == id }
        let descriptor = FetchDescriptor<TransactionEntity>(predicate: predicate)
        let entity =
            try modelContext.fetch(descriptor).first
            ?? TransactionEntity(
                id: id,
                participants: participants.map(\.id),
                budget: "",
                amount: canonical.doubleValue,
                date: date,
                summary: summary,
                status: status.rawValue,
                splitMode: splitMode?.rawValue,
                splitValue: splitValue,
                paymentsPlan: paymentsPlan
            )
        entity.id = id
        entity.participants = participants.map(\.id)
        entity.categoryID = categoryID
        entity.kind = kind.rawValue
        guard entity.ownerID.isEmpty || entity.ownerID == userID else { throw CashlyError.onSave }
        entity.ownerID = userID
        entity.amount = canonical.doubleValue
        entity.amountSource = canonical.doubleValue
        entity.amountMinorUnits = canonical.minorUnits
        entity.ownerMinorUnits = allocation.owner.minorUnits
        entity.currencyCode = Money.currencyCode
        entity.tagIDs = tagIDs.sorted()
        entity.tagsMigrated = true
        let month = date.yearMonth
        entity.startMonthIndex = month / 100 * 12 + month % 100 - 1
        entity.endMonthIndex = entity.startMonthIndex + max(paymentsPlan ?? 1, 1) - 1
        entity.contentRevision = UUID().uuidString
        entity.dateSource = date
        entity.paymentsPlanSource = paymentsPlan
        entity.date = date
        entity.summary = summary
        entity.status = status.rawValue
        entity.splitMode = splitMode?.rawValue
        entity.splitValue = splitValue
        entity.paymentsPlan = paymentsPlan
        modelContext.insert(entity)
        try commit(userID: userID)
    }

}
