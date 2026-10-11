import Foundation

public struct SpreadsheetRow: Hashable, Sendable {
    public let line: Int
    public let date: Date
    public let summary: String
    public let category: String
    public let kind: TransactionKind
    public let status: TransactionStatus
    public let money: Money
    public let installments: Int
    public let tags: [String]
}

public struct SpreadsheetIssue: Hashable, Sendable, Identifiable {
    public let line: Int
    public let message: String
    public var id: Int { line }
}

public struct SpreadsheetPreview: Sendable {
    public let rows: [SpreadsheetRow]
    public let issues: [SpreadsheetIssue]

    public var categories: [String] { Self.unique(rows.map(\.category)) }
    public var tags: [String] { Self.unique(rows.flatMap(\.tags)) }
    public var income: Money { total(of: .income) }
    public var expenses: Money { total(of: .expense) }

    public func newCategories(existing: [String]) -> [String] {
        let known = Set(existing.map(SpreadsheetParser.key))
        return categories.filter { !known.contains(SpreadsheetParser.key($0)) }
    }

    public func newTags(existing: [String]) -> [String] {
        let known = Set(existing.map(SpreadsheetParser.key))
        return tags.filter { !known.contains(SpreadsheetParser.key($0)) }
    }

    private func total(of kind: TransactionKind) -> Money {
        Money(minorUnits: rows.filter { $0.kind == kind }.reduce(0) { $0 + $1.money.minorUnits })
    }

    private static func unique(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.filter { seen.insert(SpreadsheetParser.key($0)).inserted }
    }
}
