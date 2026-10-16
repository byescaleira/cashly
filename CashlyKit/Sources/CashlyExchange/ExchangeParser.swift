import CashlyDomain
import Foundation

enum ExchangeParser {
    static let excluded: Set<String> = [
        "XAG", "XAU", "XBA", "XBB", "XBC", "XBD", "XDR", "XPD", "XPT", "XSU", "XTS", "XUA", "XXX",
    ]

    static func table(_ data: Data, base: String, source: ExchangeSource, fetchedAt: Date) throws
        -> ExchangeTable
    {
        let decoder = JSONDecoder()
        switch source {
        case .currencyAPI:
            let response = try decoder.decode(CurrencyAPIResponse.self, from: data)
            return ExchangeTable(
                base: base, day: response.date, rates: uppercased(response.rates), source: source,
                fetchedAt: fetchedAt)
        case .frankfurter:
            let response = try decoder.decode(FrankfurterResponse.self, from: data)
            guard response.base.uppercased() == base else { throw URLError(.cannotParseResponse) }
            return ExchangeTable(
                base: base, day: response.date, rates: uppercased(response.rates), source: source,
                fetchedAt: fetchedAt)
        }
    }

    static func currencies(_ data: Data) throws -> [String] {
        try JSONDecoder().decode([String: String].self, from: data).keys.map { $0.uppercased() }
    }

    static func fiat(_ codes: [String]) -> [String] {
        let iso = Set(Locale.Currency.isoCurrencies.map { $0.identifier.uppercased() })
        return Set(codes).filter { iso.contains($0) && !excluded.contains($0) }.sorted()
    }

    private static func uppercased(_ rates: [String: Decimal]) -> [String: Decimal] {
        var output: [String: Decimal] = [:]
        for (code, rate) in rates where rate > 0 { output[code.uppercased()] = rate }
        return output
    }
}

private struct CurrencyAPIResponse: Decodable {
    let date: String
    let rates: [String: Decimal]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        date = try container.decode(String.self, forKey: DynamicKey(stringValue: "date"))
        guard let key = container.allKeys.first(where: { $0.stringValue != "date" }) else {
            throw URLError(.cannotParseResponse)
        }
        rates = try container.decode([String: Decimal].self, forKey: key)
    }
}

private struct FrankfurterResponse: Decodable {
    let base: String
    let date: String
    let rates: [String: Decimal]
}

private struct DynamicKey: CodingKey {
    let stringValue: String
    let intValue: Int? = nil

    init(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        nil
    }
}
