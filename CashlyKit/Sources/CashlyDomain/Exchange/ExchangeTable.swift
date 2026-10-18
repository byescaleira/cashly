import Foundation

public struct ExchangeTable: Codable, Hashable, Sendable {
    public let base: String
    public let day: String
    public let rates: [String: Decimal]
    public let source: ExchangeSource
    public let fetchedAt: Date

    public init(
        base: String, day: String, rates: [String: Decimal], source: ExchangeSource,
        fetchedAt: Date = .now
    ) {
        self.base = base
        self.day = day
        self.rates = rates
        self.source = source
        self.fetchedAt = fetchedAt
    }

    public func rate(to code: String) -> Decimal? {
        code == base ? 1 : rates[code]
    }

    public var date: Date? { Self.date(for: day) }

    public static func day(for date: Date, calendar: Calendar = CashlyCalendar.current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    public static func date(for day: String, calendar: Calendar = CashlyCalendar.current) -> Date? {
        let parts = day.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(
            from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12))
    }
}

public enum ExchangeSource: String, Codable, Hashable, Sendable {
    case currencyAPI, frankfurter
}
