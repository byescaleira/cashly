import CashlyDomain
import Foundation
import Testing

@testable import CashlyExchange

@Suite(.serialized)
struct ExchangeRateServiceTests {
    let directory = FileManager.default.temporaryDirectory.appending(
        path: UUID().uuidString, directoryHint: .isDirectory)
    let today = ExchangeTable.date(for: "2026-10-15") ?? .now

    func service(at date: Date? = nil) -> ExchangeRateService {
        let now = date ?? today
        return ExchangeRateService(
            session: StubProtocol.session(), directory: directory, now: { now })
    }

    @Test func readsHistoricalTableFromCurrencyAPI() async throws {
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-10-01/v1/currencies/usd.min.json",
            body: #"{"date":"2026-10-01","usd":{"brl":5.1885,"eur":0.92,"btc":0.00001}}"#)
        let table = try await service().table(
            base: "USD", on: ExchangeTable.date(for: "2026-10-01"))
        #expect(table.day == "2026-10-01")
        #expect(table.rate(to: "BRL") == Decimal(string: "5.1885"))
        #expect(table.rate(to: "USD") == 1)
        #expect(table.source == .currencyAPI)
    }

    @Test func fallsBackToFrankfurter() async throws {
        StubProtocol.respond(
            "https://api.frankfurter.dev/v1/2026-09-30?base=EUR",
            body: #"{"amount":1.0,"base":"EUR","date":"2026-09-30","rates":{"BRL":6.01}}"#)
        let table = try await service().table(
            base: "EUR", on: ExchangeTable.date(for: "2026-09-30"))
        #expect(table.source == .frankfurter)
        #expect(table.rate(to: "BRL") == Decimal(string: "6.01"))
    }

    @Test func oldDatesSkipCurrencyAPI() async throws {
        StubProtocol.respond(
            "https://api.frankfurter.dev/v1/2020-05-04?base=GBP",
            body: #"{"amount":1.0,"base":"GBP","date":"2020-05-04","rates":{"BRL":6.9}}"#)
        let table = try await service().table(
            base: "GBP", on: ExchangeTable.date(for: "2020-05-04"))
        #expect(table.source == .frankfurter)
        let requests = StubProtocol.requests.withLock { $0 }
        #expect(!requests.contains { $0.contains("currency-api@2020-05-04") })
    }

    @Test func futureDatesUseLatestAndCacheForAnHour() async throws {
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/chf.min.json",
            body: #"{"date":"2026-10-14","chf":{"brl":6.5}}"#)
        let first = try await service().table(
            base: "CHF", on: ExchangeTable.date(for: "2026-12-01"))
        #expect(first.day == "2026-10-14")
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies/chf.min.json",
            body: #"{"date":"2026-10-15","chf":{"brl":6.6}}"#)
        let cached = try await service(at: today.addingTimeInterval(600)).table(
            base: "CHF", on: nil)
        #expect(cached.rate(to: "BRL") == Decimal(string: "6.5"))
        let refreshed = try await service(at: today.addingTimeInterval(4000)).table(
            base: "CHF", on: nil)
        #expect(refreshed.rate(to: "BRL") == Decimal(string: "6.6"))
    }

    @Test func historicalTablesStayCachedOffline() async throws {
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-08-10/v1/currencies/cad.min.json",
            body: #"{"date":"2026-08-10","cad":{"brl":3.9}}"#)
        let date = ExchangeTable.date(for: "2026-08-10")
        _ = try await service().table(base: "CAD", on: date)
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@2026-08-10/v1/currencies/cad.min.json",
            status: 500, body: "")
        let cached = try await service(at: today.addingTimeInterval(86_400 * 30)).table(
            base: "CAD", on: date)
        #expect(cached.rate(to: "BRL") == Decimal(string: "3.9"))
    }

    @Test func failsWhenEverySourceFails() async {
        await #expect(throws: (any Error).self) {
            try await service().table(base: "MXN", on: ExchangeTable.date(for: "2026-07-01"))
        }
    }

    @Test func listsOnlyFiatCurrencies() async throws {
        StubProtocol.respond(
            "https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@latest/v1/currencies.min.json",
            body:
                #"{"usd":"US Dollar","brl":"Brazilian Real","btc":"Bitcoin","xau":"Gold","jpy":"Yen"}"#
        )
        let codes = try await service().currencies()
        #expect(codes == ["BRL", "JPY", "USD"])
    }
}
