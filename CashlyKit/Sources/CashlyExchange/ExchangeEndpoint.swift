import CashlyDomain
import Foundation

struct ExchangeEndpoint {
    let url: URL
    let source: ExchangeSource

    init?(_ address: String, source: ExchangeSource) {
        guard let url = URL(string: address) else { return nil }
        self.url = url
        self.source = source
    }

    static func tables(base: String, day: String?) -> [ExchangeEndpoint] {
        let version = day ?? "latest"
        let code = base.lowercased()
        return [
            ExchangeEndpoint(
                "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@\(version)/v1/currencies/\(code).min.json",
                source: .currencyAPI),
            ExchangeEndpoint(
                "https://\(version).currency-api.pages.dev/v1/currencies/\(code).min.json",
                source: .currencyAPI),
            ExchangeEndpoint(
                "https://api.frankfurter.dev/v1/\(version)?base=\(base.uppercased())",
                source: .frankfurter),
        ].compactMap(\.self)
    }

    static let currencyLists = [
        ExchangeEndpoint(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.min.json",
            source: .currencyAPI),
        ExchangeEndpoint(
            "https://latest.currency-api.pages.dev/v1/currencies.min.json", source: .currencyAPI),
        ExchangeEndpoint("https://api.frankfurter.dev/v1/currencies", source: .frankfurter),
    ].compactMap(\.self)
}
