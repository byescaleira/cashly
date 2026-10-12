import CashlyAnalytics
import CashlyDomain
import Foundation

public enum ImportOutcome: Sendable {
    case imported(Int)
    case declined
    case waiting
    case locked
}

public protocol TransactionImporting: Sendable {
    func requestImport(_ preview: SpreadsheetPreview, source: String) async -> ImportOutcome
}

public struct CashlyContext: Sendable {
    let workspace: @Sendable () async throws -> (Repositories, User)
    let importer: any TransactionImporting
    let engine: AnalysisEngine
    let today: @Sendable () -> Date

    public init(
        workspace: @escaping @Sendable () async throws -> (Repositories, User),
        importer: any TransactionImporting, engine: AnalysisEngine = AnalysisEngine(),
        today: @escaping @Sendable () -> Date = { .now }
    ) {
        self.workspace = workspace
        self.importer = importer
        self.engine = engine
        self.today = today
    }

    func month(_ value: JSONValue?) throws -> YearMonth {
        guard let text = value?.string, !text.isEmpty else { return YearMonth(today()) }
        let parts = text.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 2, let month = YearMonth(year: parts[0], month: parts[1]) else {
            throw MCPToolError("Use o mês no formato AAAA-MM, por exemplo 2026-10.")
        }
        return month
    }
}

enum Amount {
    static func value(_ money: Money) -> Double { money.doubleValue }

    static func day(_ date: Date) -> String {
        date.formatted(Date.ISO8601FormatStyle(timeZone: .current).year().month().day())
    }
}
