import Foundation

public struct WebSnapshot: Codable, Equatable, Sendable {
    public struct Profile: Codable, Equatable, Sendable {
        public let name: String
        public let initials: String
        public let color: String
    }

    public enum Pace: String, Codable, Sendable {
        case onTrack, ahead, over
    }

    public struct Month: Codable, Equatable, Sendable {
        public let start: String
        public let end: String
        public let today: String
        public let planned: Double
        public let spent: Double
        public let income: Double
        public let available: Double
        public let usedRatio: Double
        public let elapsedRatio: Double
        public let pace: Pace
        public let perDay: Double
    }

    public struct Budget: Codable, Equatable, Sendable {
        public let name: String
        public let symbol: String
        public let color: String
        public let planned: Double
        public let spent: Double
    }

    public struct Category: Codable, Equatable, Sendable {
        public let name: String
        public let symbol: String
        public let color: String
    }

    public struct Entry: Codable, Equatable, Sendable {
        public let date: String
        public let description: String
        public let kind: String
        public let status: String
        public let amount: Double
        public let category: Category
        public let tags: [String]
    }

    public struct Bill: Codable, Equatable, Sendable {
        public let description: String
        public let dueDate: String
        public let amount: Double
    }

    public static let version = 1
    public static let transactionLimit = 300

    public let v: Int
    public let generatedAt: String
    public let locale: String
    public let currency: String
    public let profile: Profile
    public let month: Month
    public let budgets: [Budget]
    public let transactions: [Entry]
    public let upcoming: [Bill]

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try encoder.encode(self)
    }
}
