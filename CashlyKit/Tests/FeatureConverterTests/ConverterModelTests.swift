import CashlyDomain
import FeatureConverter
import FeatureCore
import Foundation
import Testing

@MainActor
struct ConverterModelTests {
    let defaults = UserDefaults(suiteName: UUID().uuidString) ?? .standard

    @Test func convertsWithTheLatestRateAndSwaps() async {
        let model = ConverterModel(rates: PairRates(), defaults: defaults)
        model.choose(from: "USD")
        model.choose(to: "BRL")
        model.amount = 10
        await model.load()
        #expect(model.rate == 5)
        #expect(model.result == Money(minorUnits: 5000).formatted(currency: "BRL"))
        #expect(model.rateText != nil)
        #expect(model.updatedText != nil)
        model.swap()
        #expect(model.from == "BRL")
        #expect(model.to == "USD")
        #expect(model.amount == 50)
        #expect(model.rate == nil)
        await model.load()
        #expect(model.rate == Decimal(string: "0.2"))
        #expect(model.result == Money(minorUnits: 1000).formatted(currency: "USD"))
    }

    @Test func choosingTheSameCurrencySwapsTheOtherSide() {
        let model = ConverterModel(rates: PairRates(), defaults: defaults)
        model.choose(from: "USD")
        model.choose(to: "BRL")
        model.choose(from: "BRL")
        #expect(model.from == "BRL")
        #expect(model.to == "USD")
        let reopened = ConverterModel(rates: PairRates(), defaults: defaults)
        #expect(reopened.from == "BRL")
        #expect(reopened.to == "USD")
    }

    @Test func failureIsReported() async {
        let model = ConverterModel(rates: UnavailableExchangeRates(), defaults: defaults)
        await model.load()
        #expect(model.failed)
        #expect(model.result == nil)
    }
}

private struct PairRates: ExchangeRateProviding {
    func table(base: String, on date: Date?) async throws -> ExchangeTable {
        let rates: [String: Decimal] =
            base == "USD" ? ["BRL": 5] : ["USD": Decimal(string: "0.2") ?? 0]
        return ExchangeTable(base: base, day: "2026-10-14", rates: rates, source: .currencyAPI)
    }

    func currencies() async throws -> [String] {
        ["BRL", "USD"]
    }
}
