import CashlyDomain
import Foundation

public actor ExchangeRateService: ExchangeRateProviding {
    public static let shared = ExchangeRateService()
    static let latestLifetime: TimeInterval = 3600
    static let currenciesLifetime: TimeInterval = 7 * 86_400
    static let historyStart = "2024-03-02"

    private let session: URLSession
    private let cache: ExchangeCache
    private let now: @Sendable () -> Date
    private var tables: [String: ExchangeTable] = [:]
    private var loading: [String: Task<ExchangeTable, any Error>] = [:]

    public init(
        session: URLSession = .shared, directory: URL? = ExchangeCache.defaultDirectory,
        now: @escaping @Sendable () -> Date = { .now }
    ) {
        self.session = session
        cache = ExchangeCache(directory: directory)
        self.now = now
    }

    public func table(base: String, on date: Date?) async throws -> ExchangeTable {
        let base = base.uppercased()
        let today = ExchangeTable.day(for: now())
        let day = date.map { ExchangeTable.day(for: $0) }.flatMap { $0 < today ? $0 : nil }
        let key = "\(base)-\(day ?? "latest")"
        let cached = tables[key] ?? cache.table(key)
        if let cached, day != nil || now().timeIntervalSince(cached.fetchedAt) < Self.latestLifetime
        {
            tables[key] = cached
            return cached
        }
        let isOwner = loading[key] == nil
        let task: Task<ExchangeTable, any Error>
        if let running = loading[key] {
            task = running
        } else {
            task = Task { try await fetch(base: base, day: day) }
            loading[key] = task
        }
        defer { if isOwner { loading[key] = nil } }
        do {
            let table = try await task.value
            if isOwner {
                tables[key] = table
                cache.save(table, key: key)
            }
            return table
        } catch {
            if let cached { return cached }
            throw error
        }
    }

    public func currencies() async throws -> [String] {
        if let saved = cache.currencies(),
            now().timeIntervalSince(saved.fetchedAt) < Self.currenciesLifetime
        {
            return saved.codes
        }
        for source in ExchangeEndpoint.currencyLists {
            guard let data = try? await data(from: source.url),
                let codes = try? ExchangeParser.currencies(data),
                !codes.isEmpty
            else { continue }
            let list = ExchangeParser.fiat(codes)
            cache.save(ExchangeCache.CurrencyList(codes: list, fetchedAt: now()))
            return list
        }
        if let saved = cache.currencies() { return saved.codes }
        return CurrencySetting.supported.sorted()
    }

    private func fetch(base: String, day: String?) async throws -> ExchangeTable {
        var failure: any Error = URLError(.cannotLoadFromNetwork)
        for endpoint in ExchangeEndpoint.tables(base: base, day: day) {
            if let day, endpoint.source == .currencyAPI, day < Self.historyStart { continue }
            do {
                let data = try await data(from: endpoint.url)
                return try ExchangeParser.table(
                    data, base: base, source: endpoint.source, fetchedAt: now())
            } catch {
                failure = error
            }
        }
        throw failure
    }

    private func data(from url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
