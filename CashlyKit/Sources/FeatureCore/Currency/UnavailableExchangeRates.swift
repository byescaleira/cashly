import CashlyDomain
import Foundation
import SwiftUI

public struct UnavailableExchangeRates: ExchangeRateProviding {
    public init() {}

    public func table(base: String, on date: Date?) async throws -> ExchangeTable {
        throw URLError(.notConnectedToInternet)
    }

    public func currencies() async throws -> [String] {
        CurrencySetting.supported
    }
}

extension EnvironmentValues {
    @Entry public var exchangeRates: any ExchangeRateProviding = UnavailableExchangeRates()
}
