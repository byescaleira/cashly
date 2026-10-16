import CashlyDomain
import FeatureCore
import Foundation
import Observation

@MainActor @Observable
public final class ConverterModel {
    public var amount: Double = 100
    public private(set) var from: String
    public private(set) var to: String
    public private(set) var table: ExchangeTable?
    public private(set) var isLoading = true
    public private(set) var failed = false
    public private(set) var currencies: [String] = CurrencySetting.supported
    @ObservationIgnored private let rates: any ExchangeRateProviding
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var request = 0

    public init(rates: any ExchangeRateProviding, defaults: UserDefaults = .standard) {
        self.rates = rates
        self.defaults = defaults
        let home = Money.currencyCode
        to = defaults.string(forKey: Key.to) ?? home
        let saved = defaults.string(forKey: Key.from)
        from = saved ?? (home == "USD" ? "EUR" : "USD")
    }

    public var suggested: [String] {
        var codes = [Money.currencyCode, "USD", "EUR"]
        if let local = Locale.current.currency?.identifier { codes.append(local) }
        return codes.reduce(into: []) { if !$0.contains($1) { $0.append($1) } }
    }

    public var rate: Decimal? {
        guard let table, table.base == from else { return nil }
        return table.rate(to: to)
    }

    public var result: String? {
        guard let rate, let money = try? Money(validating: amount),
            let converted = try? money.converted(by: rate)
        else { return nil }
        return converted.formatted(currency: to)
    }

    public var isUnavailable: Bool { !isLoading && rate == nil }

    public var resultText: String {
        result.map { "≈ \($0)" } ?? ""
    }

    public var rateText: String? {
        rate.map { CurrencyText.rate($0, from: from, to: to) }
    }

    public var updatedText: String? {
        guard let table, rate != nil else { return nil }
        let day = (table.date ?? table.fetchedAt).formatted(
            .dateTime.day().month(.abbreviated).year().locale(.app))
        let time = table.fetchedAt.formatted(.dateTime.hour().minute().locale(.app))
        return String(appLocalized: "Published on \(day), checked at \(time)")
    }

    public func load() async {
        request += 1
        let current = request
        isLoading = true
        defer { if current == request { isLoading = false } }
        let base = from
        do {
            let table = try await rates.table(base: base, on: nil)
            try Task.checkCancellation()
            guard current == request else { return }
            self.table = table
            failed = false
        } catch is CancellationError {
        } catch {
            guard current == request else { return }
            failed = true
        }
    }

    public func loadCurrencies() async {
        guard let codes = try? await rates.currencies(), !codes.isEmpty else { return }
        currencies = Array(Set(codes).union(suggested)).sorted()
    }

    public func choose(from code: String) {
        guard code != from else { return }
        if code == to { to = from }
        from = code
        save()
    }

    public func choose(to code: String) {
        guard code != to else { return }
        if code == from { from = to }
        to = code
        save()
    }

    public func swap() {
        if let rate, let money = try? Money(validating: amount),
            let converted = try? money.converted(by: rate)
        {
            amount = converted.doubleValue
        }
        let previous = from
        from = to
        to = previous
        save()
    }

    private func save() {
        defaults.set(from, forKey: Key.from)
        defaults.set(to, forKey: Key.to)
    }

    private enum Key {
        static let from = "cashly.converter.from"
        static let to = "cashly.converter.to"
    }
}
