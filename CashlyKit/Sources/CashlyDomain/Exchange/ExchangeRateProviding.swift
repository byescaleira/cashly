import Foundation

public protocol ExchangeRateProviding: Sendable {
    func table(base: String, on date: Date?) async throws -> ExchangeTable
    func currencies() async throws -> [String]
}
