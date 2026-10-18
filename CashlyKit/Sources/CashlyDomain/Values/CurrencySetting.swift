import Foundation
import Observation
import Synchronization

@Observable
public final class CurrencySetting: Sendable {
    public static let shared = CurrencySetting()
    public static let supported = [
        "BRL", "USD", "EUR", "GBP", "CAD", "AUD", "CHF", "MXN", "ARS", "CNY",
    ]

    @ObservationIgnored private let storage: Mutex<String>
    @ObservationIgnored private let correctionStorage = Mutex<CurrencyCorrection?>(nil)

    public init(code: String = "BRL") {
        storage = Mutex(code)
    }

    public var code: String {
        get {
            access(keyPath: \.code)
            return storage.withLock { $0 }
        }
        set {
            guard Self.isSupported(newValue) else { return }
            withMutation(keyPath: \.code) { storage.withLock { $0 = newValue } }
        }
    }

    public var correction: CurrencyCorrection? {
        get {
            access(keyPath: \.correction)
            return correctionStorage.withLock { $0 }
        }
        set {
            withMutation(keyPath: \.correction) { correctionStorage.withLock { $0 = newValue } }
        }
    }

    public func correctionRate(from currency: String) -> (
        rate: Decimal, date: Date, target: String
    )? {
        guard let correction, correction.target == code, currency != correction.target,
            let rate = correction.rate(from: currency)
        else { return nil }
        return (rate, correction.date, correction.target)
    }

    public static func isSupported(_ code: String) -> Bool {
        supported.contains(code)
    }
}
