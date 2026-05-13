//
//  CashlyCSVExporter.swift
//  CashlyKit
//
//  Pure-Swift CSV serializer for the user's transactions + budgets.
//  Output is RFC 4180 — fields with commas / quotes / newlines get
//  wrapped in double quotes, embedded quotes are doubled. Numbers
//  use locale-independent dot decimals so spreadsheets parse the
//  amount columns deterministically across regions.
//

import Foundation

public enum CashlyCSVExporter {
    /// Renders the transactions list as a CSV string with the
    /// header: date,summary,amount,category,budget,status,participants.
    /// Date column uses ISO-8601 (yyyy-MM-dd) so external tools
    /// sort lexicographically.
    public static func transactions(_ transactions: [Transaction]) -> String {
        let header = "date,summary,amount,category,budget,status,participants"
        let rows = transactions.map { tx -> String in
            let date = isoDate(from: tx.date)
            let participants = tx.participants
                .map(\.user.name)
                .joined(separator: ";")
            return [
                escape(date),
                escape(tx.summary),
                amount(tx.amount),
                escape(tx.effectiveCategory.name),
                escape(tx.budget.summary),
                escape(String(describing: tx.status)),
                escape(participants)
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    /// Renders the budgets list with header:
    /// date,category,amount,summary.
    public static func budgets(_ budgets: [Budget]) -> String {
        let header = "date,category,amount,summary"
        let rows = budgets.map { budget -> String in
            [
                "\(budget.date)",
                escape(budget.category.name),
                amount(budget.amount),
                escape(budget.summary)
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func isoDate(from interval: TimeInterval) -> String {
        // ISO8601DateFormatter is not Sendable, so we build a fresh
        // instance per call instead of caching a static one. One
        // allocation per row is acceptable for batch export.
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter.string(from: Date(timeIntervalSince1970: interval))
    }

    /// Locale-independent amount formatting — two decimals, dot
    /// separator. Importers (Excel, Numbers, Google Sheets) treat
    /// this as a number column regardless of regional defaults.
    private static func amount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    /// RFC 4180 escape: wrap in quotes when needed, double internal
    /// quotes. Fields without commas / quotes / newlines / CR pass
    /// through untouched for a smaller payload.
    private static func escape(_ field: String) -> String {
        let needsQuoting = field.contains(",") || field.contains("\"")
            || field.contains("\n") || field.contains("\r")
        guard needsQuoting else { return field }
        let escaped = field.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}
