import CashlyDomain
import Foundation
import SwiftData

extension CashlyStore {
    public func getCaptures(status: Capture.Status?, userID: String) throws -> [Capture] {
        let wanted = status?.rawValue ?? ""
        let filtersStatus = status != nil
        return try modelContext.fetch(
            FetchDescriptor<CaptureEntity>(
                predicate: #Predicate {
                    $0.ownerID == userID && (!filtersStatus || $0.status == wanted)
                },
                sortBy: [SortDescriptor(\.date, order: .reverse), SortDescriptor(\.id)])
        ).compactMap(Self.capture)
    }

    public func getCapture(id: String, userID: String) throws -> Capture? {
        var descriptor = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == id && $0.ownerID == userID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.flatMap(Self.capture)
    }

    public func saveCapture(_ capture: Capture, userID: String) throws -> Capture {
        guard capture.ownerID == userID, capture.money.minorUnits > 0 else {
            throw CashlyError.onSave
        }
        guard try getUser(id: userID) != nil else { throw CashlyError.missingRecord }
        let id = capture.id
        var byID = FetchDescriptor<CaptureEntity>(
            predicate: #Predicate { $0.id == id && $0.ownerID == userID })
        byID.fetchLimit = 1
        let row: CaptureEntity
        if let existing = try modelContext.fetch(byID).first {
            row = existing
        } else {
            let key = capture.merchantKey
            let minute = capture.minute
            let amount = capture.money.minorUnits
            var twin = FetchDescriptor<CaptureEntity>(
                predicate: #Predicate {
                    $0.ownerID == userID && $0.merchantKey == key && $0.minute == minute
                        && $0.amountMinorUnits == amount
                })
            twin.fetchLimit = 1
            if let duplicate = try modelContext.fetch(twin).first.flatMap(Self.capture) {
                return duplicate
            }
            row = CaptureEntity(id: id, ownerID: userID)
            row.createdAt = capture.createdAt.timeIntervalSince1970
            modelContext.insert(row)
        }
        row.amountMinorUnits = capture.money.minorUnits
        row.currencyCode = Money.currencyCode
        row.merchant = capture.merchant
        row.merchantKey = capture.merchantKey
        row.card = capture.card
        row.date = capture.date.timeIntervalSince1970
        row.minute = capture.minute
        row.source = capture.source.rawValue
        row.suggestedCategoryID = capture.suggestedCategoryID ?? ""
        row.suggestedSummary = capture.suggestedSummary
        row.suggestedTagIDs = capture.suggestedTagIDs.sorted()
        row.status = capture.status.rawValue
        row.transactionID = capture.transactionID ?? ""
        try commit(userID: userID)
        return Self.capture(row) ?? capture
    }

    public func getMerchantMemory(key: String, userID: String) throws -> MerchantMemory? {
        var descriptor = FetchDescriptor<MerchantMemoryEntity>(
            predicate: #Predicate { $0.key == key && $0.ownerID == userID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first.map {
            MerchantMemory(
                key: $0.key, ownerID: $0.ownerID, categoryID: $0.categoryID, summary: $0.summary,
                tagIDs: Set($0.tagIDs), count: $0.count)
        }
    }

    public func rememberMerchant(_ memory: MerchantMemory, userID: String) throws {
        guard memory.ownerID == userID, !memory.key.isEmpty else { throw CashlyError.onSave }
        let key = memory.key
        var descriptor = FetchDescriptor<MerchantMemoryEntity>(
            predicate: #Predicate { $0.key == key && $0.ownerID == userID })
        descriptor.fetchLimit = 1
        let row =
            try modelContext.fetch(descriptor).first
            ?? MerchantMemoryEntity(id: UUID().uuidString, ownerID: userID, key: key)
        row.categoryID = memory.categoryID
        row.summary = memory.summary
        row.tagIDs = memory.tagIDs.sorted()
        row.count = memory.count
        row.updatedAt = Date.now.timeIntervalSince1970
        modelContext.insert(row)
        try commit(userID: userID)
    }

    private static func capture(_ row: CaptureEntity) -> Capture? {
        guard let source = Capture.Source(rawValue: row.source),
            let status = Capture.Status(rawValue: row.status)
        else { return nil }
        return Capture(
            id: row.id, ownerID: row.ownerID, money: Money(minorUnits: row.amountMinorUnits),
            merchant: row.merchant, card: row.card, date: Date(timeIntervalSince1970: row.date),
            source: source,
            suggestedCategoryID: row.suggestedCategoryID.isEmpty ? nil : row.suggestedCategoryID,
            suggestedSummary: row.suggestedSummary, suggestedTagIDs: Set(row.suggestedTagIDs),
            status: status, transactionID: row.transactionID.isEmpty ? nil : row.transactionID,
            createdAt: Date(timeIntervalSince1970: row.createdAt))
    }
}
