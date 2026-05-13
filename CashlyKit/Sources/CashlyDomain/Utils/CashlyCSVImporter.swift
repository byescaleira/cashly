//
//  CashlyCSVImporter.swift
//  CashlyKit
//
//  Pure-Swift RFC 4180 parser. Reads the same column layout
//  CashlyCSVExporter emits and returns structured row values the
//  caller can map to Domain entities. Format errors surface as
//  ``CashlyCSVImporter.Error`` so the UI can show a precise line
//  number on failure.
//

import Foundation

public enum CashlyCSVImporter {
    public enum Failure: Error, Equatable, Sendable {
        case missingHeader
        case unexpectedColumns(line: Int, found: Int, expected: Int)
        case invalidAmount(line: Int, raw: String)
        case invalidDate(line: Int, raw: String)
    }

    public struct TransactionRow: Equatable, Sendable {
        public let date: TimeInterval
        public let summary: String
        public let amount: Double
        public let categoryName: String
        public let budgetSummary: String
        public let status: String
        public let participantNames: [String]
    }

    public struct BudgetRow: Equatable, Sendable {
        public let date: Int
        public let categoryName: String
        public let amount: Double
        public let summary: String
    }

    /// Parses the transactions CSV. Expects the header emitted by
    /// ``CashlyCSVExporter.transactions(_:)``.
    public static func transactions(_ source: String) throws -> [TransactionRow] {
        let rows = try parseRFC4180(source)
        guard let header = rows.first else { throw Failure.missingHeader }
        let expected = ["date", "summary", "amount", "category", "budget", "status", "participants"]
        try validate(header: header, expected: expected)
        return try rows.dropFirst().enumerated().map { (offset, fields) in
            let line = offset + 2
            guard fields.count == expected.count else {
                throw Failure.unexpectedColumns(line: line, found: fields.count, expected: expected.count)
            }
            guard let date = isoDate(from: fields[0]) else {
                throw Failure.invalidDate(line: line, raw: fields[0])
            }
            guard let amount = Double(fields[2]) else {
                throw Failure.invalidAmount(line: line, raw: fields[2])
            }
            let participants = fields[6]
                .split(separator: ";", omittingEmptySubsequences: true)
                .map { String($0).trimmingCharacters(in: .whitespaces) }
            return TransactionRow(
                date: date,
                summary: fields[1],
                amount: amount,
                categoryName: fields[3],
                budgetSummary: fields[4],
                status: fields[5],
                participantNames: participants
            )
        }
    }

    /// Parses the budgets CSV. Expects the header emitted by
    /// ``CashlyCSVExporter.budgets(_:)``.
    public static func budgets(_ source: String) throws -> [BudgetRow] {
        let rows = try parseRFC4180(source)
        guard let header = rows.first else { throw Failure.missingHeader }
        let expected = ["date", "category", "amount", "summary"]
        try validate(header: header, expected: expected)
        return try rows.dropFirst().enumerated().map { (offset, fields) in
            let line = offset + 2
            guard fields.count == expected.count else {
                throw Failure.unexpectedColumns(line: line, found: fields.count, expected: expected.count)
            }
            guard let date = Int(fields[0]) else {
                throw Failure.invalidDate(line: line, raw: fields[0])
            }
            guard let amount = Double(fields[2]) else {
                throw Failure.invalidAmount(line: line, raw: fields[2])
            }
            return BudgetRow(
                date: date,
                categoryName: fields[1],
                amount: amount,
                summary: fields[3]
            )
        }
    }

    // MARK: - Helpers

    private static func validate(header: [String], expected: [String]) throws {
        let normalised = header.map { $0.lowercased() }
        guard normalised == expected else {
            throw Failure.missingHeader
        }
    }

    private static func isoDate(from raw: String) -> TimeInterval? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.date(from: raw)?.timeIntervalSince1970
    }

    /// Minimal RFC 4180 parser. Honours quoted fields, doubled
    /// quotes, and CRLF / LF line endings. Returns each row as a
    /// `[String]` of unescaped fields.
    static func parseRFC4180(_ source: String) throws -> [[String]] {
        var rows: [[String]] = []
        var field = ""
        var row: [String] = []
        var inQuotes = false
        var index = source.startIndex
        while index < source.endIndex {
            let c = source[index]
            if inQuotes {
                if c == "\"" {
                    let next = source.index(after: index)
                    if next < source.endIndex, source[next] == "\"" {
                        field.append("\"")
                        index = next
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else {
                switch c {
                case "\"":
                    inQuotes = true
                case ",":
                    row.append(field)
                    field = ""
                case "\r":
                    break
                case "\n":
                    row.append(field)
                    rows.append(row)
                    row = []
                    field = ""
                default:
                    field.append(c)
                }
            }
            index = source.index(after: index)
        }
        if !field.isEmpty || !row.isEmpty {
            row.append(field)
            rows.append(row)
        }
        // Strip trailing empty rows caused by a final newline.
        while let last = rows.last, last == [""] {
            rows.removeLast()
        }
        return rows
    }
}
