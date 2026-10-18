import Foundation

public enum ProportionalSplit {
    public static func distribute(_ total: Money, like parts: [Money]) -> [Money] {
        let weight = parts.reduce(Int64(0)) { $0 + max($1.minorUnits, 0) }
        guard !parts.isEmpty, total.minorUnits >= 0 else { return parts }
        guard weight > 0 else {
            return [total] + Array(repeating: .zero, count: parts.count - 1)
        }
        let exact = parts.map {
            Decimal(total.minorUnits) * Decimal(max($0.minorUnits, 0)) / Decimal(weight)
        }
        var values = exact.map { amount -> Int64 in
            var amount = amount
            var whole = Decimal()
            NSDecimalRound(&whole, &amount, 0, .down)
            return NSDecimalNumber(decimal: whole).int64Value
        }
        let remainder = total.minorUnits - values.reduce(0, +)
        let priority = exact.indices.sorted { lhs, rhs in
            let left = exact[lhs] - Decimal(values[lhs])
            let right = exact[rhs] - Decimal(values[rhs])
            return left == right ? lhs < rhs : left > right
        }
        for index in priority.prefix(Int(max(remainder, 0))) { values[index] += 1 }
        return values.map(Money.init(minorUnits:))
    }
}
