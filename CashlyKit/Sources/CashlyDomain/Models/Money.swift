import Foundation

public struct Money: Codable, Hashable, Comparable, Sendable {
    public let minorUnits: Int64
    public static let currencyCode = "BRL"
    public static let zero = Money(minorUnits: 0)
    public init(minorUnits: Int64) { self.minorUnits = minorUnits }
    public init(validating amount: Double) throws {
        guard amount.isFinite, abs(amount) <= 9_000_000_000_000,
            let decimal = Decimal(string: String(amount), locale: Locale(identifier: "en_US_POSIX"))
        else {
            throw CashlyError.invalidInput("O valor informado está fora do intervalo permitido.")
        }
        var scaled = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        self.minorUnits = NSDecimalNumber(decimal: rounded).int64Value
    }
    public var decimalValue: Decimal { Decimal(minorUnits) / 100 }
    public var doubleValue: Double { NSDecimalNumber(decimal: decimalValue).doubleValue }
    public var formatted: String { decimalValue.formatted(.currency(code: Self.currencyCode)) }
    public static func < (lhs: Self, rhs: Self) -> Bool { lhs.minorUnits < rhs.minorUnits }
    public func adding(_ other: Self) throws -> Self {
        let (value, overflow) = minorUnits.addingReportingOverflow(other.minorUnits)
        guard !overflow else {
            throw CashlyError.invalidInput("O total excede o intervalo monetário permitido.")
        }
        return Self(minorUnits: value)
    }
    public func subtracting(_ other: Self) throws -> Self {
        let (value, overflow) = minorUnits.subtractingReportingOverflow(other.minorUnits)
        guard !overflow else {
            throw CashlyError.invalidInput("O total excede o intervalo monetário permitido.")
        }
        return Self(minorUnits: value)
    }
    public func divided(into count: Int) throws -> [Self] {
        guard (1...10_000).contains(count), minorUnits >= 0 else { throw CashlyError.onSave }
        let quotient = minorUnits / Int64(count)
        let remainder = minorUnits % Int64(count)
        return (0..<count).map { Self(minorUnits: quotient + (Int64($0) < remainder ? 1 : 0)) }
    }
    public func installment(at index: Int, count: Int) -> Self {
        guard count > 0, count <= 1200, index >= 0, index < count, minorUnits >= 0 else {
            return .zero
        }
        let quotient = minorUnits / Int64(count)
        let remainder = minorUnits % Int64(count)
        return Self(minorUnits: quotient + (Int64(index) < remainder ? 1 : 0))
    }
}
