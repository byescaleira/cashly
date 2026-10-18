import Foundation

public struct CurrencyCorrection: Codable, Hashable, Sendable {
    public let target: String
    public let date: Date
    public let rates: [String: Decimal]

    public init(target: String, date: Date, rates: [String: Decimal]) {
        self.target = target
        self.date = date
        self.rates = rates
    }

    public init(table: ExchangeTable, codes: [String]) {
        target = table.base
        date = table.fetchedAt
        var rates: [String: Decimal] = [:]
        for code in codes where code != table.base {
            guard let rate = table.rates[code], rate > 0 else { continue }
            rates[code] = 1 / rate
        }
        self.rates = rates
    }

    public func rate(from code: String) -> Decimal? {
        code == target ? 1 : rates[code]
    }
}
