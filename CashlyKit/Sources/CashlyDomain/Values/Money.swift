import Foundation

public struct Money: Hashable, Comparable, Sendable {
    public static var currencyCode: String { CurrencySetting.shared.code }
    public static let zero = Money(minorUnits: 0)

    public let minorUnits: Int64

    public init(minorUnits: Int64) {
        self.minorUnits = minorUnits
    }

    public init(validating amount: Double) throws {
        guard amount.isFinite, abs(amount) <= 9_000_000_000_000,
            let decimal = Decimal(string: String(amount), locale: Locale(identifier: "en_US_POSIX"))
        else {
            throw CashlyError.invalidInput("O valor informado está fora do intervalo permitido.")
        }
        var scaled = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        minorUnits = NSDecimalNumber(decimal: rounded).int64Value
    }

    public var decimalValue: Decimal { Decimal(minorUnits) / 100 }

    public var doubleValue: Double { NSDecimalNumber(decimal: decimalValue).doubleValue }

    public func adding(_ other: Money) throws -> Money {
        let (value, overflow) = minorUnits.addingReportingOverflow(other.minorUnits)
        guard !overflow else {
            throw CashlyError.invalidInput("O total excede o intervalo monetário permitido.")
        }
        return Money(minorUnits: value)
    }

    public func subtracting(_ other: Money) throws -> Money {
        let (value, overflow) = minorUnits.subtractingReportingOverflow(other.minorUnits)
        guard !overflow else {
            throw CashlyError.invalidInput("O total excede o intervalo monetário permitido.")
        }
        return Money(minorUnits: value)
    }

    public func divided(into count: Int) throws -> [Money] {
        guard (1...10_000).contains(count), minorUnits >= 0 else { throw CashlyError.onSave }
        let quotient = minorUnits / Int64(count)
        let remainder = minorUnits % Int64(count)
        return (0..<count).map { Money(minorUnits: quotient + (Int64($0) < remainder ? 1 : 0)) }
    }

    public func installment(at index: Int, count: Int) -> Money {
        guard count > 0, count <= 1200, index >= 0, index < count, minorUnits >= 0 else {
            return .zero
        }
        let quotient = minorUnits / Int64(count)
        let remainder = minorUnits % Int64(count)
        return Money(minorUnits: quotient + (Int64(index) < remainder ? 1 : 0))
    }

    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.minorUnits < rhs.minorUnits }
}
