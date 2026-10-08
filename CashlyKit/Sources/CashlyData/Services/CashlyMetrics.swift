import Foundation
import OSLog

public enum CashlyMetrics {
    public static let logger = Logger(
        subsystem: "br.com.rafaelescaleira.Cashly", category: "Storage")
    private static let signposter = OSSignposter(
        subsystem: "br.com.rafaelescaleira.Cashly", category: .pointsOfInterest)
    public static func measure<T>(_ name: StaticString, operation: () throws -> T) rethrows -> T {
        let state = signposter.beginInterval(name)
        defer { signposter.endInterval(name, state) }
        return try operation()
    }
    public static func failure(_ operation: String, error: any Error) {
        let value = error as NSError
        logger.error(
            "Operation \(operation, privacy: .public) failed; domain=\(value.domain, privacy: .public) code=\(value.code)"
        )
    }
}
