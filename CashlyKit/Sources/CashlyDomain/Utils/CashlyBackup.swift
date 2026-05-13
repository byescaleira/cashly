//
//  CashlyBackup.swift
//  CashlyKit
//
//  Reimportable JSON snapshot of every user-owned entity. Used by
//  the Share Sheet export in Settings — sister to CashlyCSVExporter
//  but carries the full graph (users, categories, budgets, tags,
//  transactions, participants) so a future import flow can restore
//  state losslessly.
//

import Foundation

public struct CashlyBackup: Codable, Sendable, Equatable {
    public let version: Int
    public let exportedAt: Date
    public let users: [User]
    public let categories: [Category]
    public let budgets: [Budget]
    public let tags: [Tag]
    public let transactions: [Transaction]

    public init(
        version: Int = 1,
        exportedAt: Date = Date(),
        users: [User],
        categories: [Category],
        budgets: [Budget],
        tags: [Tag],
        transactions: [Transaction]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.users = users
        self.categories = categories
        self.budgets = budgets
        self.tags = tags
        self.transactions = transactions
    }
}

public enum CashlyBackupCoder {
    /// Serialise the backup with sorted keys + ISO-8601 dates so
    /// diffs are reviewable and tools can parse the dates without
    /// configuration.
    public static func encode(_ backup: CashlyBackup) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backup)
        return String(decoding: data, as: UTF8.self)
    }

    /// Round-trip helper for the future import flow.
    public static func decode(_ json: String) throws -> CashlyBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(CashlyBackup.self, from: Data(json.utf8))
    }
}
