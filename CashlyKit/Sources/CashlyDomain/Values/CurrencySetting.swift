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

    public static func isSupported(_ code: String) -> Bool {
        supported.contains(code)
    }
}
