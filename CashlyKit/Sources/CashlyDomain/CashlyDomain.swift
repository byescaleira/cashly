import Foundation

public protocol CashlyEntity: Identifiable, Codable, Hashable, Sendable {}

public enum CashlyCalendar {
    public static var current: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        calendar.locale = .current
        return calendar
    }
}

extension BinaryInteger {
    public var double: Double { Double(self) }
    public var isEven: Bool { self % 2 == 0 }
    public var string: String { String(self) }
}
extension Double {
    public var int: Int {
        isFinite ? Int(min(max(self, Double(Int.min + 1)), Double(Int.max - 1024))) : 0
    }
    public var double: Double { self }
    public var date: Date { Date(timeIntervalSince1970: self) }
    public var yearMonth: Int {
        let components = CashlyCalendar.current.dateComponents([.year, .month], from: date)
        return (components.year ?? 0) * 100 + (components.month ?? 1)
    }
    public var percentage: String { formatted(.percent.precision(.fractionLength(0))) }
    public func currency() -> String? {
        guard isFinite else { return nil }
        return formatted(.currency(code: Money.currencyCode))
    }
}
extension String {
    public var int: Int? { Int(self) }
    public var space: String { self + " " }
    public var breakLine: String { self + "\n" }
    public func date(with formatter: CashlyDateFormatter) -> Date? {
        formatter.rawValue.date(from: self)
    }
}
extension Date {
    public func string(with formatter: CashlyDateFormatter) -> String? {
        formatter.rawValue.string(from: self)
    }
    public func cashly(with formatter: CashlyDateFormatter) -> String {
        formatter.rawValue.string(from: self)
    }
    public static func from(yearMonth: Int) -> Date? {
        guard yearMonth / 100 > 0, (1...12).contains(yearMonth % 100) else { return nil }
        return CashlyCalendar.current.date(
            from: DateComponents(year: yearMonth / 100, month: yearMonth % 100, day: 1))
    }
}
extension Data {
    public func entity<T: Decodable>(for type: T.Type) throws -> T {
        try JSONDecoder().decode(type, from: self)
    }
}
extension Encodable {
    public func data() throws -> Data { try JSONEncoder().encode(self) }
}
extension Sequence {
    public func sorted<Value: Comparable>(
        by keyPath: KeyPath<Element, Value>, using compare: (Value, Value) -> Bool = (<)
    ) -> [Element] {
        sorted { compare($0[keyPath: keyPath], $1[keyPath: keyPath]) }
    }
}
