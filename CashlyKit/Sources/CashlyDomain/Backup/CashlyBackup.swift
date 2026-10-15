import Foundation

public struct CashlyBackup: Codable, Equatable, Sendable {
    public static let format = "cashly-backup"
    public static let version = 2

    public var format: String
    public var version: Int
    public var currency: String
    public var exportedAt: Date
    public var users: [UserRecord]
    public var categories: [LabelRecord]
    public var tags: [LabelRecord]
    public var budgets: [BudgetRecord]
    public var transactions: [TransactionRecord]

    public struct UserRecord: Codable, Equatable, Sendable {
        public var id: String
        public var name: String
        public var photo: String
        public var photoData: Data?
    }

    public struct LabelRecord: Codable, Equatable, Sendable {
        public var id: String
        public var userID: String
        public var name: String
        public var color: String
        public var icon: String
    }

    public struct BudgetRecord: Codable, Equatable, Sendable {
        public var id: String
        public var categoryID: String
        public var month: Int
        public var amount: Int64
        public var summary: String
    }

    public struct TransactionRecord: Codable, Equatable, Sendable {
        public var id: String
        public var categoryID: String
        public var kind: Int
        public var amount: Int64
        public var date: Date
        public var summary: String
        public var status: Int
        public var splitMode: Int?
        public var splitValue: Double?
        public var paymentsPlan: Int?
        public var tagIDs: [String]
        public var participants: [ParticipantRecord]
    }

    public struct ParticipantRecord: Codable, Equatable, Sendable {
        public var id: String
        public var userID: String
        public var splitMode: Int
        public var splitValue: Double
        public var status: Int
    }

    public init(data: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(CashlyBackup.self, from: data),
            backup.format == Self.format
        else {
            throw CashlyError.invalidInput(String(appLocalized: "This file isn't a Cashly backup."))
        }
        guard backup.version <= Self.version else {
            throw CashlyError.invalidInput(
                String(
                    appLocalized:
                        "This backup was made by a newer version of Cashly. Update the app."))
        }
        guard CurrencySetting.isSupported(backup.currency) else {
            throw CashlyError.invalidInput(
                String(appLocalized: "This backup uses a currency that isn't supported yet."))
        }
        self = backup
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }
}
